return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      -- parinfer owns Lisp indentation and parenthesis structure.
      -- An empty list explicitly disables whole-buffer formatting.
      lisp = {},
    },
  },
}
