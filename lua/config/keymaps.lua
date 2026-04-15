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

-- Invert behaviour of 'p' & 'P'
map({ "v", "x" }, "p", "P", { desc = "Paste without overwriting register" })
map({ "v", "x" }, "P", "p", { desc = "Paste and overwrite register" })

-- x acts as cut to clipboard
map("n", "x", '"*dl', { desc = "Cut character (yank+delete)" })
map("n", "X", '"*dh', { desc = "Cut previous character (yank+delete)" })
map("v", "x", '"+d', { desc = "Cut selection to clipboard" })
map("v", "X", '"+d', { desc = "Cut selection to clipboard" })

-- Cmd + S : I constantly hit this from muscle memory, so why not?
map({ "n", "i", "v" }, "<D-s>", "<Cmd>w<CR>", { desc = "Save file" })

-- Cmd + C/V : copy & paste with the system clipboard
map("n", "<D-c>", '"+yy', { desc = "Copy line to clipboard" })
map("v", "<D-c>", '"+y', { desc = "Copy selection to clipboard" })
map("n", "<D-v>", '"+p', { desc = "Paste from clipboard" })
map("v", "<D-v>", '"+p', { desc = "Paste from clipboard" })
map("i", "<D-v>", "<C-r>+", { desc = "Paste from clipboard" })

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

-- Window splits under the <leader>w group
map("n", "<leader>wh", "<C-w>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>wv", "<C-w>v", { desc = "Split Window Right", remap = true })

-- Additional leader aliases for consistency in which-key
map("n", "<leader>ck", "<cmd>norm! K<cr>", { desc = "Keyword Help" })
map("n", "<leader>ul", "<cmd>Lazy<cr>", { desc = "Lazy" })
map("n", "<leader>uL", function()
  LazyVim.news.changelog()
end, { desc = "LazyVim Changelog" })

-- Terminal aliases under the <leader>w group
map("n", "<leader>wt", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })
map("n", "<leader>wT", function()
  Snacks.terminal()
end, { desc = "Terminal (cwd)" })

map("n", "<leader>wx", "<C-w>c", { desc = "Delete Window", remap = true })

-- Yank code location (file path + line number)
map("n", "<leader>yl", function()
  local loc = vim.fn.expand("%:.") .. ":" .. vim.fn.line(".")
  vim.fn.setreg("+", loc)
  vim.notify(loc, vim.log.levels.INFO, { title = "Yanked location" })
end, { desc = "Yank file location" })

map("v", "<leader>yl", function()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local loc = vim.fn.expand("%:.") .. ":" .. start_line .. "-" .. end_line
  vim.fn.setreg("+", loc)
  vim.notify(loc, vim.log.levels.INFO, { title = "Yanked location" })
end, { desc = "Yank file location (range)" })

map({ "n", "v" }, "<leader>yp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify(path, vim.log.levels.INFO, { title = "Yanked path" })
end, { desc = "Yank relative path" })

map({ "n", "v" }, "<leader>yP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify(path, vim.log.levels.INFO, { title = "Yanked path" })
end, { desc = "Yank absolute path" })

map({ "n", "v" }, "<leader>yf", function()
  local name = vim.fn.expand("%:t")
  vim.fn.setreg("+", name)
  vim.notify(name, vim.log.levels.INFO, { title = "Yanked filename" })
end, { desc = "Yank filename" })

map("n", "<leader>yg", function()
  local rel = vim.fn.expand("%:.")
  local line = vim.fn.line(".")
  local remote = vim.fn.system("git remote get-url origin 2>/dev/null"):gsub("\n", "")
  local sha = vim.fn.system("git rev-parse HEAD 2>/dev/null"):gsub("\n", "")
  if remote == "" or sha == "" then
    vim.notify("Not in a git repo with a remote", vim.log.levels.WARN, { title = "Yank GitHub link" })
    return
  end
  remote = remote:gsub("git@github.com:", "https://github.com/"):gsub("%.git$", "")
  local url = remote .. "/blob/" .. sha .. "/" .. rel .. "#L" .. line
  vim.fn.setreg("+", url)
  vim.notify(url, vim.log.levels.INFO, { title = "Yanked GitHub link" })
end, { desc = "Yank GitHub permalink" })

map("v", "<leader>yg", function()
  local rel = vim.fn.expand("%:.")
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  local remote = vim.fn.system("git remote get-url origin 2>/dev/null"):gsub("\n", "")
  local sha = vim.fn.system("git rev-parse HEAD 2>/dev/null"):gsub("\n", "")
  if remote == "" or sha == "" then
    vim.notify("Not in a git repo with a remote", vim.log.levels.WARN, { title = "Yank GitHub link" })
    return
  end
  remote = remote:gsub("git@github.com:", "https://github.com/"):gsub("%.git$", "")
  local url = remote .. "/blob/" .. sha .. "/" .. rel .. "#L" .. start_line .. "-L" .. end_line
  vim.fn.setreg("+", url)
  vim.notify(url, vim.log.levels.INFO, { title = "Yanked GitHub link" })
end, { desc = "Yank GitHub permalink (range)" })
