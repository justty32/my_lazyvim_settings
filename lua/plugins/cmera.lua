return {
  -- 1. 語法高亮 (保留 Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "commonlisp" })
      end
    end,
  },

  -- 2. Conjure REPL (保留強大的即時求值功能)
  {
    "Olical/conjure",
    ft = { "lisp" },
    init = function()
      vim.g["conjure#client_on_load"] = false
      vim.g["conjure#filetype#lisp"] = "conjure.client.common-lisp.swank"
      vim.g["conjure#client#common_lisp#swank#connection#default_host"] = "127.0.0.1"
      vim.g["conjure#client#common_lisp#swank#connection#default_port"] = 4005
    end,
  },
}
