local colors = require("config.colors")
local picker = require("config.snacks.picker")

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
    opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
      layout = { layout = { position = "right" } },
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
