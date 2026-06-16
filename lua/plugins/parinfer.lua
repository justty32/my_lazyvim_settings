return {
  {
    "eraserhd/parinfer-rust",
    ft = {
      "clojure",
      "scheme",
      "lisp",
      "racket",
      "hy",
      "fennel",
      "janet",
      "carp",
      "wast",
      "yuck",
      "dune",
    },
    build = "cargo build --release",
    init = function()
      vim.g.parinfer_mode = "smart"
      vim.g.parinfer_enabled = 1
    end,
  },
}
