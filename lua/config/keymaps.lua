-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- Exit insert mode with 'jk'
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- H/L to move within line in normal mode
map("n", "H", "^", { desc = "Move to beginning of line" })
map("n", "L", "$", { desc = "Move to end of line" })

-- Deletions/changes without affecting registers
map({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
map({ "n", "v" }, "c", '"_c', { desc = "Change without yanking" })

-- x acts as cut to clipboard
map("n", "x", '"*dl', { desc = "Cut character (yank+delete)" })
map("n", "X", '"*dh', { desc = "Cut previous character (yank+delete)" })
map("v", "x", '"+d', { desc = "Cut selection to clipboard" })
map("v", "X", '"+d', { desc = "Cut selection to clipboard" })

-- Cmd + S : I constantly hit this from muscle memory, so why not?
map({ "n", "i", "v" }, "<D-s>", "<Cmd>w<CR>", { desc = "Save file" })

-- Move cursor 3 lines with Shift+J/K
map({ "n", "v" }, "J", "3j", { desc = "Move down 3 lines", noremap = true, silent = true })
map({ "n", "v" }, "K", "3k", { desc = "Move up 3 lines", noremap = true, silent = true })

-- Move actual lines with Alt+j/k
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move block down", noremap = true, silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move block up", noremap = true, silent = true })
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down", noremap = true, silent = true })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up", noremap = true, silent = true })
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down (insert)", noremap = true, silent = true })
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up (insert)", noremap = true, silent = true })
