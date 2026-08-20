local M = {}

local palettes = require("micrographics.palette")
local highlight_groups = require("micrographics.groups")

local function current_options()
  return {
    punctuation = vim.g.micrographics_punctuation == "ink" and "ink" or "faint",
  }
end

local function set_terminal_palette(p)
  local colors = {
    p.paper,
    p.danger,
    p.success,
    p.metadata,
    p.metadata,
    p.metadata,
    p.metadata,
    p.metadata,
    p.faint,
    p.danger,
    p.success,
    p.ink,
    p.ink,
    p.ink,
    p.ink,
    p.ink,
  }

  for index, color in ipairs(colors) do
    vim.g["terminal_color_" .. (index - 1)] = color
  end
end

local function apply()
  if vim.g.colors_name ~= "micrographics" then
    return
  end

  local palette = palettes.get(vim.o.background)
  vim.g.micrographics_palette = palette

  for name, value in pairs(highlight_groups.build(palette, current_options())) do
    vim.api.nvim_set_hl(0, name, value)
  end

  highlight_groups.apply_dynamic(palette)
  set_terminal_palette(palette)
end

function M.load()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.g.colors_name = "micrographics"
  apply()

  vim.api.nvim_create_user_command("MicrographicsPunctuation", function(command)
    local value = command.args
    if value == "" or value == "toggle" then
      value = current_options().punctuation == "faint" and "ink" or "faint"
    end
    if value ~= "ink" and value ~= "faint" then
      vim.notify("Micrographics punctuation must be 'ink', 'faint', or 'toggle'", vim.log.levels.ERROR)
      return
    end

    vim.g.micrographics_punctuation = value
    apply()
  end, {
    nargs = "?",
    complete = function()
      return { "ink", "faint", "toggle" }
    end,
    desc = "Set or toggle Micrographics punctuation contrast",
    force = true,
  })

  local group = vim.api.nvim_create_augroup("MicrographicsTheme", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "LazyLoad", "VeryLazy" },
    callback = function()
      vim.schedule(apply)
    end,
  })

  -- Config callbacks attached to ColorScheme run after the colorscheme file.
  -- Reapply once on the next loop so the selected theme remains authoritative.
  vim.schedule(apply)
end

function M.palette(background)
  return palettes.get(background or vim.o.background)
end

function M.options()
  return current_options()
end

function M.groups(background, options)
  return highlight_groups.build(M.palette(background), options or current_options())
end

return M
