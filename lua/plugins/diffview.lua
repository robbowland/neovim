local marker =
  [[%{%v:virtnum == 0 && diff_hlID(v:lnum, 1) ? '%#' . w:micrographics_diffview_gutter_hl . '#▎%*' : ' '%}]]
local line_number = "%=%{v:virtnum == 0 ? (&rnu && v:relnum ? v:relnum : v:lnum) : ''} "
local statuscolumn = "%C" .. marker .. line_number
local source_groups = { "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "DiffTextAdd" }
local mouse_scroll_keycodes = {
  [vim.api.nvim_replace_termcodes("<ScrollWheelDown>", true, false, true)] = true,
  [vim.api.nvim_replace_termcodes("<ScrollWheelUp>", true, false, true)] = true,
}
local mouse_scroll_namespace = vim.api.nvim_create_namespace("micrographics_diffview_mouse_scroll")
local large_diff_line_limit = 10000

local function diffview_lsp_clients(bufnr)
  if vim.lsp.get_clients then
    return vim.lsp.get_clients({ bufnr = bufnr })
  end

  return vim.lsp.get_active_clients({ bufnr = bufnr })
end

local function detach_lsp_clients(bufnr)
  for _, client in ipairs(diffview_lsp_clients(bufnr)) do
    pcall(vim.lsp.buf_detach_client, bufnr, client.id)
  end
end

local function tune_diff_buffer(bufnr)
  if vim.api.nvim_buf_line_count(bufnr) < large_diff_line_limit then
    return
  end

  vim.b[bufnr].diffview_large_buffer = true
  vim.b[bufnr].completion = false

  pcall(vim.diagnostic.enable, false, { bufnr = bufnr })
  pcall(vim.treesitter.stop, bufnr)
  detach_lsp_clients(bufnr)
end

local function tune_diff_window(bufnr, win)
  vim.wo[win].wrap = false
  vim.wo[win].list = false
  vim.wo[win].colorcolumn = "80"

  if vim.b[bufnr].diffview_large_buffer then
    vim.wo[win].foldmethod = "manual"
  end
end

local function gutter_highlight(context)
  if context.layout_name:match("^diff2") then
    return context.symbol == "a" and "Removed" or context.symbol == "b" and "Added" or "Changed"
  end
  return "Changed"
end

local function hide_source_highlights(win)
  local hidden = {}
  for _, group in ipairs(source_groups) do
    hidden[group] = true
  end

  local mappings = {}
  for _, mapping in ipairs(vim.split(vim.wo[win].winhighlight, ",", { plain = true, trimempty = true })) do
    if not hidden[mapping:match("^[^:]+") or ""] then
      table.insert(mappings, mapping)
    end
  end
  for _, group in ipairs(source_groups) do
    table.insert(mappings, group .. ":MicrographicsDiffviewSource")
  end
  vim.wo[win].winhighlight = table.concat(mappings, ",")
end

-- Neovim ignores scrollbind when the mouse wheel targets an inactive window.
local function enable_mouse_scroll_sync()
  vim.on_key(function(key, typed)
    local input = typed ~= "" and typed or key
    if not mouse_scroll_keycodes[input] then
      return
    end

    local win = vim.fn.getmousepos().winid
    if
      win > 0
      and vim.api.nvim_win_is_valid(win)
      and win ~= vim.api.nvim_get_current_win()
      and vim.w[win].micrographics_diffview_gutter_hl
    then
      pcall(vim.api.nvim_set_current_win, win)
    end
  end, mouse_scroll_namespace)
end

local function disable_mouse_scroll_sync()
  vim.on_key(nil, mouse_scroll_namespace)
end

local function find_conflict_marker(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil
  end

  local start_line
  local has_separator = false
  local line_number = 0

  for line in handle:lines() do
    line_number = line_number + 1

    if line:match("^<<<<<<<") then
      start_line = line_number
      has_separator = false
    elseif start_line and line:match("^=======$") then
      has_separator = true
    elseif start_line and has_separator and line:match("^>>>>>>>") then
      handle:close()
      return start_line
    end
  end

  handle:close()
  return nil
end

local function file_is_under(file, dir)
  return file.path == dir.path or file.path:sub(1, #dir.path + 1) == dir.path .. "/"
end

local function selected_stage_targets(view, item)
  if not item or item.kind == "staged" then
    return {}
  end

  if item.kind ~= "working" and item.kind ~= "conflicting" then
    return {}
  end

  if type(item.collapsed) ~= "boolean" then
    return { item }
  end

  local source = item.kind == "conflicting" and view.files.conflicting or view.files.working
  local targets = {}

  for _, file in ipairs(source) do
    if file_is_under(file, item) then
      targets[#targets + 1] = file
    end
  end

  return targets
end

local function conflict_files(files)
  local conflicts = {}

  for _, file in ipairs(files) do
    local line = find_conflict_marker(file.absolute_path)
    if line then
      conflicts[#conflicts + 1] = { path = file.path, line = line }
    end
  end

  return conflicts
end

local function format_conflict_warning(conflicts)
  local lines = {
    "Conflict markers were found in the files you are about to stage:",
    "",
  }

  for index, conflict in ipairs(conflicts) do
    if index > 5 then
      lines[#lines + 1] = ("...and %d more"):format(#conflicts - 5)
      break
    end

    lines[#lines + 1] = ("- %s:%d"):format(conflict.path, conflict.line)
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Stage anyway?"

  return table.concat(lines, "\n")
end

local function confirm_stage_with_conflicts(files, stage)
  local conflicts = conflict_files(files)
  if #conflicts == 0 then
    stage()
    return
  end

  local choice = vim.fn.confirm(format_conflict_warning(conflicts), "&Cancel\n&Stage anyway", 1, "Warning")
  if choice == 2 then
    stage()
  else
    vim.notify("Staging cancelled: conflict markers found", vim.log.levels.WARN)
  end
end

local function guarded_toggle_stage_entry(actions)
  return function()
    local view = require("diffview.lib").get_current_view()
    local item = view and view:infer_cur_file(true)

    confirm_stage_with_conflicts(selected_stage_targets(view, item), actions.toggle_stage_entry)
  end
end

local function guarded_stage_all(actions)
  return function()
    local view = require("diffview.lib").get_current_view()
    local targets = {}

    if view then
      for _, file in ipairs(view.files.working) do
        targets[#targets + 1] = file
      end
      for _, file in ipairs(view.files.conflicting) do
        targets[#targets + 1] = file
      end
    end

    confirm_stage_with_conflicts(targets, actions.stage_all)
  end
end

local function write_merge_file()
  local view = require("diffview.lib").get_current_view()
  local layout = view and view.cur_layout
  local main = layout and layout.get_main_win and layout:get_main_win()
  local file = main and main.file
  local bufnr = file and file.bufnr

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("No Diffview merge file to save", vim.log.levels.WARN)
    return
  end

  if not vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
    vim.notify("Resolved merge file already saved", vim.log.levels.INFO)
    return
  end

  vim.api.nvim_buf_call(bufnr, function()
    local ok, err = pcall(vim.cmd, "silent write")
    if not ok then
      vim.notify("Failed to save resolved merge file: " .. err, vim.log.levels.ERROR)
    else
      vim.notify("Saved resolved merge file", vim.log.levels.INFO)
    end
  end)
end

return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewOpen",
    "DiffviewRefresh",
    "DiffviewToggleFiles",
  },
  init = function()
    vim.api.nvim_create_user_command("DiffviewPR", function()
      require("config.diffview").open_current_pr_diff()
    end, { desc = "Diff the current pull request layer" })
  end,
  opts = function()
    local actions = require("diffview.actions")

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("diffview_large_buffer_lsp", { clear = true }),
      callback = function(event)
        if not vim.b[event.buf].diffview_large_buffer then
          return
        end

        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(event.buf) then
            pcall(vim.lsp.buf_detach_client, event.buf, event.data.client_id)
          end
        end)
      end,
    })

    return {
      hooks = {
        view_enter = enable_mouse_scroll_sync,
        view_leave = disable_mouse_scroll_sync,
        diff_buf_read = tune_diff_buffer,
        diff_buf_win_enter = function(bufnr, win, context)
          tune_diff_buffer(bufnr)
          tune_diff_window(bufnr, win)
          vim.w[win].micrographics_diffview_gutter_hl = gutter_highlight(context)
          hide_source_highlights(win)
          vim.wo[win].statuscolumn = statuscolumn
        end,
      },
      file_panel = {
        win_config = { position = "right" },
      },
      keymaps = {
        view = {
          { "n", "<leader>cw", write_merge_file, { desc = "Save resolved merge file" } },
        },
        file_panel = {
          { "n", "-", guarded_toggle_stage_entry(actions), { desc = "Stage / unstage the selected entry" } },
          { "n", "s", guarded_toggle_stage_entry(actions), { desc = "Stage / unstage the selected entry" } },
          { "n", "S", guarded_stage_all(actions), { desc = "Stage all entries" } },
          { "n", "<leader>cw", write_merge_file, { desc = "Save resolved merge file" } },
        },
      },
    }
  end,
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git Diff (Working Tree)" },
    {
      "<leader>gD",
      function()
        require("config.diffview").open_all_changes()
      end,
      desc = "Git Diff (Full Branch)",
    },
    {
      "<leader>gA",
      function()
        require("config.diffview").open_all_changes_history()
      end,
      desc = "Git Diff (Full Branch by Commit)",
    },
    {
      "<leader>gV",
      function()
        require("config.diffview").open_current_pr_diff()
      end,
      desc = "Git Diff (Current PR Layer)",
    },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    {
      "<leader>gF",
      "<cmd>DiffviewFileHistory --base=LOCAL %<cr>",
      desc = "Git Current File History (Diffview)",
    },
    {
      "<leader>gR",
      "<cmd>DiffviewFileHistory --follow --base=LOCAL %<cr>",
      desc = "Git Current File History (Follow Renames)",
    },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git History (Diffview)" },
    { "<leader>gm", "<cmd>DiffviewOpen HEAD~1<cr>", desc = "Git Diff (Last Commit to Working Tree)" },
    { "<leader>gM", "<cmd>DiffviewOpen HEAD~1..HEAD<cr>", desc = "Git Diff (Last Commit)" },
  },
}
