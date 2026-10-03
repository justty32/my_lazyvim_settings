-- 全部用插件預設的 `rainbow-delimiters` query，不要另外指定 query 表：
-- 表的 key 是 treesitter 語言名（lisp 檔是 `commonlisp`），而 `rainbow-parens`
-- 只有 JS/TS 系有——指定它反而讓 scheme/fennel 等語言查不到 query、完全沒有彩虹（踩過）。
-- hy 沒有 treesitter parser，不列。
return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    ft = {
      "lisp",
      "clojure",
      "scheme",
      "racket",
      "fennel",
      "janet",
    },
  },
}
