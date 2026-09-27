-- REPL 設定統一見 conjure.lua。
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        janet_lsp = {
          -- 只用已建置的修正版；缺依賴時不回退到會執行初始化式的全域 LSP。
          enabled = vim.fn.executable("bwrap") == 1 and vim.fn.executable("janet") == 1 and vim.fn.filereadable(
            vim.fn.stdpath("data") .. "/janet-lsp-fixed/janet-lsp.jimage"
          ) == 1,
          cmd = {
            vim.fn.stdpath("config") .. "/scripts/janet-lsp",
            vim.fn.stdpath("data") .. "/janet-lsp-fixed/janet-lsp.jimage",
          },
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
