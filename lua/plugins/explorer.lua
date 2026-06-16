return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}

      local explorer = opts.picker.sources.explorer or {}
      local user_on_show = explorer.on_show
      local user_on_close = explorer.on_close

      local function explorer_width(picker)
        local root = picker.layout and picker.layout.root
        if root and root.win and vim.api.nvim_win_is_valid(root.win) then
          return vim.api.nvim_win_get_width(root.win)
        end
      end

      local function restore_width(picker)
        local width = vim.g.snacks_explorer_session_width
        if type(width) ~= "number" or width <= 0 then
          return
        end

        vim.schedule(function()
          local root = picker.layout and picker.layout.root
          if root and root.win and vim.api.nvim_win_is_valid(root.win) then
            pcall(vim.api.nvim_win_set_width, root.win, width)
          end
        end)
      end

      explorer.on_show = function(picker)
        restore_width(picker)
        if user_on_show then
          user_on_show(picker)
        end
      end

      explorer.on_close = function(picker)
        local width = explorer_width(picker)
        if width then
          vim.g.snacks_explorer_session_width = width
        end
        if user_on_close then
          user_on_close(picker)
        end
      end

      opts.picker.sources.explorer = explorer
    end,
  },
}
