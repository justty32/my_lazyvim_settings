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
-- ★★★ 為什麼要包一層 stdbuf -o0（拿掉的話 REPL 會「起得來但永遠不回話」）
--   Conjure 的 stdio client 是靠「看到 prompt 字串」來判斷一次求值回完了沒。而 s7 的 `> ` prompt
--   走 **stdout**，stdout 接到 pipe（不是終端機）時 libc 預設是**全緩衝**——prompt 只有 2 bytes，
--   永遠填不滿 4KB 緩衝區，於是卡在 libc 裡出不來。Conjure 等不到 prompt，就一直認為「還沒回完」，
--   結果是：log 顯示 REPL started、eval 也送出去了，但**結果一行都不會出現**。
--   （s7 的 banner 走 stderr、stderr 無緩衝，所以你只看得到 banner——更像是「壞得很安靜」。）
--   在 shell 裡 `printf '(+ 1 2)' | s7` 之所以看得到 prompt 和結果，是因為 s7 讀到 EOF 就結束，
--   **退出時 libc 會 flush**——所以那個測法無法暴露這個 bug，別拿它當「REPL 沒問題」的證據。
--   stdbuf -o0 用 LD_PRELOAD 把 s7 的 stdout 改成無緩衝，prompt 就即時出得來。
--   注意必須是 -o0（無緩衝）不能是 -oL（行緩衝）：prompt 結尾沒有換行，行緩衝一樣不會 flush。
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

  local s7 = "s7" -- 都沒有就賭 PATH 上有；沒有的話 Conjure 會在 log 裡報起不了 REPL
  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then
      s7 = path
      break
    end
  end

  -- ⚠ 回傳**字串**不要回傳 table：Conjure 的 display-repl-status 會把 command 直接字串串接，
  --   completions 也會對它做 string.match——給 table 兩邊都會炸。字串會被 Conjure 依空白切開，
  --   所以路徑不能有空白（s7 的候選路徑都沒有，成立）。
  if vim.fn.executable("stdbuf") == 1 then
    return "stdbuf -o0 " .. s7 -- 見上方 ★★★：不包這層的話 prompt 出不來，REPL 會永遠不回話
  end
  return s7 -- 沒有 stdbuf（非 GNU coreutils 環境）：REPL 大概率會卡住，但至少不會直接起不來
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
