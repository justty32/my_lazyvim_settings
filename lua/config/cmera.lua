local M = {}

local function detect_lang(buf)
  local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
  if first:match("cm:%s*c%+%+") or first:match("cm:%s*cxx") then
    return "c++"
  end
  return "c"
end

local function notify(msg, level)
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

function M.build()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
  if file == "" then
    return
  end

  vim.cmd("silent! write")
  local lang = detect_lang(buf)
  --notify("C-Mera 編譯中: " .. file, "info")

  vim.system({ "cm", lang, file }, { text = true }, function(obj)
    vim.schedule(function()
      if obj.code ~= 0 then
        notify("編譯出錯 (Exit " .. obj.code .. "):\n" .. (obj.stderr or ""), "error")
        return
      end

      local content = obj.stdout or ""
      if content == "" then
        notify("執行成功但無產出。", "warn")
        return
      end
      local lines = vim.split(content:gsub("\r", ""), "\n")

      if _G.Snacks then
        local out_buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, lines)
        vim.bo[out_buf].filetype = (lang == "c++" and "cpp" or "c")

        _G.Snacks.win({
          buf = out_buf,
          width = 0.45,
          position = "right",
          backdrop = false,
          wo = { cursorline = true, number = true },
          keys = { ["q"] = "close" },
        })
      else
        vim.cmd("vnew")
        local new_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, lines)
        vim.bo[new_buf].filetype = (lang == "c++" and "cpp" or "c")
        vim.bo[new_buf].buftype = "nofile"
        vim.bo[new_buf].bufhidden = "wipe"
      end

      --notify("C-Mera 編譯成功！", "info")
    end)
  end)
end

vim.api.nvim_create_user_command("CmeraBuild", M.build, {})
return M
