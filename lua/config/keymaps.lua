-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
require("config.cmera")
require("config.codegen")
vim.keymap.set("n", "<leader>cb", "<cmd>CmeraPreview<cr>", { desc = "C-Mera Preview" })
vim.keymap.set("n", "<leader>cp", "<cmd>CmeraPreview<cr>", { desc = "C-Mera Preview" })
vim.keymap.set("n", "<leader>cw", "<cmd>CmeraWrite<cr>", { desc = "C-Mera Write Output" })
vim.keymap.set("n", "<leader>co", "<cmd>CmeraOpen<cr>", { desc = "C-Mera Write and Open Output" })
vim.keymap.set("n", "<leader>cgr", "<cmd>CodegenRun<cr>", { desc = "Codegen Run" })
vim.keymap.set("n", "<leader>cgd", "<cmd>CodegenDryRun<cr>", { desc = "Codegen Dry Run" })
vim.keymap.set("n", "<leader>cgl", "<cmd>CodegenRollbackList<cr>", { desc = "Codegen Rollback List" })
vim.keymap.set("n", "<leader>cgR", "<cmd>CodegenRollback<cr>", { desc = "Codegen Rollback" })

-- LazyGit
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })

-- Window resize
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { silent = true })

-- jk to exit insert mode
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Ctrl+S to save
vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
