# Lua module：檔案怎樣變成設定

[回教程](README.md) · 下一課：[常用 API](api.md)

## 目前這份設定的入口

```text
init.lua                     require("config.lazy")
lua/config/lazy.lua          啟動 lazy.nvim，匯入 LazyVim 與 plugins
lua/config/options.lua      編輯器選項
lua/config/keymaps.lua      個人快捷鍵
lua/config/autocmds.lua      個人事件
lua/plugins/*.lua           回傳 lazy.nvim plugin spec
```

入口可直接讀 [init.lua](../../init.lua) 和 [config/lazy.lua](../../lua/config/lazy.lua)。
`config/options.lua` 等名稱是 **LazyVim 的約定**，不是 Neovim 自動掃描所有 Lua 檔。
`lua/plugins/` 被載入，是因為 lazy 設定有 `{ import = "plugins" }`。
Neovim 原生的 `plugin/` 啟動腳本目錄，則和 `lua/plugins/` 不是同一件事。
LazyVim 的載入時機見 [設定文件](https://www.lazyvim.org/configuration)。

## require 的路徑與回傳值

| 呼叫 | 放在 runtimepath 下的檔案 |
| --- | --- |
| `require("mytools.panel")` | `lua/mytools/panel.lua` |
| `require("mytools")` | `lua/mytools.lua` 或 `lua/mytools/init.lua`；避免同時建兩者造成混淆 |

`require` 不是 shell 路徑：不寫 `~/.config/nvim/` 或 `.lua`。
module 通常回傳一個 Lua table，使用者再呼叫其中的函式：

```lua
-- lua/mytools/greeting.lua
local M = {}

function M.hello(name)
  vim.notify("你好，" .. name)
end

function M.setup()
  vim.api.nvim_create_user_command("MyHello", function()
    M.hello("Janet 使用者")
  end, { force = true })
end

return M
```

儲存後執行 `:lua require("mytools.greeting").setup()`，再執行 `:MyHello`。
`setup` 只是作者取的函式名，不是 Lua 自動呼叫的魔法。
要永久啟用，可由自己的設定入口呼叫一次。練習後移除：
`:delcommand MyHello`，並刪掉練習檔及你加入的呼叫。
module 規則見 [Lua guide](https://neovim.io/doc/user/lua-guide/#lua-guide-modules)。

## 改了檔案，為何 require 沒重新讀？

首次 `require` 的結果放在 `package.loaded["mytools.greeting"]`。
再次呼叫取快取，因此磁碟更新、buffer 重載、Lua module 重新執行是三件不同的事。
局部重載自己的小模組可用：

```lua
package.loaded["mytools.greeting"] = nil
require("mytools.greeting").setup()
```

已被其他程式保存的舊 table／callback 不會跟著換掉；子 module 也不會自動清快取。
重載還可能留下 timer、job、autocmd。範例 command 用 `force = true` 覆蓋同名命令；
事件需具名 augroup 並清舊事件；持續運作的資源要先 teardown。
改整套外掛載入結構時，開新 Neovim 驗證通常比大量清 `package.loaded` 可靠。

## plugin spec 的 init、opts、config

```lua
-- 示意：lua/plugins/example.lua，不要直接加入不存在的外掛
return {
  {
    "author/example.nvim",
    ft = "janet",
    init = function()
      vim.g.example_feature = true
    end,
    opts = { width = 60 },
    -- 通常讓 lazy 自動執行 require(MAIN).setup(opts)
  },
}
```

| 欄位 | 用途 |
| --- | --- |
| `init` | 啟動時執行，常用來在 plugin 載入前設定 `vim.g` |
| `ft`／`event`／`cmd`／`keys` | 指定觸發外掛載入的條件 |
| `opts` | 給外掛 setup 的選項；table 可與既有 spec 合併 |
| `config` | 外掛載入時執行；需要自訂初始化流程才自己寫 |

更改繼承的選項可用 `opts = function(_, opts) opts.width = 80 end`。
`return { width = 80 }` 則換掉該次收到的 options table，意義不同。
多個 spec 的 `init`／`config` 不能當作多個事件 callback，期待自動串接。
我們之前 Conjure 設定遺失就是這類覆蓋問題；共同初始化現在集中在
[conjure.lua](../../lua/plugins/conjure.lua)。定義見 [lazy.nvim spec](https://lazy.folke.io/spec)。

練習：讀 Janet 與 Conjure 的 spec，各找出「載入條件」「編輯器變數」「真正執行動作的函式」。
不必先改它們；能分清這三者，就比較不會把執行期行為塞進載入期設定。
