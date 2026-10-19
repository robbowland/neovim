local marker =
  [[%{%v:virtnum == 0 && diff_hlID(v:lnum, 1) ? '%#' . w:micrographics_diffview_gutter_hl . '#▎%*' : ' '%}]]
local line_number = "%=%{v:virtnum == 0 ? (&rnu && v:relnum ? v:relnum : v:lnum) : ''} "
local statuscolumn = "%C" .. marker .. line_number
local foldtext =
  [["  " . (v:foldend - v:foldstart + 1) . " unchanged lines hidden · file lines " . v:foldstart . "–" . v:foldend . " · zO expand · zR expand all  "]]
local fold_fillchars = { fold = "─", foldclose = "▶", foldopen = "▼", foldsep = "│" }
local source_groups = { "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "DiffTextAdd" }
local mouse_scroll_keycodes = {
  [vim.api.nvim_replace_termcodes("<ScrollWheelDown>", true, false, true)] = true,
  [vim.api.nvim_replace_termcodes("<ScrollWheelUp>", true, false, true)] = true,
}
local mouse_scroll_namespace = vim.api.nvim_create_namespace("micrographics_diffview_mouse_scroll")
local large_diff_line_limit = 10000

local function place_newer_pane_on_left(view)
  local layout = view and view.cur_layout
  if not (layout and type(layout.windows) == "table" and #layout.windows == 2 and layout.a and layout.b) then
    return
  end

  local old_win = layout.a.id
  local new_win = layout.b.id
  if not old_win or not new_win or not vim.api.nvim_win_is_valid(old_win) or not vim.api.nvim_win_is_valid(new_win) then
    return
  end

  local old_position = vim.api.nvim_win_get_position(old_win)
  local new_position = vim.api.nvim_win_get_position(new_win)
  if old_position[1] ~= new_position[1] or old_position[2] >= new_position[2] then
    return
  end

  local old_winnr = vim.fn.win_id2win(old_win)
  if old_winnr == 0 then
    return
  end

  vim.api.nvim_win_call(new_win, function()
    vim.cmd(("%dwincmd x"):format(old_winnr))
  end)
end

local refresh_statusline = require("config.diffview").refresh_statusline
local popover = require("config.popover")

local function current_view()
  local lib = package.loaded["diffview.lib"]
  return lib and lib.get_current_view()
end

-- The widest panel line, so the popover shows every entry whole.
local function file_panel_content_width(view)
  local panel = view and view.panel
  if not (panel and panel.bufid and vim.api.nvim_buf_is_valid(panel.bufid)) then
    return 0
  end

  local width = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(panel.bufid, 0, -1, false)) do
    width = math.max(width, vim.fn.strdisplaywidth(line) + 2)
  end

  local root = panel.adapter and panel.adapter.ctx and panel.adapter.ctx.toplevel
  if root then
    width = math.max(width, vim.fn.strdisplaywidth(vim.fn.fnamemodify(root, ":~")) + 6)
  end

  return width
end

-- The file panel is a popover (config.popover) over the diff: hidden as a
-- view opens, shown by <leader>ft (or <leader>e), and closed by the same
-- keys, q, <esc>, picking a file, or anything else that leaves it.
local function file_panel_win_config()
  local width = popover.width(file_panel_content_width(current_view()))
  return vim.tbl_extend("force", { type = "float" }, popover.float(width))
end

local function close_file_panel(view)
  local panel = view and view.panel
  if panel and panel:is_open() then
    panel:close()
    refresh_statusline()
  end
end

local function configure_file_panel_popover(view)
  local panel = view and view.panel
  if not (panel and panel.on_autocmd) then
    return
  end

  panel:on_autocmd("WinEnter", {
    callback = function()
      refresh_statusline()
    end,
  })
  -- Scheduled: a file picked moves the cursor to the diff after leaving.
  panel:on_autocmd("WinLeave", {
    callback = function()
      vim.schedule(function()
        if not panel:is_focused() then
          close_file_panel(view)
        end
      end)
    end,
  })

  view.emitter:on("files_updated", function()
    refresh_statusline()
  end)
  view.emitter:on("file_open_post", function()
    refresh_statusline()
  end)
end

-- <leader>ft: show the popover and go there; from inside it, close it.
local function toggle_file_panel()
  local view = current_view()
  local panel = view and view.panel
  if not panel then
    return
  end

  if panel:is_focused() then
    close_file_panel(view)
  else
    panel:focus()
    refresh_statusline()
  end
end

local function hide_file_panel()
  close_file_panel(current_view())
end

popover.on_close_all(hide_file_panel)

local function hide_file_panel_on_open(view)
  vim.schedule(function()
    close_file_panel(view)
  end)
end

local function detach_lsp_clients(bufnr)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
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
  vim.wo[win].foldcolumn = "1"
  vim.wo[win].foldtext = foldtext
  vim.api.nvim_win_call(win, function()
    vim.opt_local.fillchars:append(fold_fillchars)
  end)

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
  local hidden = { FoldColumn = true, Folded = true }
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
  table.insert(mappings, "FoldColumn:MicrographicsDiffviewFoldColumn")
  table.insert(mappings, "Folded:MicrographicsDiffviewFold")
  vim.wo[win].winhighlight = table.concat(mappings, ",")
end

local function compatible_fold_action(actions, lhs)
  for _, mapping in ipairs(actions.compat.fold_cmds) do
    if mapping[2] == lhs then
      return mapping[3]
    end
  end

  error("Diffview fold action is unavailable: " .. lhs)
end

-- Neovim ignores scrollbind when the mouse wheel targets an inactive window,
-- so the wheel focuses a scroll-bound pane first.
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
      and vim.wo[win].scrollbind
    then
      pcall(vim.api.nvim_set_current_win, win)
    end
  end, mouse_scroll_namespace)
