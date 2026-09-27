-- Teaching example: bounded, line-oriented text log; no terminal emulation.
local M = {}

function M.start(argv)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false
  vim.cmd("botright 10split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].wrap = true
  local state = { buf = buf, win = win, job = nil, code = nil }
  local pending = { stdout = "", stderr = "" }
  local max_lines, max_fragment = 2000, 65536

  local function append(line)
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.bo[buf].modifiable = true
    local count = vim.api.nvim_buf_line_count(buf)
    local empty = count == 1 and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
    vim.api.nvim_buf_set_lines(buf, empty and 0 or -1, -1, false, { line })
    count = vim.api.nvim_buf_line_count(buf)
    if count > max_lines then
      vim.api.nvim_buf_set_lines(buf, 0, count - max_lines, false, {})
    end
    vim.bo[buf].modifiable = false
  end

  local function receive(_, data, stream)
    if #data == 1 and data[1] == "" then
      if pending[stream] ~= "" then
        append("[" .. stream .. "] " .. pending[stream])
      end
      pending[stream] = ""
      return
    end
    pending[stream] = pending[stream] .. data[1]
    for i = 2, #data do
      append("[" .. stream .. "] " .. pending[stream])
      pending[stream] = data[i]
    end
    if #pending[stream] > max_fragment then
      append("[" .. stream .. "] [未換行資料過長，已丟棄此片段]")
      pending[stream] = ""
    end
  end

  function state.stop()
    if state.job and state.job > 0 and state.code == nil then
      vim.fn.jobstop(state.job)
    end
  end

  vim.api.nvim_create_autocmd("BufWipeout", { buffer = buf, once = true, callback = state.stop })
  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, desc = "關閉練習 log 並停止程序" })
  local ok, job = pcall(vim.fn.jobstart, argv, {
    on_stdout = receive,
    on_stderr = receive,
    on_exit = function(_, code)
      state.code = code
      append("[exit] " .. code)
    end,
  })
  if not ok or job <= 0 then
    vim.api.nvim_win_close(win, true)
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    error("無法啟動程序：" .. vim.inspect(argv) .. " (" .. tostring(job) .. ")")
  end
  state.job = job

  function state.send(text)
    assert(state.code == nil, "程序已退出")
    return vim.fn.chansend(state.job, text)
  end

  function state.eof()
    vim.fn.chanclose(state.job, "stdin")
  end

  return state
end

return M
