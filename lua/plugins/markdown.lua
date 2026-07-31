-- Markdown 寫的是筆記不是原始碼：關掉 lang.markdown extra 帶來的挑剔部分。
-- markdownlint 的警告（行長、標題層級、裸連結…）與存檔時 prettier/markdownlint --fix
-- 會重排段落，對中文筆記幫倒忙。語法高亮、render-markdown、marksman 連結跳轉保留。
return {
  -- 不再對 markdown 跑任何 formatter（空列表＝明確停用，不是「沒設定」）
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.markdown = {}
      opts.formatters_by_ft["markdown.mdx"] = {}
    end,
    -- 保險：即使有其他 formatter/LSP 想插手，也不對 markdown 存檔自動格式化
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown", "markdown.mdx" },
        callback = function()
          vim.b.autoformat = false
        end,
      })
    end,
  },

  -- 關掉 markdownlint 診斷
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}
    end,
  },

  -- none-ls 若有啟用，也把 markdownlint 來源拿掉
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      opts.sources = vim.tbl_filter(function(source)
        return source.name ~= "markdownlint_cli2" and source.name ~= "markdownlint-cli2"
      end, opts.sources or {})
    end,
  },
}
