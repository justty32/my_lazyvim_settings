-- REPL 設定統一見 conjure.lua。
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        janet_lsp = {
          -- 現機已確認 LSP 會執行 def 初始化式，可能觸發模型請求。
          -- 修正並驗證分析無副作用後才能重新啟用；Conjure REPL 不受影響。
          enabled = false,
          mason = false,
          root_markers = { "project.janet", ".git" },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "janet_simple" })
    end,
  },
}
