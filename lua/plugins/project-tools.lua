local project_tools = require("config.project-tools")

local prettier_filetypes = {
  css = true,
  graphql = true,
  handlebars = true,
  html = true,
  javascript = true,
  javascriptreact = true,
  json = true,
  jsonc = true,
  less = true,
  markdown = true,
  ["markdown.mdx"] = true,
  scss = true,
  typescript = true,
  typescriptreact = true,
  vue = true,
  yaml = true,
}

local function run(command, cwd)
  local ok, result = pcall(function()
    return vim.system(command, { cwd = cwd, text = true }):wait()
  end)
  return ok and result or nil
end

local function prettier_context(command, ctx)
  local config_result = run({ command, "--find-config-path", ctx.filename }, ctx.dirname)
  if config_result == nil or config_result.code ~= 0 then
    return nil
  end

  local config_path = vim.trim(config_result.stdout or "")
  if config_path == "" then
    return nil
  end
  if not vim.startswith(config_path, "/") then
    config_path = vim.fs.joinpath(ctx.dirname, config_path)
  end

  local cwd = vim.fs.dirname(vim.fs.normalize(config_path))
  local info_result = run({ command, "--file-info", ctx.filename }, cwd)
  if info_result == nil or info_result.code ~= 0 then
    return nil
  end

  local ok, info = pcall(vim.json.decode, info_result.stdout)
  if
    not ok
    or type(info) ~= "table"
    or info.ignored
    or info.inferredParser == nil
    or info.inferredParser == vim.NIL
  then
    return nil
  end

  return cwd
end

local function configure_prettier_buffer(args)
  if not prettier_filetypes[vim.bo[args.buf].filetype] then
    return
  end

  local filename = vim.api.nvim_buf_get_name(args.buf)
  if filename == "" then
    return
  end

  local command = project_tools.node_executable(filename, "prettier") or "prettier"
  if prettier_context(command, { filename = filename, dirname = vim.fs.dirname(filename) }) == nil then
    vim.b[args.buf].autoformat = false
  end
end

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "actionlint" } },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.yaml = opts.linters_by_ft.yaml or {}
      if not vim.tbl_contains(opts.linters_by_ft.yaml, "actionlint") then
        table.insert(opts.linters_by_ft.yaml, "actionlint")
      end

      opts.linters = opts.linters or {}
      opts.linters.actionlint = vim.tbl_deep_extend("force", opts.linters.actionlint or {}, {
        condition = function(ctx)
          return vim.fs.normalize(ctx.filename):match("/%.github/workflows/.*%.ya?ml$") ~= nil
        end,
      })
      opts.linters.terraform_validate = vim.tbl_deep_extend("force", opts.linters.terraform_validate or {}, {
        condition = function()
          return vim.fn.executable("terraform") == 1
        end,
      })
    end,
  },
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local has_terraform = vim.fn.executable("terraform") == 1
      opts.sources = vim.tbl_filter(function(source)
        if source.name == "prettier" then
          return false
        end
        if not has_terraform and (source.name == "terraform_fmt" or source.name == "terraform_validate") then
          return false
        end
        return true
      end, opts.sources or {})
    end,
  },
  {
    "stevearc/conform.nvim",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ProjectPrettier", { clear = true }),
        callback = configure_prettier_buffer,
      })
    end,
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}
      opts.formatters.prettier = vim.tbl_deep_extend("force", opts.formatters.prettier or {}, {
        command = function(_, ctx)
          return project_tools.node_executable(ctx.filename, "prettier") or "prettier"
        end,
        condition = function(_, ctx)
          local command = project_tools.node_executable(ctx.filename, "prettier") or "prettier"
          return prettier_context(command, ctx) ~= nil
        end,
      })
    end,
  },
}
