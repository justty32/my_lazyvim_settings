local M = {}

-- C-Mera 關鍵字高亮見 queries/commonlisp/highlights.scm（treesitter query）。

local generators = {
  c = { filetype = "c", extension = "c" },
  ["c++"] = { filetype = "cpp", extension = "cpp" },
  cxx = { filetype = "cpp", extension = "cpp", cli = "c++" },
  cuda = { filetype = "cuda", extension = "cu" },
  glsl = { filetype = "glsl", extension = "glsl" },
  ocl = { filetype = "opencl", extension = "cl" },
  opencl = { filetype = "opencl", extension = "cl", cli = "ocl" },
}

local function detect_lang(buf)
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  if first:match("cm:%s*c%+%+") or first:match("cm:%s*cxx") then
    return "c++"
  end
  local marker = first:match("cm:%s*([%w%+%-_]+)")
  if marker and generators[marker] then
    return marker
  end
  return "c"
end

local function notify(msg, level)
  level = level or "info"
  if _G.Snacks and _G.Snacks.notify then
    local fn = _G.Snacks.notify[level]
    if type(fn) == "function" then
      fn(msg)
    else
      _G.Snacks.notify.info(msg)
    end
  else
    vim.notify(msg, vim.log.levels[level:upper()] or vim.log.levels.INFO)
  end
end

local function output_meta(generator)
  return generators[generator] or generators.c
end

local function generator_arg(generator)
  return output_meta(generator).cli or generator
end

local function current_file()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    notify("目前 buffer 沒有檔名，請先存檔。", "warn")
    return nil
  end

  vim.cmd("silent! write")
  return buf, vim.fn.fnamemodify(file, ":p")
end

local function run_cm(generator, file, callback)
  local cmd = { "cm", generator_arg(generator), file }
  local cwd = vim.fn.fnamemodify(file, ":h")

  vim.system(cmd, { text = true, cwd = cwd }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        local err = vim.trim(obj.stderr or obj.stdout or "")
        notify("C-Mera 編譯出錯 (Exit " .. obj.code .. "):\n" .. err, "error")
        return
      end

      callback(obj)
    end)
  end)
end

local function write_output(out, content)
  if content == "" then
    notify("C-Mera 執行成功但沒有 stdout 輸出，未寫入空檔。", "warn")
    return false
  end

  local lines = vim.split(content:gsub("\r", ""), "\n")
  if lines[#lines] == "" then
    table.remove(lines)
  end

  local ok, err = pcall(vim.fn.writefile, lines, out)
  if not ok then
    notify("C-Mera 寫檔失敗: " .. err, "error")
    return false
  end

  return true
end

-- 重複執行 preview 時更新同一個視窗，而不是每次疊一個新的。
local preview = {}

local function preview_output(generator, content)
  if content == "" then
    notify("C-Mera 執行成功但沒有 stdout 輸出。", "warn")
    return
  end

  local lines = vim.split(content:gsub("\r", ""), "\n")
  local meta = output_meta(generator)

  local buf = preview.buf
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
    preview.buf = buf
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  if vim.bo[buf].filetype ~= meta.filetype then
    vim.bo[buf].filetype = meta.filetype
  end

  if preview.win and vim.api.nvim_win_is_valid(preview.win) then
    return
  end

  if _G.Snacks then
    local win = _G.Snacks.win({
      buf = buf,
      width = 0.45,
      position = "right",
      backdrop = false,
      -- bufhidden 保持 hide，關窗後 buffer 留著給下一次 preview 重用
      bo = { buftype = "nofile", bufhidden = "hide" },
      wo = { cursorline = true, number = true },
      keys = { ["q"] = "close" },
    })
    preview.win = win and win.win
  else
    vim.cmd("vsplit")
    preview.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(preview.win, buf)
  end
end

function M.preview(opts)
  local buf, file = current_file()
  if not file then
    return
  end

  local generator = opts and opts.args ~= "" and opts.args or detect_lang(buf)
  run_cm(generator, file, function(obj)
    preview_output(generator, obj.stdout or "")
  end)
end

function M.write(opts)
  local buf, file = current_file()
  if not file then
    return
  end

  local generator = opts and opts.args ~= "" and opts.args or detect_lang(buf)
  local meta = output_meta(generator)
  local out = vim.fn.fnamemodify(file, ":r") .. "." .. meta.extension

  run_cm(generator, file, function(obj)
    if write_output(out, obj.stdout or "") then
      notify("C-Mera 已寫出: " .. out, "info")
    end
  end)
end

function M.open_output(opts)
  local buf, file = current_file()
  if not file then
    return
  end

  local generator = opts and opts.args ~= "" and opts.args or detect_lang(buf)
  local meta = output_meta(generator)
  local out = vim.fn.fnamemodify(file, ":r") .. "." .. meta.extension

  run_cm(generator, file, function(obj)
    if write_output(out, obj.stdout or "") then
      vim.cmd.edit(vim.fn.fnameescape(out))
      vim.bo.filetype = meta.filetype
    end
  end)
end

local function complete_generators()
  return vim.tbl_keys(generators)
end

vim.filetype.add({
  extension = {
    cmera = "lisp",
  },
})

local group = vim.api.nvim_create_augroup("user_cmera", { clear = true })

-- C-Mera 源碼 (.cmera) 靠 `cm` 重新產生，原始檔不需要 format-on-save。
-- 關掉 LazyVim 的自動格式化，避免每次 :w 都對它跑 lisp_format。
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = group,
  pattern = "*.cmera",
  callback = function(args)
    vim.b[args.buf].autoformat = false
  end,
})

vim.api.nvim_create_user_command("CmeraPreview", M.preview, {
  nargs = "?",
  complete = complete_generators,
})
vim.api.nvim_create_user_command("CmeraWrite", M.write, {
  nargs = "?",
  complete = complete_generators,
})
vim.api.nvim_create_user_command("CmeraOpen", M.open_output, {
  nargs = "?",
  complete = complete_generators,
})

vim.api.nvim_create_user_command("CmeraBuild", M.preview, {
  nargs = "?",
  complete = complete_generators,
})

return M
