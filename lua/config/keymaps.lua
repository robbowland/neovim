-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set("n", "H", "^", { desc = "Move to beginning of line" })
vim.keymap.set("n", "L", "$", { desc = "Move to end of line" })

vim.keymap.set({ "n", "v" }, "x", '"_x', { desc = "Delete character without yanking" })
vim.keymap.set({ "n", "v" }, "d", '"_d', { desc = "Delete without yanking" })
vim.keymap.set({ "n", "v" }, "c", '"_c', { desc = "Change without yanking" })

-- Cmd + S : I constantly hit this from muscle memory, so why not?
vim.keymap.set({ "n", "i", "v" }, "<D-s>", "<Cmd>w<CR>", { desc = "Save file" })
