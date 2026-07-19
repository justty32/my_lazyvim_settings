-- Janet：Conjure REPL（stdio client）。
--
-- 跟 hy/fennel/scheme 同一套「REPL 一直開、邊寫邊試」哲學：`,ee` 求值游標所在 form、
-- `,er` 求值最外層 form、`,eb` 求值整個 buffer。開檔即自動起一個 `janet -n -s` 子行程當 REPL。
--
-- 前置：janet 要在 PATH 上（已裝到 ~/.local/bin，該路徑已在 PATH）。
--
-- ★ 為什麼指定 client：Conjure 對 janet 的**預設** client 是 netrepl（要另外先跑一個 netrepl
--   伺服器才連得上），不是 stdio。開發單機小專案要的是 stdio——開檔就自帶一個 `janet -n -s`
--   子行程，零設定。所以這裡把 janet 綁到 stdio client。
--
-- ★★ 為什麼寫在檔案 body（不是 conjure spec 的 init）：hy/fennel/scheme/janet 四個檔都對同一個
--   "Olical/conjure" plugin 各給一份 spec。lazy.nvim 合併同名 plugin 時，`init` 這種函式欄位是
--   **後載入者覆蓋前者**（scheme.lua 依字母序在 janet.lua 之後載入，會蓋掉 janet 的 init）。
--   hy/fennel 之所以還能動，是因為它們的 conjure 預設本來就是 stdio、蓋掉也無所謂；janet 預設是
--   netrepl，被蓋掉就會連錯。把 g: 變數設在 body 於**啟動時無條件執行**，不進 spec 合併、不會被蓋，
--   Conjure 載入時會沿用已存在的 g: 值（scheme 的 s7 覆寫能生效就是同一個道理）。
--
-- 括號結構（parinfer）與彩虹括號（rainbow-delimiters）的 ft 清單裡本來就有 "janet"，不必重設。
-- 語法高亮：Neovim **沒有**內建 janet syntax，treesitter 的 janet parser 也不會自己裝，所以
--   高亮以前是全空的。janet 的 treesitter parser 名叫 "janet_simple"（rainbow/nvim-treesitter 的
--   query 目錄用的也是這個名字），把它加進 ensure_installed 就會編譯安裝、開檔自動高亮。
vim.g["conjure#filetype#janet"] = "conjure.client.janet.stdio"

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "janet_simple" })
    end,
  },
  {
    "Olical/conjure",
    ft = { "janet" },
  },
}
