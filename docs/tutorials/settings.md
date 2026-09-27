# 選項、快捷鍵與事件：從小改動開始

[回教程](README.md) · 下一課：[Lua module](modules.md)

## 1. 先找出是哪個設定生效

在程式碼視窗輸入：

```vim
:setlocal wrap?
:verbose setlocal wrap?
:verbose nmap ,ee
:lua =vim.api.nvim_get_current_buf()
:lua =vim.api.nvim_get_current_win()
```

第一行查值，第二行多查最後設定來源，第三行查映射來源。後兩行得到物件 ID。
打開 Conjure log 後再查一次：buffer、window 不同，區域設定和鍵位也可能不同。
遇到「我明明設定了卻沒效果」，先確認查的是實際出問題的視窗。

## 2. 選項的作用範圍

```lua
vim.opt.wrap = true -- 適合寫在 config/options.lua，設定目前值及相應預設
vim.wo.wrap = false -- 只改目前 window
vim.bo.expandtab = true -- 只改目前 buffer
vim.g.my_demo_enabled = true -- 自訂變數，不會自行啟用任何功能
```

`vim.opt` 類似 `:set`，不是「永遠只改全域」。選項本身有 global、buffer-local、
window-local 等範圍；精確操作時用 `vim.bo[buf]` 或 `vim.wo[win]`。
`vim.opt_local`／`vim.opt_global` 對應 `:setlocal`／`:setglobal`。
列表型選項可用 `vim.opt.path:append("**")`，避免手動拼逗號。
參考 [Lua 選項介面](https://neovim.io/doc/user/lua/#vim.opt)。

練習：`:vsplit` 後，只在一邊執行 `:setlocal nowrap`。
兩邊看同一份文字，但顯示不同；折行沒有改動檔案內容。

## 3. 做一個只影響目前 buffer 的快捷鍵

將以下存成暫存 Lua 檔，在練習 buffer 用 `:luafile` 執行：

```lua
vim.keymap.set("n", "<localleader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify("wrap = " .. tostring(vim.wo.wrap))
end, { buffer = true, desc = "切換目前視窗折行" })
```

`buffer = true` 把映射放在目前 buffer；映射被呼叫時，函式改的是當時的 window。
本設定 localleader 是逗號，因此按 `,uw`。在 `--clean` 裡預設是反斜線；
可在建立映射**之前**先執行 `:let maplocalleader=','`。
`desc` 提供說明，`vim.keymap.set` 預設不遞迴展開右側映射。
移除練習映射：

```lua
vim.keymap.del("n", "<localleader>uw", { buffer = true })
```

## 4. 讓 Janet buffer 開啟時自動有這個鍵

學會前一步後，才考慮放進 `lua/config/autocmds.lua`：

```lua
local group = vim.api.nvim_create_augroup("MyJanetPractice", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "janet",
  callback = function(event)
    vim.keymap.set("n", "<localleader>uw", function()
      vim.wo.wrap = not vim.wo.wrap
    end, { buffer = event.buf, desc = "切換折行" })
  end,
})
```

`clear = true` 清掉同群組舊的事件，重跑設定才不會累積 callback。
它不會移除以前已建立的 buffer 鍵位；刪除此功能時也要刪鍵位，或重開 Neovim。
註冊事件不會回頭替早已開啟的 buffer 執行；另開 Janet 檔測試最清楚。
事件細節見 [autocmd API](https://neovim.io/doc/user/api/#nvim_create_autocmd())。

## 5. 怎樣驗證與還原

依序試：Janet buffer 有鍵位、其他語言沒有、兩個視窗分別切換、重載不增加事件。
用 `:autocmd MyJanetPractice` 查註冊結果。
只練習時，不必存進正式設定；正式修改前後用 `git diff` 確認範圍。
不要用整個 repo 的強制還原來清一個小練習，它也會丟掉其他未提交修改。
