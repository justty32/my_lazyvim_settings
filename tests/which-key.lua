-- 回歸：log 被暫時切入後，LSP 清除來源 buffer 的前綴，仍須自動恢復。
local ok, err = xpcall(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
  require("lazy").load({ plugins = { "which-key.nvim" } })
  vim.api.nvim_exec_autocmds("VimEnter", {})
  vim.wait(300)
  local source = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", ",ee", function() end, { buffer = source })
  require("which-key.buf").get({ buf = source })
  vim.wait(100)
  local log = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(log, "conjure-log-regression.txt")
  vim.cmd.split()
  vim.api.nvim_win_set_buf(0, log)
  require("which-key.buf").get({ buf = log })
  vim.wait(100)
  vim.api.nvim_exec_autocmds("LspAttach", { group = "wk", buffer = source })
  vim.cmd("noautocmd wincmd p")
  vim.wait(200)
  assert(vim.fn.maparg(",", "n") == "", "Expected missing prefix before recovery")
  vim.api.nvim_exec_autocmds("LspAttach", { group = "user_which_key_lsp", buffer = source })
  assert(
    vim.wait(1000, function()
      return vim.fn.maparg(",", "n", false, true).desc == "which-key-trigger"
    end, 20),
    "Prefix recovery failed"
  )
  print("PASS: reproduced lost prefix after LSP attach; recovery restores it")
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd.cquit()
else
  vim.cmd("qa!")
end
