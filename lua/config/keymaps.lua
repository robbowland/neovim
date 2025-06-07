-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("n", "H", "^", { desc = "Move to beginning of line" })
vim.keymap.set("n", "L", "$", { desc = "Move to end of line" })

-- Non-yank alterations
vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "n", "v" }, "c", '"_c', { desc = "Change without yanking" })

-- 'x' behaves like cut (delete + yank)
vim.keymap.set("n", "x", '"*dl', { desc = "Cut character (yank and delete)" })
vim.keymap.set("n", "X", '"*dh', { desc = "Cut previous character (yank and delete)" })
vim.keymap.set("v", "x", '"+d', { desc = "Cut selection to clipboard" })
vim.keymap.set("v", "X", '"+d', { desc = "Cut selection to clipboard" })

-- Cmd + S : I constantly hit this from muscle memory, so why not?
vim.keymap.set({ "n", "i", "v" }, "<D-s>", "<Cmd>w<CR>", { desc = "Save file" })

--  3 line movements
vim.keymap.set("n", "J", "3j", { noremap = true, silent = true })
vim.keymap.set("n", "K", "3k", { noremap = true, silent = true })

vim.keymap.set("v", "J", ":m '>+3<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "K", ":m '<-3<CR>gv=gv", { noremap = true, silent = true })
