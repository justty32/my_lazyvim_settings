# 從這次 Janet 設定學 Neovim

這份筆記寫給想自己調整設定的使用者。案例來自 2026-09-27 的 Janet 開發環境整理；
日常快捷鍵以 [設定 README](../README.md#janet-開發) 為準，這裡記方法、原因與踩坑。

## 先認識你正在改哪一層

| 層次 | 本次的例子 | 設定位置 |
| --- | --- | --- |
| Neovim 選項 | 長行折行、延續行縮排 | [options.lua](../lua/config/options.lua) |
| LazyVim／lazy.nvim plugin 規格 | 載入時機、filetype、外掛初始化 | [conjure.lua](../lua/plugins/conjure.lua) |
| 語言服務 | Janet LSP、Treesitter parser | [janet.lua](../lua/plugins/janet.lua) |
| 視窗與鍵位行為 | log 放大、開啟與返回 | [conjure.lua](../lua/plugins/conjure.lua) |
| 外掛事件協作 | LSP 事件後恢復 which-key 前綴 | [which-key.lua](../lua/plugins/which-key.lua) |

本機 `~/.config/nvim` 是指向這份設定 repo 的 symlink。修改檔案後，新的 Neovim 會載入；
已開的行程不會自動重新執行 Lua。這次曾透過 RPC 明確套用局部修復，才不用每次重開。

## 三個概念：buffer、window、tab

- **Buffer** 保存內容：程式碼、結果 log、暫存文字都可以是 buffer。
- **Window** 是觀看 buffer 的區域；兩個 window 可以同時看同一個 buffer。
- **Tab** 保存一組 window 配置。它不等於檔案，也不等於 buffer。

這正是 `q` 曾出錯的原因：`,ls` 新增結果視窗，關掉視窗就能回到原布局；
`,le` 卻是用原視窗顯示另一個 buffer，返回時應換回原 buffer。
原先只處理「關掉視窗」與「最後一個視窗開空白頁」，所以 `,le` 後的 `q` 會留下空白畫面。
修復保存來源 window／buffer，再依開啟方式返回；測試也加入只有一個及多個視窗的情況。

## 選項：先試用，再寫進設定

在 Neovim 命令列可以先試：

```vim
:setlocal wrap linebreak breakindent
:verbose setlocal wrap?
```

第一行只改目前視窗的顯示，沒有在檔案插入換行。第二行查看實際值及最後設定來源。
要保留成預設，再寫進 `lua/config/options.lua`：

```lua
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
```

`vim.opt` 提供設定選項的介面；`vim.wo` 指定 window 選項，`vim.bo` 指定 buffer 選項。
`vim.g` 則是全域變數，常被 plugin 當成自己的設定入口。

本次的陷阱是：Conjure 建立 log 視窗時還會自行設定 `wrap`，所以必須另外設定
`vim.g["conjure#log#wrap"] = true`。主編輯區折行，並不保證所有外掛視窗也折行。

## 外掛設定：init 不會自動串在一起

原本 Common Lisp、Fennel、Hy、Scheme 各自提供同一個 `Olical/conjure` 的 `init`。
lazy.nvim 合併規格時只保留最後一個 `init`，前面設定便沒有執行。

我們實際查到留下的是 Scheme 的初始化；Fennel 因而使用了預設的 nfnl client。
修復把 Conjure 的 client、REPL 指令與共用設定集中到一份規格。
各語言的 Treesitter／LSP 設定仍留在各自檔案，方便找。

這種問題要查「最後載入的值」，光看到設定檔寫著 `false` 並不能證明它生效。
例如可在 Neovim 查看：

```vim
:lua print(vim.inspect(vim.g["conjure#filetype#janet"]))
:lua print(vim.inspect(require("conjure.config")["get-in"]({"client_on_load"})))
```

Janet 採開檔啟動 stdio REPL；Common Lisp 採手動連接外部 Swank。
因此啟動設定還要考慮 buffer 的 filetype，不能只用一個全域開關代表所有語言。

## 「沒反應」要拆成幾段檢查

一次 `,ee` 大致經過：實際按鍵 → 前綴／鍵位映射 → 擷取 expression → REPL → log → 視窗。
找到最後成功的一段，才知道下一步該查哪裡。

```vim
:lua print(vim.inspect(vim.api.nvim_get_mode()))
:verbose nmap ,
:verbose nmap ,ee
:messages
:ls
:tabs
```

- 先看是否處於 Normal 模式，接著確認逗號前綴與完整 `,ee` 映射。
- 看 log 有沒有新的求值紀錄；有結果卻看不到時，再查視窗。
- 不要急著重啟 REPL，否則會丟掉求值狀態，也失去診斷現場。

本次抓到的兩種「沒反應」原因不同：

| 現象 | 實際原因 | 處理 |
| --- | --- | --- |
| 手動慢速輸入 `,ee` 間歇失效 | LSP 連上後清除 which-key 前綴；其 buffer 追蹤停在隱藏 log，漏掉重建來源 buffer | 排程在 LSP 事件處理後重建前綴 |
| 按「Jump to latest part of log」後沒有結果視窗 | Conjure 原功能先關 HUD，只捲動已存在的 log 視窗；沒有視窗就無處顯示 | 先開啟／聚焦 log，再跳到最新結果 |

第一個問題曾先被猜成 HUD 收起太快；那個猜測不足以解釋按鍵失效。
後來在失效當下讀到「`,ee` 還在、逗號前綴消失」，並重現事件順序，才找到能驗證的修復。
這個案例提醒：遠端一次送完 `,ee` 成功，不能代表使用者逐鍵輸入也正常。

## 為什麼要用 vim.schedule

LSP 連線會觸發 `LspAttach`，多個 plugin 都可能處理這個事件。
若我們立刻補前綴，後面的 which-key handler 還是可能把它清掉。
`vim.schedule(function() ... end)` 讓修復排到目前事件處理完之後執行。

程式還會檢查 buffer 是否存在、which-key 是否初始化完成，避免在初始化途中或關閉後操作。
這是針對本機外掛行為的補償；未來更新 which-key 後，應用回歸案例重新核對是否仍有需要。

## UTF-8：內容與印出來的表示法不同

本次 Neovim 與 Janet 檔案都是 UTF-8。REPL 把字串值印成 `\xE7...`，是 Janet 的值表示法。
`print` 會輸出文字內容，所以中文可正常顯示；`pp`／pretty 格式在本機仍會跳脫中文。
用法見 [中文結果與 UTF-8](../README.md#中文結果與-utf-8)。本輪沒有加自動解碼處理。

## 怎麼驗證自己沒有改壞別的地方

本次先在暫存專案驗證，再在實際開發目錄確認 LSP 根目錄與 REPL。
後續發現 LSP 本身會執行初始化式；早先「沒有執行模型請求」的判斷不能涵蓋這個自動副作用。
可重跑的入口與前置條件見 [本機驗證](../README.md#本機驗證)：

- [conjure.lua 測試](../tests/conjure.lua)：求值、import、LSP、折行、log 開啟／返回等。
- [which-key.lua 測試](../tests/which-key.lua)：模擬隱藏 log 與 LSP 事件，重現前綴遺失再驗證恢復。

單純檢查「映射存在」抓不到視窗返回錯誤；要測完整操作順序，例如 `,le` → `q`，
並確認回到同一個來源 buffer、原內容仍在、REPL 繼續可用。

## 自己動手的練習順序

1. 用 `:setlocal wrap!` 切換折行，觀察內容沒變，再切回來。
2. 用 `:ls`、`:tabs` 配合 `,ls`／`,lt`／`,le`，觀察 buffer、window、tab 的差別。
3. 讀 `conjure.lua` 裡的 `keys`：左邊是按鍵，函式是動作，`ft` 是適用語言，`desc` 是說明。
4. 改一個容易還原的選項，在另一個 Neovim 行程驗證；通過後看 `git diff`，只提交這次的改動。

不用一次讀懂所有 plugin。從「想改的行為 → 實際設定來源 → 一個小修改 → 驗證」開始就夠了。

## 後續發現：Janet LSP 會執行初始化式

2026-09-27 使用者再回報錯誤後，LSP 日誌出現了程式本身的 `tool: add` 輸出。
用暫存專案做隔離探測：檔案只有一個 `def`，初始化式在暫存目錄寫入標記；
不呼叫 Conjure 求值，僅讓 LSP 開檔分析，標記仍然產生。

上游 [eval.janet](https://github.com/CFiggers/janet-lsp/blob/f38b4c8a17ac01ff29536b93d66198a0fec8a680/src/eval.janet)
有 flycheck evaluator；所以「能連線、hover 正常」不能證明分析完全沒有副作用。
此處不把上游當前程式碼等同於本機 jimage 的精確版本；本機行為以隔離探測為證。

已停用本設定的 Janet LSP 自動啟動，也停止現有 Neovim 的該 client；沒有停止 Conjure REPL。
待修復並驗證分析不會執行初始化式後，才能恢復 LSP。本輪未修改 VS Code 的獨立 LSP 設定。
使用者提到的「不少錯誤」尚缺原始訊息；當時通知歷史沒有該批錯誤，REPL log 只找到
`unknown symbol res`，不可把這筆錯誤與 LSP 副作用直接視為同一問題。
