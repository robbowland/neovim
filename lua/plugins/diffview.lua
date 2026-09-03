local marker =
  [[%{%v:virtnum == 0 && diff_hlID(v:lnum, 1) ? '%#' . w:micrographics_diffview_gutter_hl . '#▎%*' : ' '%}]]
local line_number = "%=%{v:virtnum == 0 ? (&rnu && v:relnum ? v:relnum : v:lnum) : ''} "
local statuscolumn = "%C" .. marker .. line_number
local source_groups = { "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "DiffTextAdd" }

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
  opts = {
    hooks = {
      diff_buf_win_enter = function(_, win, context)
        vim.w[win].micrographics_diffview_gutter_hl = gutter_highlight(context)
        hide_source_highlights(win)
        vim.wo[win].statuscolumn = statuscolumn
      end,
    },
    file_panel = {
      win_config = { position = "right" },
    },
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen HEAD<cr>", desc = "Git Diff (Working Tree)" },
    {
      "<leader>gD",
      "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>",
      desc = "Git Diff (Full Branch)",
    },
    { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
    { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "Git Current File History (Diffview)" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git History (Diffview)" },
  },
}
