vim.g.maplocalleader = ","

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.colorcolumn = "100"

-- 長行依視窗寬度顯示，不改動檔案中的實際換行。
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
