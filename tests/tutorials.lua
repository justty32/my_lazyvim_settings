-- Run from the repository root: nvim --clean --headless -l tests/tutorials.lua
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
local jobs = {}
local function wait_for(fn, label)
  assert(vim.wait(5000, fn, 10), "timeout: " .. label)
end
local function text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end
local function run(argv)
  local result = vim.system(argv, { text = true }):wait(5000)
  assert(result.code == 0, result.stderr)
  return result
end
local function wipe(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end
local function press_q()
  vim.api.nvim_feedkeys("q", "xt", false)
end
local function test()
  vim.o.swapfile = false
  vim.o.hidden = true
  vim.g.maplocalleader = ","
  local source = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(source, 0, -1, false, { "來源中文", "second line" })

  -- Window-local display options do not alter shared buffer text.
  vim.wo.wrap = true
  vim.cmd("vsplit")
  vim.wo.wrap = false
  assert(vim.wo[source_win].wrap)
  assert(vim.api.nvim_get_current_buf() == source)
  vim.cmd("close")
  vim.keymap.set("n", "<localleader>uw", function()
    vim.wo.wrap = not vim.wo.wrap
  end, { buffer = true, desc = "切換折行" })
  vim.api.nvim_feedkeys(",uw", "xt", false)
  assert(not vim.wo.wrap)
  vim.keymap.del("n", "<localleader>uw", { buffer = true })
  for _ = 1, 2 do
    local group = vim.api.nvim_create_augroup("MyJanetPractice", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "janet",
      callback = function(event)
        vim.keymap.set("n", "<localleader>uw", function()
          vim.wo.wrap = not vim.wo.wrap
        end, { buffer = event.buf, desc = "切換折行" })
      end,
    })
  end
  assert(#vim.api.nvim_get_autocmds({ group = "MyJanetPractice" }) == 1)
  vim.bo[source].filetype = "janet"
  assert(vim.fn.maparg(",uw", "n", false, true).buffer == 1)
  vim.cmd("enew")
  assert(vim.fn.maparg(",uw", "n") == "")
  vim.api.nvim_win_set_buf(source_win, source)
  vim.api.nvim_del_augroup_by_name("MyJanetPractice")
  vim.keymap.del("n", "<localleader>uw", { buffer = source })
  print("PASS options, local mappings, idempotent autocmd")

  local panel = dofile("docs/tutorials/examples/panel.lua").open({ string.rep("中文結果 ", 50), "按 q 返回" })
  assert(vim.wo[panel.win].wrap and not vim.bo[panel.buf].modifiable)
  vim.api.nvim_win_set_config(panel.win, { width = 40 })
  assert(vim.api.nvim_win_get_width(panel.win) == 40)
  assert(vim.api.nvim_buf_line_count(panel.buf) == 2)
  assert(vim.api.nvim_win_text_height(panel.win, {}).all > 2)
  press_q()
  assert(not vim.api.nvim_win_is_valid(panel.win))
  assert(not vim.api.nvim_buf_is_valid(panel.buf))
  assert(vim.api.nvim_get_current_buf() == source)
  print("PASS floating panel, resize, wrap, q returns to source")

  local stream = dofile("docs/tutorials/examples/stream.lua")
  local function start(argv)
    local state = stream.start(argv)
    jobs[#jobs + 1] = state
    return state
  end
  local cat = start({ "cat" })
  cat.send(table.concat(vim.api.nvim_buf_get_lines(source, 0, -1, false), "\n") .. "\n")
  wait_for(function()
    return text(cat.buf):find("來源中文", 1, true)
  end, "cat echo")
  cat.eof()
  wait_for(function()
    return cat.code ~= nil
  end, "cat eof")
  assert(cat.code == 0 and text(cat.buf):find("[stdout] second line", 1, true))
  press_q()
  assert(not vim.api.nvim_buf_is_valid(cat.buf))
  assert(text(source) == "來源中文\nsecond line")

  local py = start({
    "python3",
    "-u",
    "-c",
    "import os,time; b='你好'.encode(); os.write(1,b[:1]); time.sleep(.08); os.write(1,b[1:]+b'\\n'); os.write(2,b'problem\\n'); os.write(1,b'tail')",
  })
  wait_for(function()
    return py.code ~= nil
  end, "split UTF-8 and stderr")
  local output = text(py.buf)
  assert(output:find("[stdout] 你好", 1, true), output)
  assert(output:find("[stderr] problem", 1, true), output)
  assert(output:find("[stdout] tail", 1, true), output)
  assert(py.code == 0)
  wipe(py.buf)
  local blocked = start({ "cat" })
  press_q()
  wait_for(function()
    return blocked.code ~= nil
  end, "q stops running process")
  assert(not vim.api.nvim_buf_is_valid(blocked.buf))
  local windows_before_failure = #vim.api.nvim_list_wins()
  assert(not pcall(stream.start, { "/definitely/missing/tutorial-command" }))
  assert(#vim.api.nvim_list_wins() == windows_before_failure)
  print("PASS stdin, stdout, stderr, partial UTF-8, EOF tail, q stops job, start failure")

  local fifo = tmp .. "/有 空白.fifo"
  run({ "mkfifo", fifo })
  local reader = start({ "cat", fifo })
  local writer = start({
    "python3",
    "-u",
    "-c",
    "import sys; f=open(sys.argv[1], 'wb', buffering=0); f.write(sys.stdin.buffer.read()); f.close()",
    fifo,
  })
  writer.send("FIFO 你好\n第二行\n")
  writer.eof()
  wait_for(function()
    return reader.code ~= nil and writer.code ~= nil
  end, "FIFO round trip")
  assert(reader.code == 0 and writer.code == 0)
  assert(text(reader.buf):find("[stdout] FIFO 你好\n[stdout] 第二行", 1, true))
  wipe(reader.buf)
  wipe(writer.buf)
  reader = start({ "cat", fifo })
  run({ "sh", "-c", 'exec 3> "$1"; printf "first\\n" >&3; printf "second\\n" >&3; exec 3>&-', "sh", fifo })
  wait_for(function()
    return reader.code ~= nil
  end, "held FIFO fd")
  assert(text(reader.buf):find("[stdout] first\n[stdout] second", 1, true))
  wipe(reader.buf)
  local waiting = start({ "cat", fifo })
  local tick = false
  vim.defer_fn(function()
    tick = true
  end, 20)
  wait_for(function()
    return tick
  end, "UI loop while FIFO open waits")
  press_q()
  wait_for(function()
    return waiting.code ~= nil
  end, "stop waiting FIFO reader")
  print("PASS FIFO read/write, spaced path, persistent writer FD, nonblocking editor")

  -- Exercise require cache and repeatable command setup in an isolated runtimepath.
  vim.fn.mkdir(tmp .. "/lua/mytools", "p")
  local module_path = tmp .. "/lua/mytools/greeting.lua"
  -- Execute the actual greeting example printed in the tutorial, not a transcription.
  local tutorial = table.concat(vim.fn.readfile("docs/tutorials/modules.md"), "\n")
  local greeting_code = assert(tutorial:match("```lua\n(%-%- lua/mytools/greeting.lua.-)\n```"))
  vim.fn.writefile(vim.split(greeting_code, "\n", { plain = true }), module_path)
  vim.opt.rtp:prepend(tmp)
  local notify = vim.notify
  local message
  vim.notify = function(value)
    message = value
  end
  require("mytools.greeting").setup()
  vim.cmd("MyHello")
  vim.notify = notify
  assert(message == "你好，Janet 使用者")
  package.loaded["mytools.greeting"] = nil
  local function module_content(word)
    return {
      "local M = {}",
      "function M.hello(name) vim.g.tutorial_greeting = '" .. word .. "' .. name end",
      "function M.setup() vim.api.nvim_create_user_command('MyHello', function() M.hello('Janet') end, {force=true}) end",
      "return M",
    }
  end
  vim.fn.writefile(module_content("你好"), module_path)
  local old = require("mytools.greeting")
  old.setup()
  old.setup()
  vim.cmd("MyHello")
  assert(vim.g.tutorial_greeting == "你好Janet")
  vim.fn.writefile(module_content("再見"), module_path)
  assert(require("mytools.greeting") == old)
  package.loaded["mytools.greeting"] = nil
  require("mytools.greeting").setup()
  vim.cmd("MyHello")
  assert(vim.g.tutorial_greeting == "再見Janet")
  old.hello("Janet")
  assert(vim.g.tutorial_greeting == "你好Janet")
  vim.cmd("delcommand MyHello")
  print("PASS require cache, reload, old references, command replacement")

  vim.cmd("enew")
  local oneshot = vim.api.nvim_get_current_buf()
  vim.cmd("0read !printf 'hello\\n'")
  assert(text(oneshot):find("hello", 1, true))
  vim.api.nvim_buf_set_lines(oneshot, 0, -1, false, { "hello", "world" })
  -- :write ! sends input without replacing text; :! over a range filters it.
  vim.cmd("silent 1,2write !cat > " .. vim.fn.shellescape(tmp .. "/sent.txt"))
  assert(text(oneshot) == "hello\nworld")
  assert(table.concat(vim.fn.readfile(tmp .. "/sent.txt"), "\n") == "hello\nworld")
  vim.cmd("silent 1,2!tr a-z A-Z")
  assert(text(oneshot) == "HELLO\nWORLD")
  local async_result
  vim.system(
    { "python3", "-c", "import sys; print('out'); print('err', file=sys.stderr)" },
    { text = true },
    function(result)
      async_result = result
    end
  )
  wait_for(function()
    return async_result ~= nil
  end, "vim.system callback")
  assert(async_result.code == 0 and async_result.stdout == "out\n" and async_result.stderr == "err\n")
  wipe(oneshot)
  print("PASS read command, write to stdin, range filter, async vim.system result")

  local path = tmp .. "/watch.txt"
  vim.fn.writefile({ "original" }, path)
  vim.cmd.edit(path)
  local filebuf = vim.api.nvim_get_current_buf()
  vim.o.autoread = true
  vim.fn.writefile({ "outside longer" }, path)
  vim.cmd("checktime")
  assert(text(filebuf) == "outside longer" and not vim.bo[filebuf].modified)
  local reasons = {}
  vim.api.nvim_create_autocmd("FileChangedShell", {
    buffer = filebuf,
    callback = function()
      reasons[#reasons + 1] = vim.v.fcs_reason
      vim.v.fcs_choice = "" -- Preserve text, suppress interactive prompt in headless tests only.
    end,
  })
  vim.api.nvim_buf_set_lines(filebuf, 0, -1, false, { "unsaved in memory" })
  vim.fn.writefile({ "outside changed again much longer" }, path)
  vim.cmd("checktime")
  assert(reasons[#reasons] == "conflict", vim.inspect(reasons))
  assert(text(filebuf) == "unsaved in memory" and vim.bo[filebuf].modified)
  vim.cmd("edit!")
  assert(text(filebuf) == "outside changed again much longer")
  vim.bo[filebuf].autoread = false
  vim.fn.writefile({ "short" }, path)
  vim.cmd("checktime")
  assert(reasons[#reasons] == "changed")
  assert(text(filebuf) == "outside changed again much longer")
  vim.bo[filebuf].autoread = true
  vim.fn.delete(path)
  vim.cmd("checktime")
  assert(reasons[#reasons] == "deleted")
  assert(text(filebuf) == "outside changed again much longer")
  print("PASS checktime clean reload, dirty conflict, edit!, noautoread, deleted file preservation")
end

local ok, err = xpcall(test, debug.traceback)
for _, state in ipairs(jobs) do
  state.stop()
end
vim.fn.delete(tmp, "rf")
if not ok then
  io.stderr:write(err .. "\n")
  vim.cmd("cquit 1")
end
print("All tutorial checks passed")
vim.cmd("qa!")
