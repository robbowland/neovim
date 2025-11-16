return {
  "mikavilpas/yazi.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "Yazi" },
  keys = {
    { "<leader>fe", "<cmd>Yazi<CR>", desc = "File Explorer" },
  },
  opts = function()
    local openers = require("yazi.openers")

    return {
      previewer = {
        width = 120,
      },
      open_file_function = function(chosen_file, _, state)
        local is_dir = vim.fn.isdirectory(chosen_file) == 1
        local last_dir = state and state.last_directory
        local last_dir_name = last_dir and last_dir.filename or nil

        if is_dir then
          if chosen_file == last_dir_name then
            -- quitting without selection still reports current dir, ignore it
            return
          end
          vim.fn.chdir(chosen_file)
        else
          openers.open_file(chosen_file)
        end
      end,
    }
  end,
}
