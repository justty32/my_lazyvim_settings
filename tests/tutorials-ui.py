#!/usr/bin/env python3
"""Exercise real TUI prompts and terminal input in an isolated PTY (stdlib only)."""

import json
import os
import pty
import re
import select
import subprocess
import tempfile
import time
from pathlib import Path


def main():
    with tempfile.TemporaryDirectory(prefix="nvim-tutorial-ui-") as directory:
        root = Path(directory)
        source = root / "watch.txt"
        report = root / "state.json"
        source.write_text("original\n")
        master, slave = pty.openpty()
        process = subprocess.Popen(
            ["nvim", "--clean", "-n", str(source)],
            stdin=slave, stdout=slave, stderr=slave,
            env={**os.environ, "TERM": "xterm-256color", "LC_ALL": "C"},
        )
        os.close(slave)

        def read_until(predicate):
            output = b""
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.02)[0]:
                    output += os.read(master, 65536)
                if predicate(output):
                    return output
            raise AssertionError(f"TUI timeout: {output[-1200:]!r}")

        def send(command):
            os.write(master, command)

        def snapshot():
            report.unlink(missing_ok=True)
            expression = (
                "{lines=vim.api.nvim_buf_get_lines(0,0,-1,false),"
                "modified=vim.bo.modified,buftype=vim.bo.buftype,"
                "mode=vim.api.nvim_get_mode().mode}"
            )
            send((":lua vim.fn.writefile({vim.json.encode(" + expression
                  + ")}, [[" + str(report) + "]])\r").encode())
            read_until(lambda _: report.exists() and report.stat().st_size > 0)
            return json.loads(report.read_text())

        try:
            read_until(lambda data: b"original" in data)
            send(b':lua vim.api.nvim_buf_set_lines(0,0,-1,false,{"unsaved"})\r')
            assert snapshot()["lines"] == ["unsaved"]
            source.write_text("external replacement longer\n")
            send(b":checktime\r")
            output = read_until(lambda data: b"[O]K" in data)
            assert b"W12" in output
            send(b"o")
            state = snapshot()
            assert state["lines"] == ["unsaved"] and state["modified"]
            send(b":edit!\r")
            state = snapshot()
            assert state["lines"] == ["external replacement longer"]
            assert not state["modified"]
            print("PASS real W12 prompt: O preserves unsaved text; edit! reloads disk")

            send(b":enew\r:terminal cat\r")
            read_until(lambda data: b"term://" in data)
            send(b"iq\r")  # i; q goes to cat. Wait for actual terminal output.
            read_until(lambda data: b"q" in re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]", b"", data))
            send(b"\x1c\x0e")  # Ctrl-\ Ctrl-n returns to Terminal-Normal mode.
            state = snapshot()
            assert state["buftype"] == "terminal"
            assert any(line == "q" for line in state["lines"]), state
            assert state["mode"] == "nt", state
            print("PASS terminal q is input; Ctrl-\\ Ctrl-n returns to Normal")
            send(b":qa!\r")
            process.wait(timeout=5)
            assert process.returncode == 0
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            os.close(master)


if __name__ == "__main__":
    main()
