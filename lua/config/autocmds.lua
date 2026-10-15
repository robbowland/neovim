-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Never hang on the way out with no UI left. When the terminal or tmux goes
-- (a crash, a quit, a closed pane), every nvim in it is told to exit at once
-- and they race to write ShaDa; the loser's error (E886, E136) makes nvim wait
-- for a key that nothing can send, for good. With no UI left: write ShaDa with
-- its errors silenced, skip nvim's own write, and end once the exit
-- autocommands have run. (weaver's nvims do the same.)
local function orphaned()
  return #vim.api.nvim_list_uis() == 0 and not vim.tbl_contains(vim.v.argv, "--headless")
end
local exit_guard = vim.api.nvim_create_augroup("exit_guard", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = exit_guard,
  callback = function()
    if orphaned() then
      pcall(vim.cmd, "silent! wshada")
      vim.o.shada = ""
    end
  end,
})
vim.api.nvim_create_autocmd("VimLeave", {
  group = exit_guard,
  callback = function()
    if orphaned() then
      os.exit(tonumber(vim.v.exiting) or 1)
    end
  end,
})
