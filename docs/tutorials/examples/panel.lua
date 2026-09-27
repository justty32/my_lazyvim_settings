local M = {}

function M.open(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or { "你好，Janet！" })
  vim.bo[buf].modifiable = false
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 1,
    col = 2,
    width = math.max(1, math.min(80, vim.o.columns - 6)),
    height = math.max(1, math.min(12, vim.o.lines - 6)),
    style = "minimal",
    border = "rounded",
    title = " 練習結果 ",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, desc = "關閉練習結果" })
  return { buf = buf, win = win }
end

return M
