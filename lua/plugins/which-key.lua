return {
  "folke/which-key.nvim",
  opts = function(_, opts)
    local extras = require("which-key.extras")
    local icons = {
      files = { icon = "󰈞", color = "cyan" },
      search = { icon = "󰍉", color = "green" },
      git = { icon = "󰊢", color = "red" },
      code = { icon = "󰘧", color = "orange" },
      debug = { icon = "󰃤", color = "red" },
      tests = { icon = "󰙨", color = "green" },
      toggles = { icon = "󰨚", color = "yellow" },
      goto = { icon = "󰁔", color = "azure" },
      windows = { icon = "󱡴", color = "blue" },
      buffers = { icon = "󰈙", color = "cyan" },
      session = { icon = "󰷈", color = "azure" },
      diagnostics = { icon = "󰒡", color = "yellow" },
      workspace = { icon = "󰙅", color = "purple" },
      profiler = { icon = "󰔟", color = "orange" },
      folds = { icon = "󰄼", color = "blue" },
      fold_open = { icon = "▸", color = "green" },
      fold_close = { icon = "◂", color = "yellow" },
      split_h = { icon = "󱂬", color = "blue" },
      split_v = { icon = "󱂬", color = "blue" },
      close = { icon = "󰅖", color = "red", sort = "󿿿close" },
      maximize = { icon = "󰊓", color = "azure" },
      equalize = { icon = "󰽙", color = "azure" },
      tab = { icon = "󰓩", color = "purple" },
      swap = { icon = "󰚽", color = "orange" },
      focus = { icon = "󰆾", color = "blue" },
      focus_left = { icon = "󰦨", color = "blue" },
      focus_down = { icon = "󰦧", color = "blue" },
      focus_up = { icon = "󰦪", color = "blue" },
      focus_right = { icon = "󰦫", color = "blue" },
      focus_cycle = { icon = "󰒅", color = "purple" },
      resize = { icon = "󰑪", color = "cyan" },
      resize_width_dec = { icon = "󰞄", color = "azure" },
      resize_width_inc = { icon = "󰞃", color = "azure" },
      resize_height_dec = { icon = "󰞂", color = "azure" },
      resize_height_inc = { icon = "󰞁", color = "azure" },
      select_window = { icon = "󱂬", color = "purple" },
      inspect = { icon = "󰋺", color = "yellow" },
      lazy = { icon = "󰒲", color = "purple" },
      changelog = { icon = "󰋼", color = "yellow" },
      keyword = { icon = "󰜘", color = "orange" },
      terminal = { icon = "󰆍", color = "red" },
      surround = { icon = "󰆌", color = "purple" },
      surround_add = { icon = "󰐖", color = "green" },
      surround_delete = { icon = "󰆴", color = "red" },
      surround_find = { icon = "󰍉", color = "azure" },
      surround_find_left = { icon = "󰍊", color = "azure" },
      surround_highlight = { icon = "󰌁", color = "yellow" },
      surround_replace = { icon = "󰬺", color = "orange" },
      surround_update = { icon = "󱄄", color = "purple" },
    }

    local function icon(name)
      return icons[name] and vim.deepcopy(icons[name]) or nil
    end

    local group_icon_names = {
      ["Files"] = "files",
      ["Search"] = "search",
      ["Git"] = "git",
      ["Code & LSP"] = "code",
      ["Debug"] = "debug",
      ["Tests"] = "tests",
      ["Toggles"] = "toggles",
      ["Windows"] = "windows",
      ["Buffers"] = "buffers",
      ["Session"] = "session",
      ["Diagnostics"] = "diagnostics",
      ["Workspace"] = "workspace",
      ["Profiler"] = "profiler",
      ["Folds"] = "folds",
      ["Select Window"] = "select_window",
      ["Focus"] = "focus",
      ["Resize"] = "resize",
      ["goto"] = "goto",
      ["Surround"] = "surround",
    }

    local function apply_group_icons(node)
      if type(node) ~= "table" then
        return
      end

      local group_name = node.group
      local icon_name = group_icon_names[group_name]
      if icon_name and node.icon == nil then
        node.icon = icon(icon_name)
      elseif type(node.icon) == "string" then
        node.icon = { icon = node.icon }
      end

      for _, child in ipairs(node) do
        apply_group_icons(child)
      end
    end

    local function icon_value(item)
      local value = item.icon
      if type(value) == "table" then
        return value.sort or value.icon or ""
      end
      return value or ""
    end

    local function redirects_last(item)
      local mapping = item.mapping
      if item.group then
        return 2
      end
      if mapping and (mapping.proxy or mapping.expand) then
        return 1
      end
      return 0
    end

    opts.plugins = opts.plugins or {}
    opts.plugins.marks = false
    opts.plugins.registers = false

    opts.layout = vim.tbl_extend("force", opts.layout or {}, {
      width = { min = 24, max = 36 },
      spacing = 2,
    })

    opts.win = vim.tbl_extend("force", opts.win or {}, {
      padding = { 1, 2 },
      title = false,
    })

    if opts.icons ~= false then
      opts.icons = opts.icons or {}
      if opts.icons.rules ~= false then
        opts.icons.rules = opts.icons.rules or {}
        vim.list_extend(opts.icons.rules, {
          { pattern = "Zoom", icon = "󰆦", color = "purple" },
          { pattern = "Zen", icon = "󱅻 ", color = "cyan" },
          { pattern = "Inspect", icon = icons.inspect.icon, color = icons.inspect.color },
          { pattern = "Window", icon = icons.windows.icon, color = icons.windows.color },
          { pattern = "goto ", icon = icons.goto.icon, color = icons.goto.color },
          { pattern = "open fold", icon = icons.fold_open.icon, color = icons.fold_open.color },
          { pattern = "open all folds", icon = icons.fold_open.icon, color = icons.fold_open.color },
          { pattern = "close fold", icon = icons.fold_close.icon, color = icons.fold_close.color },
          { pattern = "close all folds", icon = icons.fold_close.icon, color = icons.fold_close.color },
        })
      end
    end

    opts.sort = { redirects_last, icon_value, "group", "manual", "alphanum", "mod" }

    opts.spec = opts.spec or {}
    vim.list_extend(opts.spec, {
      {
        mode = { "n", "v" },
        { "<leader>f", group = "Files" },
        { "<leader>s", group = "Search" },
        { "<leader>g", group = "Git" },
        { "<leader>c", group = "Code & LSP" },
        { "<leader>d", group = "Debug" },
        { "<leader>t", group = "Tests" },
        { "<leader>u", group = "Toggles" },
        { "<leader>w", group = "Windows" },
        { "<leader>b", group = "Buffers" },
        { "<leader>q", group = "Session" },
        { "<leader>x", group = "Diagnostics" },
        { "<leader><tab>", group = "Workspace" },
        { "<leader>dp", group = "Profiler" },
        { "g", group = "goto" },
      },
      { "<leader>-", hidden = true, mode = "n" },
      { "<leader>|", hidden = true, mode = "n" },
      { "<leader>`", hidden = true, mode = "n" },
      { "<leader>l", hidden = true, mode = "n" },
      { "<leader>L", hidden = true, mode = "n" },
      { "<leader>K", hidden = true, mode = "n" },
      { "<leader>ft", hidden = true, mode = "n" },
      { "<leader>fT", hidden = true, mode = "n" },
      { "<leader>wd", hidden = true, mode = "n" },
      {
        mode = "n",
        {
          "<c-w>",
          group = "Windows",
          expand = function()
            local items = {
              { "<c-w>s", desc = "Split Below", icon = icon("split_h") },
              { "<c-w>v", desc = "Split Right", icon = icon("split_v") },
              { "<c-w>q", desc = "Close Window", icon = icon("close") },
              { "<c-w>o", desc = "Maximize", icon = icon("maximize") },
              { "<c-w>=", desc = "Equalize", icon = icon("equalize") },
              { "<c-w>T", desc = "Move to Tab", icon = icon("tab") },
              { "<c-w>x", desc = "Swap With Next", icon = icon("swap") },
              {
                "<c-w>",
                group = "Focus",
                icon = icon("focus"),
                { "<c-w>h", desc = "Focus Left", icon = icon("focus_left") },
                { "<c-w>j", desc = "Focus Down", icon = icon("focus_down") },
                { "<c-w>k", desc = "Focus Up", icon = icon("focus_up") },
                { "<c-w>l", desc = "Focus Right", icon = icon("focus_right") },
                { "<c-w>w", desc = "Cycle Next", icon = icon("focus_cycle") },
              },
              {
                "<c-w>",
                group = "Resize",
                icon = icon("resize"),
                { "<c-w><", desc = "Shrink Width", icon = icon("resize_width_dec") },
                { "<c-w>>", desc = "Grow Width", icon = icon("resize_width_inc") },
                { "<c-w>-", desc = "Shrink Height", icon = icon("resize_height_dec") },
                { "<c-w>+", desc = "Grow Height", icon = icon("resize_height_inc") },
              },
            }

            if #extras.expand.win() > 0 then
              items[#items + 1] = {
                "<c-w>",
                group = "Select Window",
                icon = icon("select_window"),
                expand = function()
                  local win_items = extras.expand.win()
                  for _, spec in ipairs(win_items) do
                    spec.icon = spec.icon or icon("select_window")
                  end
                  return win_items
                end,
              }
            end
            return items
          end,
        },
      },
      {
        mode = { "n", "v" },
        {
          "gs",
          group = "Surround",
          icon = icon("surround"),
        },
      },
      {
        mode = { "n", "x" },
        {
          "gsa",
          icon = icon("surround_add"),
        },
      },
      {
        mode = "n",
        {
          "gsd",
          icon = icon("surround_delete"),
        },
        {
          "gsf",
          icon = icon("surround_find"),
        },
        {
          "gsF",
          icon = icon("surround_find_left"),
        },
        {
          "gsh",
          icon = icon("surround_highlight"),
        },
        {
          "gsr",
          icon = icon("surround_replace"),
        },
        {
          "gsn",
          icon = icon("surround_update"),
        },
      },
      { "z", group = "Folds", mode = { "n", "v" } },
      {
        mode = "n",
        {
          "<leader>wh",
          icon = icon("split_h"),
        },
        {
          "<leader>wv",
          icon = icon("split_v"),
        },
        {
          "<leader>ck",
          icon = icon("keyword"),
        },
        {
          "<leader>ul",
          icon = icon("lazy"),
        },
        {
          "<leader>uL",
          icon = icon("changelog"),
        },
        {
          "<leader>wt",
          icon = icon("terminal"),
        },
        {
          "<leader>wT",
          icon = icon("terminal"),
        },
        {
          "<leader>wx",
          icon = icon("close"),
        },
      },
      {
        mode = "n",
        {
          "<leader>ui",
          icon = icon("inspect"),
        },
      },
      {
        mode = "n",
        {
          "<c-w>s",
          icon = icon("split_h"),
        },
        {
          "<c-w>v",
          icon = icon("split_v"),
        },
        {
          "<c-w>q",
          icon = icon("close"),
        },
        {
          "<c-w>o",
          icon = icon("maximize"),
        },
        {
          "<c-w>=",
          icon = icon("equalize"),
        },
        {
          "<c-w>T",
          icon = icon("tab"),
        },
        {
          "<c-w>x",
          icon = icon("swap"),
        },
        {
          "<c-w>h",
          icon = icon("focus_left"),
        },
        {
          "<c-w>j",
          icon = icon("focus_down"),
        },
        {
          "<c-w>k",
          icon = icon("focus_up"),
        },
        {
          "<c-w>l",
          icon = icon("focus_right"),
        },
        {
          "<c-w>w",
          icon = icon("focus_cycle"),
        },
        {
          "<c-w><",
          icon = icon("resize_width_dec"),
        },
        {
          "<c-w>>",
          icon = icon("resize_width_inc"),
        },
        {
          "<c-w>-",
          icon = icon("resize_height_dec"),
        },
        {
          "<c-w>+",
          icon = icon("resize_height_inc"),
        },
      },
    })

    for _, spec in ipairs(opts.spec) do
      apply_group_icons(spec)
    end
  end,
}
