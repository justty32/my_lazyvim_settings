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

  -- 2. 核心修正：徹底禁用 vim-sexp (世界太平版)
  -- 這樣你就再也不會遇到「無法貼上」或「括號跳轉」的問題了
  { "guns/vim-sexp", ft = { "lisp" }, enabled = false },
  {
    "tpope/vim-sexp-mappings-for-regular-people",
    ft = { "lisp" },
    dependencies = { "guns/vim-sexp" },
    enabled = false,
  },

  -- 3. 修正 autopairs 行為，防止它在你輸入右括號時亂跳
  {
    "windwp/nvim-autopairs",
    -- opts = { enable_moveright = false, },
  },

  -- 4. Conjure REPL (保留強大的即時求值功能)
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

  -- 5. 載入自訂建置邏輯
  {
    "nvim-lua/plenary.nvim",
    config = function()
      require("config.cmera")
    end,
  },
}
