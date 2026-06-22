return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    ft = {
      "lisp",
      "clojure",
      "scheme",
      "racket",
      "fennel",
      "hy",
      "janet",
    },
    config = function()
      local rainbow = require("rainbow-delimiters")

      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow.strategy["global"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lisp = "rainbow-parens",
          clojure = "rainbow-parens",
          scheme = "rainbow-parens",
          racket = "rainbow-parens",
          fennel = "rainbow-parens",
        },
      }
    end,
  },
}
