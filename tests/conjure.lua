-- Run from this configuration repo with:
-- nvim --headless -i NONE '+luafile tests/conjure.lua'
local temp = vim.fn.tempname()
local original_cwd = vim.fn.getcwd()
local function check()
  vim.fn.mkdir(temp, "p")
  vim.fn.writefile({ '(declare-project :name "nvim-smoke" :version "0.0.0")' }, temp .. "/project.janet")
  vim.fn.writefile({ "(def answer 42)" }, temp .. "/helper.janet")
  vim.cmd.cd(vim.fn.fnameescape(temp))
  vim.cmd.edit("main.janet")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "(+ 20 22)" })
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  vim.wait(500)

  local config = require("conjure.config")
  assert(vim.bo.filetype == "janet", "Janet filetype detection failed")
  assert(vim.wo.wrap and vim.wo.linebreak and vim.wo.breakindent, "Visual wrapping must stay enabled")
  assert(
    vim.wait(8000, function()
      local clients = vim.lsp.get_clients({ bufnr = 0, name = "janet_lsp" })
      return clients[1] and clients[1].initialized
    end, 50),
    "Janet LSP did not attach"
  )
  local lsp = vim.lsp.get_clients({ bufnr = 0, name = "janet_lsp" })[1]
  assert(lsp.config.root_dir == temp, "Janet LSP project root mismatch")
  local hover = lsp:request_sync("textDocument/hover", {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    position = { line = 0, character = 1 },
  }, 5000, 0)
  assert(hover and hover.result and hover.result.contents, "Janet LSP hover failed")
  assert(config["get-in"]({ "filetype", "janet" }) == "conjure.client.janet.stdio")
  assert(config["get-in"]({ "client_on_load" }) == true, "Janet must start automatically")
  assert(config["get-in"]({ "log", "hud", "enabled" }) == true, "HUD must stay available")
  assert(config["get-in"]({ "filetype", "fennel" }) == "conjure.client.fennel.stdio")
  assert(config["get-in"]({ "filetype", "hy" }) == "conjure.client.hy.stdio")
  assert(config["get-in"]({ "client", "scheme", "stdio", "prompt_pattern" }) == "> ")
  for _, key in ipairs({ ",ee", ",er", ",eb", ",ls", ",cs", ",cS", ",lh", ",lt", "K" }) do
    assert(vim.fn.maparg(key, "n") ~= "", "Missing Janet mapping: " .. key)
  end
  assert(vim.treesitter.get_parser(0):lang() == "janet_simple")
  assert(not vim.treesitter.get_parser(0):parse()[1]:root():has_error())
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "No Janet highlighter")
  assert(vim.treesitter.query.get("janet_simple", "rainbow-delimiters"), "No rainbow query")
  assert(vim.g.parinfer_mode == "smart" and vim.g.parinfer_enabled == 1)
  assert(require("lazy.core.config").plugins["parinfer-rust"]._.loaded, "Parinfer not loaded")

  local client = require("conjure.client.janet.stdio")
  local function eval(code, expected)
    local result
    client["eval-str"]({
      code = code,
      ["on-result"] = function(value)
        result = value
      end,
    })
    assert(
      vim.wait(5000, function()
        return result ~= nil
      end, 20),
      "Janet evaluation timed out: " .. code
    )
    assert(vim.trim(result) == expected, "Unexpected Janet result: " .. vim.inspect(result))
  end
  eval("(+ 20 22)", "42")
  local log = require("conjure.log")
  local long_line = string.rep("長輸出 wrap ", 30)
  log.append({ long_line }, { ["break?"] = true })
  log.flush()
  local hud = log.state.hud.id
  assert(hud and vim.api.nvim_win_is_valid(hud), "No Conjure HUD")
  assert(vim.wo[hud].wrap, "HUD must wrap long output")
  local hud_buf = vim.api.nvim_win_get_buf(hud)
  local hud_lines = vim.api.nvim_buf_get_lines(hud_buf, 0, -1, false)
  local long_row
  for i, line in ipairs(hud_lines) do
    if line == long_line then
      long_row = i - 1
    end
  end
  assert(long_row, "Long output missing from HUD buffer")
  assert(vim.api.nvim_win_text_height(hud, { start_row = long_row, end_row = long_row }).all > 1)
  local initial_width = vim.api.nvim_win_get_width(hud)
  vim.cmd("normal ,lh")
  hud = log.state.hud.id
  assert(vim.api.nvim_win_get_width(hud) > initial_width, "HUD did not expand")
  assert(vim.wo[hud].wrap, "Expanded HUD must wrap")
  vim.cmd("normal ,lh")
  assert(vim.api.nvim_win_get_width(log.state.hud.id) == initial_width, "HUD did not shrink")
  local source_win = vim.api.nvim_get_current_win()
  vim.cmd("normal ,ll")
  local latest_win = vim.api.nvim_get_current_win()
  local window_count = #vim.api.nvim_tabpage_list_wins(0)
  vim.api.nvim_set_current_win(source_win)
  vim.cmd("normal ,ll")
  assert(vim.api.nvim_get_current_win() == latest_win, ",ll must reuse the existing log window")
  assert(#vim.api.nvim_tabpage_list_wins(0) == window_count, ",ll must not create duplicate splits")
  assert(vim.wo.wrap, "Split log must wrap long output")
  local log_buf = vim.api.nvim_get_current_buf()
  assert(vim.tbl_contains(vim.api.nvim_buf_get_lines(log_buf, 0, -1, false), long_line))
  local result_win = vim.api.nvim_get_current_win()
  vim.cmd("normal q")
  assert(not vim.api.nvim_win_is_valid(result_win), "q must close the result split")
  assert(vim.api.nvim_buf_is_valid(log_buf), "q must preserve result history")
  vim.api.nvim_set_current_win(source_win)
  assert(vim.fn.maparg("q", "n") == "", "q must remain unchanged in source buffers")
  local source_tab = vim.api.nvim_get_current_tabpage()
  log.tab()
  assert(vim.api.nvim_get_current_tabpage() ~= source_tab, "Log tab did not open")
  assert(vim.api.nvim_get_current_buf() == log_buf and vim.wo.wrap, "Log tab must reuse wrapped buffer")
  local result_tab = vim.api.nvim_get_current_tabpage()
  vim.cmd("normal q")
  assert(not vim.api.nvim_tabpage_is_valid(result_tab), "q must close the result tab")
  assert(vim.api.nvim_get_current_tabpage() == source_tab, "q must return to the source tab")
  eval("(def audit-value 41)", "41")
  eval("(+ audit-value 1)", "42")
  eval("(import ./helper) helper/answer", "42")
  client.stop()
  client.start()
  vim.wait(300)
  eval("(+ 40 2)", "42")
  client.stop()

  vim.cmd.enew({ bang = true })
  vim.cmd.setfiletype("lisp")
  vim.wait(200)
  assert(config["get-in"]({ "client_on_load" }) == false, "Lisp must connect manually")
  assert(config["get-in"]({ "filetype", "lisp" }) == "conjure.client.common-lisp.swank")
  vim.cmd.enew({ bang = true })
  vim.cmd.setfiletype("markdown")
  assert(vim.b.autoformat == false, "Markdown autoformat regression")
  print("PASS: Janet REPL/import/restart, LSP hover, highlighting, mappings, log wrapping, Lisp/Markdown settings")
end
local ok, err = xpcall(check, debug.traceback)
vim.cmd.cd(vim.fn.fnameescape(original_cwd))
vim.fn.delete(temp, "rf")
if not ok then
  print(err)
  vim.cmd.cquit()
else
  vim.cmd("qa!")
end