end

local function disable_mouse_scroll_sync()
  vim.on_key(nil, mouse_scroll_namespace)
end

-- Context headers differ in height between the panes, so their tops stop
-- lining up; each diff pane shows its context on one winbar line instead
-- (config.diffview.context_header). Diffview flags its buffers with ts_context_disable, which
-- treesitter-context reads (lua/plugins/treesitter-context.lua) only on
-- BufReadPost: ask again for files that were open before the view.
-- Diffview clears the flag on working-tree files when you switch files but
-- not when the view closes, so the files are remembered and cleared here.
local context_flagged_files = {}

local function recheck_treesitter_context(bufnr)
  if not vim.api.nvim_buf_get_name(bufnr):match("^diffview://") then
    context_flagged_files[bufnr] = true
  end
  pcall(vim.api.nvim_exec_autocmds, "BufReadPost", {
    buffer = bufnr,
    group = "treesitter_context_update",
    -- The modeline pass could :set a read-only diff buffer (E21).
    modeline = false,
  })
end

-- view_closed fires before the view leaves diffview.lib's list.
local function restore_treesitter_context()
  vim.schedule(function()
    if #require("diffview.lib").views > 0 then
      return
    end
    for bufnr in pairs(context_flagged_files) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.b[bufnr].ts_context_disable = nil
      end
    end
    context_flagged_files = {}

    local context = package.loaded["treesitter-context"]
    if context and context.enabled() then
      context.enable()
    end
  end)
end

-- The line of the first complete <<<<<<< … ======= … >>>>>>> region.
local function find_conflict_marker(path)
  local handle = io.open(path, "r")
  if not handle then
    return nil
  end

  -- nil outside a conflict; inside one, the half being read and its start.
  ---@type { half: "ours"|"theirs", start: integer }?
  local conflict
  local line_number = 0

  for line in handle:lines() do
    line_number = line_number + 1

    if line:match("^<<<<<<<") then
      conflict = { half = "ours", start = line_number }
    elseif conflict and conflict.half == "ours" and line:match("^=======\r?$") then
      conflict.half = "theirs"
    elseif conflict and conflict.half == "theirs" and line:match("^>>>>>>>") then
      handle:close()
      return conflict.start
    end
  end

  handle:close()
  return nil
end

