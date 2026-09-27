# 常用 API：自己做一個結果視窗

[回教程](README.md) · 下一課：[程序 I/O](io.md)

## 先學這些就能做很多事

| 想做的事 | 優先學的介面 | help |
| --- | --- | --- |
| 調整選項 | `vim.opt`、`vim.bo`、`vim.wo` | `:h lua-guide-options` |
| 定義快捷鍵 | `vim.keymap.set`／`del` | `:h vim.keymap.set()` |
| 事件與命令 | `nvim_create_autocmd`、`nvim_create_augroup`、`nvim_create_user_command` | `:h api-autocmd` |
| 找到物件 | `nvim_get_current_buf`／`win`、`nvim_list_bufs`／`wins` | `:h api` |
| 讀寫文字 | `nvim_buf_get_lines`／`set_lines`、`get_text`／`set_text` | `:h nvim_buf_set_lines()` |
| 開結果視窗 | `nvim_create_buf`、`nvim_open_win`、`nvim_win_set_buf` | `:h api-floatwin` |
| 執行既有 Ex 操作 | `vim.cmd`，例如 `vim.cmd("botright split")` | `:h vim.cmd()` |
| 呼叫 Vim 函式 | `vim.fn`，例如 `stdpath`、`expand`、`jobstart` | `:h vim.fn` |
| 檢查值／通知 | `vim.print`、`vim.inspect`、`vim.notify` | `:h vim.print()` |
| 延後 UI 操作 | `vim.schedule`、`vim.schedule_wrap` | `:h vim.schedule()` |
| 外部程序 | `vim.system`、`vim.fn.jobstart`、`chansend` | `:h vim.system()` |
| 路徑／底層 I/O | `vim.fs`，有需要才深入 `vim.uv` | `:h vim.fs`、`:h vim.uv` |

上表 `nvim_*` 都透過 `vim.api` 呼叫。它是給 Lua 與遠端 client 共用的 API；
`vim.keymap` 等則提供方便的 Lua 介面。先依目的找 API，不必背完名字。
查正式簽章用 [API 文件](https://neovim.io/doc/user/api/)，Lua 專用工具用
[Lua 文件](https://neovim.io/doc/user/lua/)。

## 三個最常踩的地方

**ID 與目前物件。** `0` 在許多 API 代表目前 buffer／window。
若非同步 callback 執行時使用者已切換檔案，`0` 就指向另一個物件。
啟動工作時保存 `local buf = vim.api.nvim_get_current_buf()`，回來時用
`nvim_buf_is_valid(buf)` 檢查；需要已載入文字時再查 `nvim_buf_is_loaded(buf)`。

**索引不統一。** Lua list 從 1 起；`nvim_buf_get_lines(buf, 0, 2, false)`
拿第 1、2 行，結束位置不包含在內，`-1` 表示結尾。
游標 `nvim_win_get_cursor(win)` 回傳 `{行, 欄}`：行從 1 起、欄從 0 起，欄是 byte offset。
中文 UTF-8 的一個字不等於一個 byte，也不等於固定一格螢幕寬度。
`get_text`／`set_text` 的行與 byte 欄又都從 0 起；使用前查對該函式。

**非同步不等於平行跑 Lua。** `vim.uv` callback 常處於 fast event，不能隨意改 UI；
可用 `vim.schedule_wrap` 排回主迴圈。排程後仍要檢查物件存活。
jobstart 的一般輸出 callback 可使用 buffer API；不必見到 callback 就機械式包 schedule。
主線程做同步 `:!` 或 `vim.system(...):wait()` 仍會等待，不適合長期串流。

## 操作完整範例

從 repo 根目錄的練習 Neovim 執行：

```vim
:lua panel = dofile("docs/tutorials/examples/panel.lua").open({string.rep("中文結果 ", 50), "按 q 返回"})
```

閱讀 [panel.lua](examples/panel.lua)，依序對照：

1. `nvim_create_buf(false, true)` 建不列入一般清單的 scratch buffer。
2. `nvim_buf_set_lines` 寫內容，再設 `modifiable = false` 防止手改。
3. `nvim_open_win` 用這個 buffer 建浮動視窗並聚焦。
4. `vim.wo[win].wrap = true` 設這個視窗折行。
5. q 只綁在結果 buffer；關閉浮窗後 `bufhidden = "wipe"` 清掉不再顯示的 buffer。

這就是 Conjure HUD 類型介面的基本積木，但範例沒有接入 Conjure。
Buffer 可以由多個 window 顯示；改變 window 的位置和大小不需要重新求值。

練習 A：把 `height` 從 12 改成 16，重跑 `dofile(...).open()`；比較顯示行數。
練習 B：用 `:lua vim.api.nvim_win_set_config(panel.win, {width = 40})` 縮窄視窗，
觀察長行折行，buffer 實際行數沒有增加。
練習 C：讀 stream 範例怎樣用 `split` 加 `nvim_win_set_buf`，把相同內容放到底部。
浮窗、分割視窗、tab 是顯示方式；資料放在 buffer 裡。
