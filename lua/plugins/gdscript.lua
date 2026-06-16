return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gdscript = {
          -- Godot editor must be running; it exposes LSP on port 6005
          cmd = vim.lsp.rpc.connect("127.0.0.1", 6005),
          filetypes = { "gdscript", "gd" },
          root_dir = function(bufnr, on_dir)
            on_dir(vim.fs.root(bufnr, { "project.godot", ".git" }))
          end,
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "gdscript", "godot_resource" })
    end,
  },
}
