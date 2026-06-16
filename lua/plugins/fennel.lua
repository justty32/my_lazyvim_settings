return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "fennel" })
    end,
  },
  {
    "Olical/conjure",
    ft = { "fennel" },
    init = function()
      vim.g["conjure#filetype#fennel"] = "conjure.client.fennel.stdio"
      vim.g["conjure#client#fennel#stdio#command"] = "fennel"
    end,
  },
}