local function file_is_under(file, dir)
  return file.path == dir.path or file.path:sub(1, #dir.path + 1) == dir.path .. "/"
end

-- The file lists staging adds from; staging a staged entry unstages it.
local stageable_kinds = { "working", "conflicting" }

-- A panel row is a file entry or a directory, which diffview-plus marks by
-- its collapsed state.
local function is_directory(item)
  return type(item.collapsed) == "boolean"
end

local function selected_stage_targets(view, item)
  if not (item and vim.tbl_contains(stageable_kinds, item.kind)) then
    return {}
  end

  if not is_directory(item) then
    return { item }
  end

  local targets = {}
  for _, file in ipairs(view.files[item.kind]) do
    if file_is_under(file, item) then
      targets[#targets + 1] = file
    end
  end

  return targets
end

local function all_stage_targets(view)
  local targets = {}
  for _, kind in ipairs(stageable_kinds) do
    vim.list_extend(targets, view.files[kind])
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

    confirm_stage_with_conflicts(view and all_stage_targets(view) or {}, actions.stage_all)
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

local function goto_file()
  require("config.diffview").goto_file()
end

return {
  -- The maintained fork of sindrets/diffview.nvim; it keeps the `diffview`
  -- module name. Tagged releases, since it moves quickly.
  "dlyongemallo/diffview-plus.nvim",
  version = "*",
  cmd = {
    "DiffviewClose",
    "DiffviewFileHistory",
    "DiffviewFocusFiles",
    "DiffviewOpen",
    "DiffviewRefresh",
    "DiffviewToggle",
    "DiffviewToggleFiles",
    "DiffviewWorktreeOverview",
  },
  init = function()
    vim.api.nvim_create_user_command("DiffviewPR", function()
      require("config.diffview").open_current_pr_diff()
    end, { desc = "Diff the current pull request layer" })
  end,
  opts = function()
    local actions = require("diffview.actions")
    local expand_all_folds = compatible_fold_action(actions, "zR")
    local collapse_all_folds = compatible_fold_action(actions, "zM")

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
      -- Delete the buffers a view opened when it closes; buffers that are
      -- modified or shown in another tab (gf) are kept.
      clean_up_buffers = true,
      -- Histogram aligns moved and refactored code better than Myers; only
      -- while a view is open.
      diffopt = { algorithm = "histogram" },
      -- Files marked reviewed (w) and hidden (H) survive restarts, per
      -- repository and revision.
      persist_selections = { enabled = true },
      hooks = {
        view_opened = function(view)
          place_newer_pane_on_left(view)
          configure_file_panel_popover(view)
          hide_file_panel_on_open(view)
        end,
        view_enter = function(view)
          place_newer_pane_on_left(view)
          enable_mouse_scroll_sync()
          refresh_statusline()
        end,
        view_leave = function()
          disable_mouse_scroll_sync()
          refresh_statusline()
        end,
        view_closed = function()
          restore_treesitter_context()
          refresh_statusline()
        end,
        view_post_layout = function(view)
          place_newer_pane_on_left(view)
        end,
        diff_buf_read = tune_diff_buffer,
        diff_buf_win_enter = function(bufnr, win, context)
          tune_diff_buffer(bufnr)
          tune_diff_window(bufnr, win)
          recheck_treesitter_context(bufnr)
          vim.wo[win].winbar = require("config.diffview").context_header_expr
          vim.w[win].micrographics_diffview_gutter_hl = gutter_highlight(context)
          hide_source_highlights(win)
          vim.wo[win].statuscolumn = statuscolumn
          if context.layout_name == "diff2_horizontal" and context.symbol == "b" then
            place_newer_pane_on_left(require("diffview.lib").get_current_view())
          end
        end,
      },
      file_panel = {
        win_config = file_panel_win_config,
      },
      -- Only the keys a review, staging and the odd merge use; diffview's
      -- other defaults (layouts, splits, tabs, commit logs, listing styles,
      -- whole-file conflict picks) are off. g? lists what is left.
      keymaps = {
        disable_defaults = true,
        view = vim.list_extend({
          { "n", "<tab>", actions.select_next_entry, { desc = "Next file" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous file" } },
          { "n", "<leader>ft", toggle_file_panel, { desc = "Files (show and go there)" } },
          { "n", "<leader>e", toggle_file_panel, { desc = "Files (show and go there)" } },
          { "n", "gf", goto_file, { desc = "Open the file in its worktree tab" } },
          { "n", "zR", expand_all_folds, { desc = "Expand all unchanged sections" } },
          { "n", "zM", collapse_all_folds, { desc = "Collapse all unchanged sections" } },
          -- zo, zc, za and the rest, in both panes at once.
        }, vim.deepcopy(actions.compat.fold_cmds)),
        diff2 = {
          { "n", "g?", actions.help({ "view", "diff2" }), { desc = "Keys" } },
        },
        -- Merges (three and four panes): from one conflict to the next, and
        -- which side wins.
        diff3 = {
          { "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
          { "n", "[x", actions.prev_conflict, { desc = "Previous conflict" } },
          { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Conflict: ours" } },
          { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Conflict: theirs" } },
          { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Conflict: base" } },
          { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Conflict: all of them" } },
          { "n", "dx", actions.conflict_choose("none"), { desc = "Conflict: none of them" } },
          { "n", "<leader>cw", write_merge_file, { desc = "Save the resolved merge file" } },
          { "n", "g?", actions.help({ "view", "diff3" }), { desc = "Keys" } },
        },
        diff4 = {
          { "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
          { "n", "[x", actions.prev_conflict, { desc = "Previous conflict" } },
          { "n", "<leader>co", actions.conflict_choose("ours"), { desc = "Conflict: ours" } },
          { "n", "<leader>ct", actions.conflict_choose("theirs"), { desc = "Conflict: theirs" } },
          { "n", "<leader>cb", actions.conflict_choose("base"), { desc = "Conflict: base" } },
          { "n", "<leader>ca", actions.conflict_choose("all"), { desc = "Conflict: all of them" } },
          { "n", "dx", actions.conflict_choose("none"), { desc = "Conflict: none of them" } },
          { "n", "<leader>cw", write_merge_file, { desc = "Save the resolved merge file" } },
          { "n", "g?", actions.help({ "view", "diff4" }), { desc = "Keys" } },
        },
        file_panel = {
          { "n", "j", actions.next_entry, { desc = "Down" } },
          { "n", "k", actions.prev_entry, { desc = "Up" } },
          { "n", "<down>", actions.next_entry, { desc = "Down" } },
          { "n", "<up>", actions.prev_entry, { desc = "Up" } },
          -- Into the diff, which closes the popover; a directory folds.
          { "n", "<cr>", actions.focus_entry, { desc = "Show this file's diff" } },
          { "n", "<LeftRelease>", actions.focus_entry, { desc = "Show this file's diff" } },
          { "n", "za", actions.toggle_fold, { desc = "Fold or unfold the directory" } },
          { "n", "<tab>", actions.select_next_entry, { desc = "Next file" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous file" } },
          { "n", "<leader>ft", toggle_file_panel, { desc = "Close" } },
          { "n", "<leader>e", toggle_file_panel, { desc = "Close" } },
          { "n", "q", hide_file_panel, { desc = "Close" } },
          { "n", "<esc>", hide_file_panel, { desc = "Close" } },
          { "n", "gf", goto_file, { desc = "Open the file in its worktree tab" } },
          { { "n", "x" }, "w", actions.toggle_select_entry, { desc = "Mark reviewed" } },
          { "n", "H", actions.toggle_hide_selected, { desc = "Hide or show the reviewed" } },
          { "n", "s", guarded_toggle_stage_entry(actions), { desc = "Stage / unstage" } },
          { "n", "S", guarded_stage_all(actions), { desc = "Stage all" } },
          { "n", "U", actions.unstage_all, { desc = "Unstage all" } },
          { "n", "X", actions.restore_entry, { desc = "Restore to the older state" } },
          { "n", "]x", actions.next_conflict, { desc = "Next conflict" } },
          { "n", "[x", actions.prev_conflict, { desc = "Previous conflict" } },
          { "n", "<leader>cw", write_merge_file, { desc = "Save the resolved merge file" } },
          { "n", "g?", actions.help("file_panel"), { desc = "Keys" } },
        },
        file_history_panel = {
          { "n", "j", actions.next_entry, { desc = "Down" } },
          { "n", "k", actions.prev_entry, { desc = "Up" } },
          { "n", "<down>", actions.next_entry, { desc = "Down" } },
          { "n", "<up>", actions.prev_entry, { desc = "Up" } },
          { "n", "<cr>", actions.select_entry, { desc = "Show this commit's diff" } },
          { "n", "<LeftRelease>", actions.select_entry, { desc = "Show this commit's diff" } },
          { "n", "za", actions.toggle_fold, { desc = "Fold or unfold" } },
          { "n", "<tab>", actions.select_next_entry, { desc = "Next" } },
          { "n", "<s-tab>", actions.select_prev_entry, { desc = "Previous" } },
          { "n", "gf", goto_file, { desc = "Open the file in its worktree tab" } },
          { "n", "y", actions.copy_hash, { desc = "Copy the commit hash" } },
          { "n", "g?", actions.help("file_history_panel"), { desc = "Keys" } },
        },
        help_panel = {
          { "n", "q", actions.close, { desc = "Close" } },
          { "n", "<esc>", actions.close, { desc = "Close" } },
        },
        worktree_overview = {
          { "n", "j", actions.next_entry, { desc = "Down" } },
          { "n", "k", actions.prev_entry, { desc = "Up" } },
          { "n", "<cr>", actions.worktree_overview_enter, { desc = "Open its diff" } },
          { "n", "<LeftRelease>", actions.worktree_overview_enter, { desc = "Open its diff" } },
          { "n", "g?", actions.help("worktree_overview"), { desc = "Keys" } },
        },
      },
    }
  end,
  keys = {
    {
      "<leader>gd",
      function()
        require("config.diffview").open_working_tree()
      end,
      desc = "Git Diff (Working Tree)",
    },
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
    {
      "<leader>gq",
      function()
        require("config.diffview").close()
      end,
      desc = "Close Diffview",
    },
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
