# 自己修改 Neovim：實作教程

目標：從「知道想改什麼」走到「找得到設定、寫得出小功能、驗證後能還原」。
案例接續 [Janet 設定筆記](../README.md)，每課都有操作、預期結果與練習。

| 教程 | 你會做什麼 |
| --- | --- |
| [選項、快捷鍵與事件](settings.md) | 查設定來源，做 buffer 專用鍵位，避免重載後 autocmd 重複 |
| [Lua module 與 LazyVim 架構](modules.md) | 看懂 require、setup、plugin spec，以及修改後為何沒生效 |
| [常用 API 與結果視窗](api.md) | 自己建立可折行、按 q 關閉的浮動結果 buffer |
| [Buffer、stdin／stdout／stderr 與 FIFO](io.md) | 啟動程序、送文字、收結果，再接具名管道 |
| [外部修改與重新載入](external-files.md) | 分辨磁碟與記憶體內容，處理重載及衝突 |
| [可執行範例](examples/README.md) | 直接跑結果視窗與 I/O 模組，查看完整原始碼 |

建議依表順序讀；想先解答 pipe 或外部修改，直接跳到該課即可。

## 練習環境

在終端進入設定 repo，另開一個乾淨的 Neovim：

```sh
cd ~/.config/nvim
nvim --clean
```

`--clean` 不載入你的 LazyVim 設定，適合學 Neovim 原生 API；測外掛時則需要正常啟動。
教程中的 `:lua`、`:setlocal` 在 Neovim 命令列輸入；標為 `sh` 的區塊在終端執行。
Lua 大區塊存成暫存 `.lua` 檔，再用 `:luafile /完整路徑/檔名.lua` 執行。
不要把整段多行 Lua 直接當成 Ex 指令貼進命令列。

可執行範例放在 `docs/`，不會隨日常啟動自動載入，也不會改掉現有快捷鍵。
每次只做一個練習；完成後退出練習用的 Neovim，就能清掉暫時設定。

## 本機驗證

在 repo 根目錄執行：

```sh
nvim --clean --headless -l tests/tutorials.lua
python3 tests/tutorials-ui.py
```

需要 Linux、Python 3、`cat`、`mkfifo`。測試使用暫存檔與自建程序，包含雙向 I/O、
stderr、跨 callback 的中文、FIFO、關閉清理、require 快取及外部修改衝突。
Lua 測試會攔截衝突事件以免 headless 等待回答；Python 測試另開隔離的 PTY，
實際操作 W12 提示、保留未存內容，以及 terminal 的 q 輸入與返回 Normal 模式。
外掛 spec 的虛構名稱只用來說明欄位，不是可安裝範例。

2026-09-27 在本機 Neovim 0.12.5 實際跑過兩支測試，全部通過；Lua 範例亦通過 StyLua 檢查。
自動測試涵蓋原生 API 與範例模組；LazyVim 架構和事件名稱另外核對本機已安裝原始碼。
這不是所有外掛組合的相容性保證，也沒有替你的日常 Neovim 安裝練習功能。

本機 help 是對應已安裝版本的依據；網站文件可能較新。例如網站目前描述即時檔案監看，
本機 `:help timestamp` 仍描述時戳檢查，因此本教程用明確的 `:checktime` 驗證重載行為。
