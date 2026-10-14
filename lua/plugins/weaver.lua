-- weaver's Neovim modules, when weaver is installed: the Git diff mappings
-- use its one-view review (weaver.diffview), and the status line shows the
-- agent in nvims weaver opens. Without weaver, both fall back to plain
-- Diffview behaviour.
local data = vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")
local dir = vim.env.WEAVER_NVIM_DIR or (data .. "/weaver/nvim")

return {
  dir = dir,
  name = "weaver",
  -- On the runtimepath from the start (it runs nothing until a mapping
  -- requires it), so :checkhealth weaver finds it too.
  lazy = false,
  cond = vim.uv.fs_stat(dir .. "/lua/weaver/diffview.lua") ~= nil,
}
