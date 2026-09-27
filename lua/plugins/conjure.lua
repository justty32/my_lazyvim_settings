-- 同一個 plugin 的 init 不會合併；所有 Conjure 設定集中在這裡。
-- stdio REPL 隨檔案啟動；Common Lisp 保留手動連接外部 Swank。
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
    return "stdbuf -o0 " .. s7 -- prompt 沒有換行；pipe 的 stdout 必須無緩衝，否則求值會卡住
  end
  return s7 -- 沒有 stdbuf（非 GNU coreutils 環境）：REPL 大概率會卡住，但至少不會直接起不來
end

return {
  {
    "Olical/conjure",
    ft = { "lisp", "fennel", "hy", "scheme", "janet" },
    keys = {
      {
        "<localleader>le",
        function()
          local log = require("conjure.log")
          local buf = vim.api.nvim_get_current_buf()
          if not log["log-buf?"](vim.api.nvim_buf_get_name(buf)) then
            local win = vim.api.nvim_get_current_win()
            log.buf()
            vim.w.conjure_log_origin = { buf = buf, win = win }
          end
        end,
        ft = { "janet", "lisp", "fennel", "hy", "scheme" },
        desc = "Open log in current window (q returns to source)",
      },
      {
        "<localleader>ll",
        function()
          local log = require("conjure.log")
          local target
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if win ~= log.state.hud.id and log["log-buf?"](vim.api.nvim_buf_get_name(buf)) then
              target = win
              break
            end
          end
          if target then
            vim.api.nvim_set_current_win(target)
          else
            log.split()
          end
          log["jump-to-latest"]()
        end,
        ft = { "janet", "lisp", "fennel", "hy", "scheme" },
        desc = "Open log and jump to latest result",
      },
      {
        "<localleader>lh",
        function()
          local expanded = vim.g["conjure#log#hud#width"] > 0.6
          vim.g["conjure#log#hud#width"] = expanded and 0.55 or 0.85
          vim.g["conjure#log#hud#height"] = expanded and 0.4 or 0.75
          -- 重新建立預覽套用尺寸，沿用既有 log，不重新求值。
          local log = require("conjure.log")
          log["close-hud"]()
          require("conjure.hook").exec("display-hud", {})
        end,
        ft = { "janet", "lisp", "fennel", "hy", "scheme" },
        desc = "Toggle REPL preview size",
      },
    },
    init = function()
      vim.g["conjure#client_on_load"] = false
      vim.g["conjure#log#hud#enabled"] = true
      vim.g["conjure#log#wrap"] = true
      -- 內建版本不會開啟 log，改由上面的鍵位開啟／聚焦再跳轉。
      vim.g["conjure#mapping#log_jump_to_latest"] = false
      vim.g["conjure#mapping#log_buf"] = false
      -- 完整 log 已開啟時，即使正在往回捲動，也不另外跳出 HUD。
      vim.g["conjure#log#hud#open_when"] = "log-win-not-visible"
      vim.g["conjure#log#botright"] = true
      vim.g["conjure#log#split#height"] = 0.33
      vim.g["conjure#log#hud#width"] = 0.55
      vim.g["conjure#log#hud#height"] = 0.4
      vim.g["conjure#filetype#lisp"] = "conjure.client.common-lisp.swank"
      vim.g["conjure#client#common_lisp#swank#connection#default_host"] = "127.0.0.1"
      vim.g["conjure#client#common_lisp#swank#connection#default_port"] = 4005
      vim.g["conjure#filetype#fennel"] = "conjure.client.fennel.stdio"
      vim.g["conjure#client#fennel#stdio#command"] = "fennel"
      vim.g["conjure#filetype#hy"] = "conjure.client.hy.stdio"
      vim.g["conjure#client#hy#stdio#command"] = 'hy -iu -c="Ready!"'
      vim.g["conjure#filetype#scheme"] = "conjure.client.scheme.stdio"
      vim.g["conjure#client#scheme#stdio#command"] = s7_command()
      vim.g["conjure#client#scheme#stdio#prompt_pattern"] = "> "
      vim.g["conjure#filetype#janet"] = "conjure.client.janet.stdio"
      vim.g["conjure#client#janet#stdio#command"] = "janet -n -s"

      local stdio = { fennel = true, hy = true, scheme = true, janet = true }
      local function configure_buffer(buf)
        vim.b[buf]["conjure#client_on_load"] = stdio[vim.bo[buf].filetype] == true
      end
      local group = vim.api.nvim_create_augroup("user_conjure", { clear = true })
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = group,
        pattern = "conjure-log-*",
        callback = function(event)
          if vim.bo[event.buf].buftype ~= "nofile" then
            return
          end
          vim.keymap.set("n", "q", function()
            -- ,le 借用原視窗，q 應還原來源；split/tab 則關閉視窗。
            local origin = vim.w.conjure_log_origin
            if origin and origin.win == vim.api.nvim_get_current_win() then
              vim.w.conjure_log_origin = nil
              if vim.api.nvim_buf_is_valid(origin.buf) then
                vim.api.nvim_win_set_buf(0, origin.buf)
                return
              end
            end
            -- 保留 log 與 REPL；只關閉正在查看的視窗／分頁。
            local windows = vim.tbl_filter(function(win)
              return vim.api.nvim_win_get_config(win).relative == ""
            end, vim.api.nvim_list_wins())
            if #windows == 1 then
              vim.cmd.enew()
            else
              vim.cmd.close()
            end
          end, { buffer = event.buf, desc = "Close REPL result window" })
        end,
      })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(event)
          configure_buffer(event.buf)
        end,
      })
      configure_buffer(vim.api.nvim_get_current_buf())
    end,
  },
}
