local colors = require("config.colors")
local picker = require("config.snacks.picker")
local popover = require("config.popover")

return {
  "folke/snacks.nvim",
  keys = function(_, keys)
    local filtered = {}
    for _, key in ipairs(keys or {}) do
      local lhs = key[1]
      local desc = type(key.desc) == "string" and key.desc:lower() or ""
      if lhs ~= "<leader>gd" and lhs ~= "<leader>gD" and not desc:find("github", 1, true) then
        table.insert(filtered, key)
      end
    end
    table.insert(filtered, {
      "<leader>e",
      function()
        Snacks.explorer({ cwd = LazyVim.root() })
      end,
      desc = "File Tree (Root Dir)",
    })
    return filtered
  end,
  opts = function(_, opts)
    opts.gh = opts.gh or {}
    opts.gh.enabled = false
    opts.explorer = opts.explorer or {}
    opts.picker = opts.picker or {}
    opts.picker.sources = opts.picker.sources or {}
    -- The file tree is a popover (config.popover): picking a file, or
    -- leaving it, closes it.
    opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
      auto_close = true,
      jump = { close = true },
      layout = popover.snacks_layout,
    })
    popover.on_close_all(function()
      for _, explorer in ipairs(Snacks.picker.get({ source = "explorer" })) do
        explorer:close()
      end
    end)
    -- The explorer ignores floats it loses focus to, so another picker opened
    -- from it would stack on top; close it instead. A select (the explorer's
    -- own confirmations) keeps it.
    vim.api.nvim_create_autocmd("WinEnter", {
      group = vim.api.nvim_create_augroup("popover_pickers", { clear = true }),
      callback = function()
        local win = vim.api.nvim_get_current_win()
        for _, other in ipairs(Snacks.picker.get()) do
          local source = other.opts.source
          if
            source ~= "explorer"
            and source ~= "select"
            and (win == other.input.win.win or win == other.list.win.win)
          then
            popover.close_all()
            return
          end
        end
      end,
    })

    picker.setup(opts, colors)

    local function set_ui_highlights()
      -- Dim indent guides so they stay subtle against the background.
      vim.api.nvim_set_hl(0, "SnacksIndent", { fg = colors.surface_2 })
      vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = colors.gray_dim })

      local dim_line_nr = { fg = colors.gray_dim }
      for _, group in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow" }) do
        vim.api.nvim_set_hl(0, group, dim_line_nr)
      end
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = colors.gray })
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_ui_highlights,
    })
    set_ui_highlights()
  end,
}
