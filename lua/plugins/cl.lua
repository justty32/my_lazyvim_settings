-- Common Lisp（SBCL）：Conjure 走 Swank（SLIME 後端）。
--
-- 跟 scheme/janet 一樣的「REPL 一直開、邊寫邊試」，但 CL 是 **connect 模式**：
-- 要先在外面跑一個 swank 伺服器，nvim 這邊再 `,cc` 連上去。
--
-- 起 swank（在 cl-lab 專案裡，會順便載入 :cl-lab）：
--     cd ~/code/cl-lab && scripts/run.sh swank        # 監聽 127.0.0.1:4005
-- 然後 nvim 開任何 .lisp 檔 → `,cc` 連線 → `,ee` 求值。
--
-- filetype 是 "lisp"（Common Lisp 檔）。與 scheme(s7)/janet/clojure 各自獨立、不衝突。
--
-- ★ 為什麼把設定寫在檔案 body 而不是 conjure spec 的 init：hy/fennel/scheme/janet/cl 都對同一個
--   Olical/conjure plugin 各給一份 spec，lazy 合併時 `init` 是後載入者覆蓋前者（cl.lua 依字母序
--   在多數之前，init 會被蓋掉）。寫在 body 於啟動時無條件執行、不進合併，Conjure 載入時沿用既有 g: 值。
--   （與 janet.lua 同一個坑、同一個解法。）
--
-- parinfer 與 rainbow-delimiters 的 ft 清單本來就有 "lisp"，不必重設。
vim.g["conjure#filetype#lisp"] = "conjure.client.common-lisp.swank"

return {
  {
    "Olical/conjure",
    ft = { "lisp" },
  },
}
