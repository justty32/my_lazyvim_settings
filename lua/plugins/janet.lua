-- REPL 設定統一見 conjure.lua。
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        janet_lsp = {
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
