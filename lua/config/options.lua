-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Let each project opt into Prettier and own its formatting rules.
vim.g.lazyvim_prettier_needs_config = true

-- No tab line: it shows only each tab's window count and buffer name
-- ("2 [Scratch]  3 d//null"), and files are reached with pickers, not tabs.
vim.o.showtabline = 0
