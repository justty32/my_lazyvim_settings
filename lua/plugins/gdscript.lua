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
      vim.list_extend(opts.ensure_installed, { "gdscript", "godot_resource", "gdshader" })
    end,
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    opts = function()
      local dap = require("dap")
      -- Godot editor must be running; it exposes DAP on port 6006
      dap.adapters.godot = dap.adapters.godot
        or {
          type = "server",
          host = "127.0.0.1",
          port = 6006,
        }
      dap.configurations.gdscript = dap.configurations.gdscript
        or {
          {
            type = "godot",
            request = "launch",
            name = "Launch scene",
            project = "${workspaceFolder}",
          },
        }
    end,
  },
}
