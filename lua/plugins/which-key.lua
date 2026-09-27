return {
  {
    "folke/which-key.nvim",
    init = function()
      -- which-key 在 LspAttach/Detach 會清除該 buffer 的前綴。
      -- Conjure 建立隱藏 log 時可能讓它的 current_buf 留在 log，
      -- 輪詢因此不會重建程式碼 buffer；等事件處理完後明確重建。
      vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
        group = vim.api.nvim_create_augroup("user_which_key_lsp", { clear = true }),
        callback = function(event)
          vim.schedule(function()
            if
              vim.api.nvim_buf_is_valid(event.buf)
              and package.loaded["which-key.buf"]
              and require("which-key.config").loaded
            then
              require("which-key.buf").get({ buf = event.buf })
            end
          end)
        end,
      })
    end,
  },
}
