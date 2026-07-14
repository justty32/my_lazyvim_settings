-- Scheme（s7）：Conjure REPL。
--
-- 為什麼要這個：ai_core 的 galtxt try_1 那條線是 s7 Scheme，開發哲學就是「REPL 一直開、邊寫邊試」。
-- Conjure 內建 scheme 的 stdio client（預設指向 mit-scheme），把它指到 s7 就能 `,ee` 求值游標所在
-- form、`,er` 求值最外層 form、`,eb` 求值整個 buffer——鍵位與其它 Lisp 方言一致。
--
-- s7 的 REPL 二進位**不在任何 repo 裡**（s7 原始碼不託管），由 s7-playground 的 build.sh 編出：
--   cd ~/repo/pas/derived/s7-playground && bash setup.sh && bash build.sh   # → ./s7
-- 路徑解析順序：$S7_REPL → ~/repo/pas/derived/s7-playground/s7 → PATH 上的 s7。
-- （沿用 galtxt try_1/build.sh 找 s7 原始碼時 $S7_DIR 的同一套慣例：env 可覆寫、否則試候選。）
--
-- ⚠ 別去編 libc_s7.so：有它的話 s7 的 REPL 會啟用終端控制碼的花俏模式，跳脫序列會汙染 Conjure
--   的 stdio 管線。沒有它 s7 只是印一行 load failed 的警告、退回純文字 REPL——那正是這裡要的。
--
-- 用法：cd 到 galtxt/try_1 再開 nvim（Conjure 的 stdio client 在 nvim 的 cwd 起 s7，
--   `(load "llm.scm")` 這種相對路徑才對得上）。`,ee` 求值；`,ls` / `,lv` 開 REPL log。
--
-- 括號結構（parinfer）與彩虹括號本來就已經涵蓋 scheme filetype，不必在這裡重複設定。

local function s7_command()
  -- ⚠ 別寫成 `{ vim.env.S7_REPL, "…/s7" }`：S7_REPL 沒設時第一個元素是 nil，
  --   ipairs 會直接停在第 0 個、整張候選表形同虛設（踩過）。
  local candidates = {}
  if vim.env.S7_REPL and vim.env.S7_REPL ~= "" then
    table.insert(candidates, vim.env.S7_REPL)
  end
  table.insert(candidates, vim.fn.expand("~/repo/pas/derived/s7-playground/s7"))

  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  return "s7" -- 都沒有就賭 PATH 上有；沒有的話 Conjure 會在 log 裡報起不了 REPL
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "scheme" })
    end,
  },
  {
    "Olical/conjure",
    ft = { "scheme" },
    init = function()
      vim.g["conjure#filetype#scheme"] = "conjure.client.scheme.stdio"
      vim.g["conjure#client#scheme#stdio#command"] = s7_command()
      -- s7 的 REPL 提示字元就是 "> "（Conjure 的預設 pattern 是給 mit-scheme 的，對不上）
      vim.g["conjure#client#scheme#stdio#prompt_pattern"] = "> "
    end,
  },
}
