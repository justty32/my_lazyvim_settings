return {
  {
    "Olical/conjure",
    ft = { "hy" },
    init = function()
      vim.g["conjure#filetype#hy"] = "conjure.client.hy.stdio"
      vim.g["conjure#client#hy#stdio#command"] = 'hy -iu -c="Ready!"'
    end,
  },
}
