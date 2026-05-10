return {
  "rmagatti/goto-preview",
  dependencies = { "rmagatti/logger.nvim" },
  event = "BufEnter",
  config = function()
    local close_preview = function(win)
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end)
    end

    require("goto-preview").setup({
      width = math.min(120, math.floor(vim.o.columns * 0.85)),
      height = math.min(25, math.floor(vim.o.lines * 0.45)),
      border = "rounded",
      default_mappings = false,
      focus_on_open = true,
      dismiss_on_move = false,
      stack_floating_preview_windows = false,
      post_open_hook = function(buf, win)
        vim.wo[win].cursorline = true
        vim.wo[win].number = true
        vim.wo[win].relativenumber = false
        vim.wo[win].signcolumn = "no"
        vim.wo[win].wrap = false

        vim.keymap.set("n", "q", function()
          if vim.api.nvim_get_current_win() == win then
            close_preview(win)
            return ""
          end

          return "q"
        end, { buffer = buf, desc = "Close preview", expr = true, nowait = true, silent = true })

        vim.keymap.set("n", "<Esc>", function()
          if vim.api.nvim_get_current_win() == win then
            close_preview(win)
            return ""
          end

          return "<Esc>"
        end, { buffer = buf, desc = "Close preview", expr = true, nowait = true, silent = true })
      end,
    })
  end,
  keys = {
    {
      "gpd",
      function()
        require("goto-preview").goto_preview_definition({})
      end,
      desc = "Preview Definition",
    },
    {
      "gpt",
      function()
        require("goto-preview").goto_preview_type_definition({})
      end,
      desc = "Preview Type Definition",
    },
    {
      "gpi",
      function()
        require("goto-preview").goto_preview_implementation({})
      end,
      desc = "Preview Implementation",
    },
    {
      "gpD",
      function()
        require("goto-preview").goto_preview_declaration({})
      end,
      desc = "Preview Declaration",
    },
    {
      "gP",
      function()
        require("goto-preview").close_all_win({})
      end,
      desc = "Close All Previews",
    },
    {
      "gpr",
      function()
        require("goto-preview").goto_preview_references({})
      end,
      desc = "Preview References",
    },
  },
}
