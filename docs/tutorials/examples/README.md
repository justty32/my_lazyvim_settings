# 可執行範例

[回教程](../README.md)

| 檔案 | 負責什麼 |
| --- | --- |
| [panel.lua](panel.lua) | 建立浮動結果 buffer、折行、區域 q 與關閉清理 |
| [stream.lua](stream.lua) | 用 job 將程序 stdout／stderr 寫入文字 buffer，提供 stdin 寫入與停止方法 |

在設定 repo 根目錄啟動 `nvim --clean`，再執行：

```vim
:lua dofile("docs/tutorials/examples/panel.lua").open()
```

按 `q` 關閉。另一個範例：

```vim
:lua demo = dofile("docs/tutorials/examples/stream.lua").start({"cat"})
:lua demo.send("你好\n")
:lua demo.eof()
```

`demo` 暫用全域變數，讓分次輸入的 `:lua` 能存取同一個狀態。
cat 將 stdin 回送至 stdout；你會看到 `[stdout] 你好`，EOF 後看到 `[exit] 0`。
`q` 刪除練習 buffer 並停止它啟動的程序；這不是 Conjure 的 q 行為。
結束後可用 `:lua demo = nil` 清掉練習變數。

stream 範例以完整行為單位顯示，未換行的尾段留到後續換行或 EOF。
適合普通文字，不解析 ANSI、回車進度條或二進位資料；最多留 2000 行，
超過 64 KiB 的未完成尾段會丟棄並顯示提示。高流量、超長完整行仍需另做限流／截斷。
這個小範例沒有自動捲到最底端，方便觀察輸出與顯示是兩件事。
