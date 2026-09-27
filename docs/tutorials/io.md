# Buffer 可以接 stdin、stdout、stderr 或 pipe 嗎？

[回教程](README.md) · 下一課：[外部修改](external-files.md)

可以，但要有一層程序／channel 把資料送進送出。Buffer 是 Neovim 裡的文字容器，
本身不是作業系統的檔案描述符；把 buffer 命名為某個 FIFO 路徑，也不會自動建立雙向連線。

```text
buffer 的文字 ── get_lines + chansend ──→ 程序 stdin
結果 buffer  ←── on_stdout callback ──── 程序 stdout
結果 buffer  ←── on_stderr callback ──── 程序 stderr
```

## 先選合適的介面

| 需求 | 方法 | 注意 |
| --- | --- | --- |
| 一次讀取命令輸出 | `:read !命令` | 插入目前 buffer，命令結束才返回 |
| 將選取範圍交給命令 | `:'<,'>write !命令` | 送給 stdin，不用結果取代文字 |
| 用命令結果取代範圍 | `:'<,'>!命令` | 真的會修改文字，和 write 不同 |
| 跑完一個程序再取結果 | `vim.system(argv, opts, callback)` | 可分別取得 stdout、stderr、exit code |
| 持續互動／串流 | `jobstart` + `chansend` + callback | 自己管理結果 buffer、程序生命週期 |
| 需要 shell、顏色或終端互動 | `:terminal` | PTY／終端模擬，輸出不是一般可編輯 log |

終端 buffer 的 Normal 模式由 `<C-\><C-n>` 進入；普通字元 `q` 在 Terminal 模式會傳給程序，
不是通用的「關閉終端」。不要把結果 log 的 q 行為直接套到所有 terminal。
參考 [job control](https://neovim.io/doc/user/job_control/) 與 [terminal](https://neovim.io/doc/user/terminal/)。

## 1. 最小的雙向 I/O

從設定 repo 根目錄開 `nvim --clean`，輸入：

```vim
:lua demo = dofile("docs/tutorials/examples/stream.lua").start({"cat"})
:lua demo.send("你好，世界\n")
```

你會在底部看到 `[stdout] 你好，世界`。`cat` 從 stdin 讀資料，再原樣寫到 stdout。
讀 [stream.lua](examples/stream.lua)：`jobstart` 回傳 job ID，`chansend` 把文字送給它。
這裡用 argv list 避免 shell 字串拼接；`{"cat", "/tmp/有 空白的檔名"}` 仍是一個路徑參數。

送目前來源 buffer 的內容時，要**在切到結果視窗之前**保存來源 ID：

```lua
local source = vim.api.nvim_get_current_buf()
local demo = dofile("docs/tutorials/examples/stream.lua").start({ "cat" })
local lines = vim.api.nvim_buf_get_lines(source, 0, -1, false)
demo.send(table.concat(lines, "\n") .. "\n")
demo.eof() -- 關閉 stdin：沒有更多輸入；仍然可以接收 stdout／stderr
```

這個範例刻意補最後換行，不是保留二進位或所有檔案格式的 byte-for-byte 傳送。
按 q 刪除練習結果 buffer 時會停止它的 job；只是切去別的 tab 並不代表工作完成。

## 2. stdout 與 stderr 分開看

```vim
:lua demo = dofile("docs/tutorials/examples/stream.lua").start({"python3", "-u", "-c", "import sys; print('正常輸出'); print('錯誤訊息', file=sys.stderr)"})
```

結果有 `[stdout]`、`[stderr]` 和 `[exit]` 標籤。stderr 有內容不代表程序一定失敗；
此例仍 exit 0。兩條 stream 各自有順序，但合在一個 log 裡的先後不保證等於原程式呼叫順序。
若使用 PTY，stdout／stderr 通常匯到同一終端，無法如此分開。

一個 callback 不等於一行：`hello\n` 可能分成多次到達，中文的 UTF-8 bytes 也可能分段。
範例分別保存 stdout／stderr 的未完成尾段，到換行或 EOF 才顯示。
因此「輸出沒立即出現」也可能是來源程式尚未 flush，或最後一行還沒換行；
Python 範例用 `-u` 關閉其輸出緩衝。協定細節見 [channel-lines](https://neovim.io/doc/user/channel/#channel-lines)。

## 3. 接具名管道 FIFO

在另一個終端建立暫存目錄：

```sh
pipe_dir=$(mktemp -d)
mkfifo "$pipe_dir/events.fifo"
printf '%s\n' "$pipe_dir/events.fifo"
```

複製最後印出的**實際完整路徑**到 Neovim：

```vim
:lua demo = dofile("docs/tutorials/examples/stream.lua").start({"cat", "/tmp/實際目錄/events.fifo"})
```

回到剛才的終端：

```sh
printf 'FIFO 你好\n第二行\n' > "$pipe_dir/events.fifo"
```

底部 buffer 會收到兩行。開啟 FIFO 等待另一端連接的是背景 `cat`，不會把 Neovim
主迴圈卡在同步讀取。這次 writer 關閉後 reader 讀到 EOF，cat 退出；要再試請重新啟動 reader。
只有 writer、沒有 reader 時，shell 的開啟操作可能等待，這是 FIFO 語意。

要讓 writer 連續寫多次，可以在**已有 reader** 時保持 FD 開啟：

```sh
exec 3> "$pipe_dir/events.fifo"
printf '第一筆\n' >&3
printf '第二筆\n' >&3
exec 3>&-
```

練習結束，關閉兩端後用 `rm -- "$pipe_dir/events.fifo"` 與 `rmdir -- "$pipe_dir"` 清理。
FIFO 是單向 byte stream，沒有訊息邊界，也不是可回看的 log 檔。
雙向通訊通常用兩條 FIFO，或直接使用有 stdin／stdout 的 job。
Linux FIFO 語意見 [fifo(7)](https://man7.org/linux/man-pages/man7/fifo.7.html)。

如果需求是「將 buffer 寫進某個 FIFO」，也要把可能等待的 `open`／寫入放在背景程序，
再以 `chansend` 送內容。例如用固定 Python 程式、路徑當獨立參數：

```lua
local source = vim.api.nvim_get_current_buf()
local payload = table.concat(vim.api.nvim_buf_get_lines(source, 0, -1, false), "\n") .. "\n"
local writer = dofile("docs/tutorials/examples/stream.lua").start({
  "python3", "-u", "-c",
  "import sys; f=open(sys.argv[1], 'wb', buffering=0); f.write(sys.stdin.buffer.read()); f.close()",
  "/tmp/實際目錄/events.fifo",
})
writer.send(payload)
writer.eof()
```

需另有 FIFO reader；沒有 reader 時 writer 等待，但 Neovim 仍可操作，q 可停止工作。
這是小文字範例，Python 會把輸入讀到記憶體，不適合無限串流。

## FIFO 與 Unix socket 不是同一種檔案

`vim.fn.sockconnect("pipe", path, ...)` 的 `pipe` 在 Unix 指 Unix-domain socket，
不能拿 `mkfifo` 建立的 FIFO 當 socket 連線。Neovim 的 `--listen` socket 又常跑 Msgpack-RPC，
不能把任意文字當作 RPC 傳送。先弄清楚對端的檔案類型與通訊協定，再選 API。
參考 [sockconnect](https://neovim.io/doc/user/vimfn/#sockconnect())。
