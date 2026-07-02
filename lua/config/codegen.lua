local M = {}

local repo = vim.env.CODEGEN_REPO or vim.fn.expand("~/repo/codegen")
local src = repo .. "/src"
local venv_python = repo .. "/.venv/bin/python"

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

local function executable()
  if vim.fn.executable(venv_python) == 1 then
    return venv_python
  end
  return "python3"
end

local function current_path()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return nil
  end
  vim.cmd("silent! write")
  return file
end

local function root_for(path)
  local start = vim.fn.fnamemodify(path or vim.fn.getcwd(), ":p")
  if vim.fn.isdirectory(start) == 0 then
    start = vim.fn.fnamemodify(start, ":h")
  end

  local found = vim.fs.find({ "codegen.toml", ".git" }, { upward = true, path = start })[1]
  return found and vim.fn.fnamemodify(found, ":h") or vim.fn.getcwd()
end

local function show_output(title, obj)
  local lines = {}
  local stdout = vim.trim(obj.stdout or "")
  local stderr = vim.trim(obj.stderr or "")

  if stdout ~= "" then
    vim.list_extend(lines, vim.split(stdout, "\n", { plain = true }))
  end
  if stderr ~= "" then
    if #lines > 0 then
      table.insert(lines, "")
    end
    vim.list_extend(lines, vim.split(stderr, "\n", { plain = true }))
  end
  if #lines == 0 then
    lines = { "codegen: done" }
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Codegen://" .. title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "text"

  if _G.Snacks then
    _G.Snacks.win({
      buf = buf,
      height = 0.35,
      position = "bottom",
      backdrop = false,
      wo = { cursorline = true, number = false, wrap = false },
      keys = { ["q"] = "close" },
    })
  else
    vim.cmd("botright 12split")
    vim.api.nvim_win_set_buf(0, buf)
  end
end

local function run(args, opts)
  opts = opts or {}
  local target = opts.target
  local cwd = root_for(target)
  local cmd = { executable(), "-m", "codegen" }
  vim.list_extend(cmd, args)

  vim.system(cmd, {
    cwd = cwd,
    text = true,
    env = {
      PYTHONPATH = src,
    },
  }, function(obj)
    vim.schedule(function()
      show_output(table.concat(args, " "), obj)
      if obj.code == 0 then
        notify(opts.success or "codegen 執行完成。", "info")
        if opts.checktime then
          vim.cmd("checktime")
        end
      else
        notify("codegen 失敗 (Exit " .. obj.code .. ")。", "error")
      end
    end)
  end)
end

local function args_or_current(opts)
  if opts and opts.args and opts.args ~= "" then
    return vim.split(opts.args, "%s+", { trimempty = true }), opts.args
  end

  local file = current_path()
  if not file then
    notify("目前 buffer 沒有檔名，請先存檔或傳入 path。", "warn")
    return nil, nil
  end

  return { file }, file
end

function M.run(opts)
  local paths, target = args_or_current(opts)
  if not paths then
    return
  end

  local args = { "run" }
  vim.list_extend(args, paths)
  run(args, {
    target = target,
    checktime = true,
    success = "codegen 已套用。",
  })
end

function M.dry_run(opts)
  local paths, target = args_or_current(opts)
  if not paths then
    return
  end

  local args = { "run", "--dry-run" }
  vim.list_extend(args, paths)
  run(args, {
    target = target,
    success = "codegen dry-run 完成。",
  })
end

function M.rollback_list(opts)
  local paths, target = args_or_current(opts)
  if not paths then
    return
  end

  local args = { "rollback", "--list" }
  vim.list_extend(args, paths)
  run(args, {
    target = target,
    success = "codegen rollback 清單已更新。",
  })
end

function M.rollback(opts)
  local extra = opts and opts.args or ""
  local args = { "rollback" }
  if extra ~= "" then
    vim.list_extend(args, vim.split(extra, "%s+", { trimempty = true }))
  else
    local file = current_path()
    if not file then
      notify("目前 buffer 沒有檔名，請先存檔或傳入 path。", "warn")
      return
    end
    table.insert(args, file)
  end

  run(args, {
    target = args[#args],
    checktime = true,
    success = "codegen rollback 完成。",
  })
end

vim.api.nvim_create_user_command("CodegenRun", M.run, {
  nargs = "*",
  complete = "file",
})
vim.api.nvim_create_user_command("CodegenDryRun", M.dry_run, {
  nargs = "*",
  complete = "file",
})
vim.api.nvim_create_user_command("CodegenRollbackList", M.rollback_list, {
  nargs = "*",
  complete = "file",
})
vim.api.nvim_create_user_command("CodegenRollback", M.rollback, {
  nargs = "*",
  complete = "file",
})

return M
