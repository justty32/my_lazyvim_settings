# 開著的檔案被外部修改，Neovim 怎麼辦？

[回教程](README.md)

Buffer 是載入後保存在記憶體的內容；磁碟檔案是另一份。外部工具寫檔不等於直接改 buffer。
Neovim 偵測到差異後，依有沒有未存修改及 `autoread` 等設定處理：

| 偵測時的狀態 | 一般行為 |
| --- | --- |
| Buffer 未修改，autoread 開啟 | 重新讀入磁碟內容 |
| Buffer 有未存修改，磁碟也改了 | 警告／詢問，避免靜默丟掉你的修改；不會自動合併 |
| autoread 關閉 | 外部內容變更會提示，不自動重載 |
| 檔案被刪除 | 不會因 autoread 就把目前 buffer 清空 |

Plugin 若自訂 `FileChangedShell`，可以接管警告與選擇，所以上表描述一般機制。
`autoread` 是自動讀取，不是自動存檔；和 `autowrite` 是不同選項。
參考本機 `:h 'autoread'`、`:h timestamp`、`:h FileChangedShell`。

## 什麼時候發現變更？

明確要求檢查用 `:checktime`；不是重新執行 Lua 或 plugin。
目前安裝的 LazyVim 另在 `FocusGained`、`TermClose`、`TermLeave` 事件執行檢查，
且略過目前 `buftype=nofile` 的情形。可在自己機器確認：

```vim
:verbose set autoread?
:verbose autocmd lazyvim_checktime
```

本機實際來源是 `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/autocmds.lua`。
終端是否傳 focus event 也會影響「切回來是否更新」，需要時手動 `:checktime` 最直接。
網站 [editing 文件](https://neovim.io/doc/user/editing/#timestamp) 現在還描述 autoread 的即時監看；
不要據此假設所有已安裝版本和終端都有同樣的偵測時機，以本機 help 與實測為準。

## 實驗 A：沒有未存修改

終端建立實驗檔並開啟：

```sh
demo_dir=$(mktemp -d)
printf '原本內容\n' > "$demo_dir/watch.txt"
nvim --clean "$demo_dir/watch.txt"
```

Neovim 裡執行 `:set autoread`、`:echo expand('%:p')`。
在第二個終端，對剛印出的實際路徑執行 `printf '外部的新內容\n' > /實際路徑/watch.txt`。
回 Neovim 執行 `:checktime`：應顯示外部的新內容，且 `:set modified?` 為 `nomodified`。

## 實驗 B：兩邊都有修改

1. 在 buffer 新增「尚未存檔」，不要 `:write`。
2. 第二個終端再將磁碟檔改成其他內容。
3. Neovim 執行 `:checktime`，觀察衝突警告／選擇；先選保留目前 buffer。
4. 確認未存文字還在，`:set modified?` 為 `modified`。

本機乾淨 TUI 實測顯示 `W12` 與 `[O]K, (L)oad File, Load File (a)nd Options`；
按 `o` 保留目前文字，按 `l` 則讀入外部版本。提示外觀可能被 UI plugin 改變；
核心是不能假設 Neovim 會替你合併。
要比較兩份，先把記憶體內容另存到新的備份檔，例如 `:write /tmp/你選的新備份檔名`，
`:diffsplit /原始檔的完整路徑` **可能仍會重用同一個已載入 buffer**，不適合直接當磁碟副本。
可靠的做法是先在終端把磁碟版本複製成另一個暫存檔，再 `:diffsplit /那份磁碟副本`。
分清楚兩份內容後再決定要保留哪一段。

| 明確決定 | 操作 |
| --- | --- |
| 丟掉目前未存修改，重讀磁碟 | `:edit!`，執行前確認不需要未存內容 |
| 保留目前內容，覆蓋外部版本 | 確認後才用 `:write!`；磁碟的外部修改會被覆蓋 |
| 兩份都需要 | 先備份、比較，再手動合併 |

## 開的是設定 Lua 檔呢？

即使 buffer 已重新載入最新的 `options.lua`，已運行的 Lua 設定仍然是舊狀態。
文字重載與程式執行不同：小範圍可明確執行設定，module 則考慮 require 快取與清理；
完整配置用新 Neovim 驗證。詳見 [module 與重載](modules.md)。
