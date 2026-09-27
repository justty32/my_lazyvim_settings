#!/usr/bin/env python3
"""驗證實際 LSP 協定、初始化式不執行，以及巨集的檔案／網路隔離。"""
import http.server
import json
import os
from pathlib import Path
import queue
import subprocess
import tempfile
import threading

CONFIG = Path(__file__).resolve().parents[1]
DATA = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share"))
IMAGE = DATA / os.environ.get("NVIM_APPNAME", "nvim") / "janet-lsp-fixed/janet-lsp.jimage"


class Client:
    def __init__(self, cwd):
        self.proc = subprocess.Popen(
            [str(CONFIG / "scripts/janet-lsp"), str(IMAGE)], cwd=cwd,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        self.messages = queue.Queue()
        self.errors = []
        self.counter = 0
        threading.Thread(target=self.read, daemon=True).start()
        threading.Thread(target=lambda: self.errors.append(self.proc.stderr.read()), daemon=True).start()

    def read(self):
        try:
            while True:
                headers = {}
                while line := self.proc.stdout.readline():
                    if line in (b"\r\n", b"\n"):
                        break
                    key, value = line.decode().split(":", 1)
                    headers[key.lower()] = value.strip()
                if not line:
                    raise RuntimeError("LSP exited before response")
                self.messages.put(json.loads(self.proc.stdout.read(int(headers["content-length"]))))
        except Exception as error:
            self.messages.put(error)

    def send(self, method, params, request=False):
        message = {"jsonrpc": "2.0", "method": method, "params": params}
        if request:
            self.counter += 1
            message["id"] = self.counter
        payload = json.dumps(message).encode()
        self.proc.stdin.write(f"Content-Length: {len(payload)}\r\n\r\n".encode() + payload)
        self.proc.stdin.flush()
        if request:
            while True:
                response = self.messages.get(timeout=8)
                if isinstance(response, Exception):
                    raise response
                if response.get("id") == self.counter:
                    assert "error" not in response, response
                    return response.get("result")

    def close(self):
        self.proc.terminate()
        self.proc.wait(timeout=5)


hits = []
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        hits.append(self.path)
        self.send_response(200)
        self.end_headers()
    def log_message(self, *_):
        pass


with tempfile.TemporaryDirectory(prefix="janet-lsp-regression-") as directory:
    root = Path(directory)
    (root / "project.janet").write_text('(declare-project :name "regression" :version "0.0.0")\n')
    marker = root / "unexpected-write.txt"
    uri = (root / "main.janet").as_uri()
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    client = Client(root)
    try:
        initialized = client.send("initialize", {
            "processId": os.getpid(), "rootUri": root.as_uri(),
            "capabilities": {"textDocument": {"diagnostic": {}}},
        }, True)
        assert initialized["capabilities"]["hoverProvider"]
        client.send("initialized", {})
        effect = f'(do (spit {json.dumps(str(marker))} "bad") 42)'
        source = f'(def runtime-value {effect})\n(defn plus-one "Add one." [x] (+ x 1))\n(plus-one runtime-value)\n'
        client.send("textDocument/didOpen", {"textDocument": {
            "uri": uri, "languageId": "janet", "version": 1, "text": source,
        }})

        def diagnostics():
            return client.send("textDocument/diagnostic", {"textDocument": {"uri": uri}}, True)["items"]

        assert diagnostics() == []
        assert not marker.exists(), "didOpen executed initializer"
        completions = client.send("textDocument/completion", {
            "textDocument": {"uri": uri}, "position": {"line": 2, "character": 2},
        }, True)
        items = completions.get("items", []) if isinstance(completions, dict) else completions
        assert {"runtime-value", "plus-one"} <= {item["label"] for item in items}
        hover = client.send("textDocument/hover", {
            "textDocument": {"uri": uri}, "position": {"line": 2, "character": 3},
        }, True)
        assert "Add one" in json.dumps(hover), hover

        version = 1
        def change(text):
            global version
            version += 1
            client.send("textDocument/didChange", {
                "textDocument": {"uri": uri, "version": version},
                "contentChanges": [{"text": text}],
            })
            return diagnostics()

        assert change(source.replace("runtime-value", "edited-value")) == []
        assert not marker.exists(), "didChange executed initializer"
        assert change("(+ 1"), "syntax error must produce a diagnostic"
        assert change("unknown-symbol"), "unknown symbol must produce a diagnostic"
        # 巨集本來就在編譯期執行：確認 LSP 專用 wrapper 能阻止實際副作用。
        macro = f'(defmacro write-probe [] (spit {json.dumps(str(marker))} "bad") nil)\n(write-probe)'
        assert change(macro), "read-only isolation should report the denied write"
        assert not marker.exists(), "macro escaped read-only isolation"
        url = f"http://127.0.0.1:{server.server_port}/must-not-be-called"
        macro = f'(defmacro network-probe [] (os/execute @["curl" "--max-time" "1" {json.dumps(url)}]) nil)\n(network-probe)'
        change(macro)
        assert not hits, "analysis reached a host network service"
        client.send("shutdown", {}, True)
        client.send("exit", {})
        client.proc.wait(timeout=5)
        assert client.proc.returncode == 0
        print("PASS: open/change, completion, hover, diagnostics, no initializer effects, read-only and network isolation")
    finally:
        if client.proc.poll() is None:
            client.close()
        server.shutdown()
