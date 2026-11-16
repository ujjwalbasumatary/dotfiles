vim.opt.completeopt = { "menu", "menuone", "noselect", "popup" }

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  virtual_text = false,
  virtual_lines = false,
  signs = true,
  underline = true,
  float = { border = "single", source = "if_many" },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspSetup", { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    -- Pyright supplies Python documentation; Ruff supplies lint/code actions.
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    local provider = client.server_capabilities.completionProvider
    if provider then
      -- Native completion on identifiers as well as server-provided punctuation.
      local triggers = provider.triggerCharacters or {}
      for character in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):gmatch(".") do
        if not vim.tbl_contains(triggers, character) then
          triggers[#triggers + 1] = character
        end
      end
      provider.triggerCharacters = triggers
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
      vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, {
        buffer = event.buf,
        desc = "LSP completion (Ctrl-Y accepts)",
      })
    end

    -- Keep native grn/gra/grr, VimTeX navigation, and Julia's Unicode Tab.
    local function map(key, action, description)
      vim.keymap.set("n", key, action, { buffer = event.buf, desc = description })
    end
    map("<leader>ld", vim.lsp.buf.definition, "LSP definition")
    map("<leader>lh", vim.lsp.buf.hover, "LSP hover")
    map("<leader>le", vim.diagnostic.open_float, "Line diagnostics")
  end,
})

vim.lsp.config("pyright", {
  settings = {
    pyright = { disableOrganizeImports = vim.fn.executable("ruff") == 1 },
    python = { analysis = { diagnosticMode = "openFilesOnly" } },
  },
})

vim.lsp.config("texlab", {
  settings = {
    texlab = {
      -- VimTeX owns compilation and PDF forward search.
      build = { onSave = false, forwardSearchAfter = false },
    },
  },
})

vim.lsp.config("julials", {
  -- LanguageServer 6 supports Julia 1.13 and replaces the old loader API.
  cmd = function(dispatchers, config)
    local command = {
      "julia", "--startup-file=no", "--history-file=no",
      "--project=" .. vim.fn.expand("~/.julia/environments/nvim-lspconfig"),
      "-e", "using LanguageServer; runserver()",
    }
    if config.root_dir then
      command[#command + 1] = config.root_dir
    end
    return vim.lsp.rpc.start(command, dispatchers, {
      cwd = config.root_dir, env = config.cmd_env, detached = config.detached,
    })
  end,
  settings = {
    julia = {
      enableWorkspaceEnvironmentResolution = false,
      maxConcurrentIndexingProcesses = 2,
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "LspJuliaActivateEnv", function(args)
      local path = vim.fn.fnamemodify(vim.fn.expand(args.args), ":p")
      if vim.fn.filereadable(path .. "/Project.toml") == 0
        and vim.fn.filereadable(path .. "/JuliaProject.toml") == 0 then
        vim.notify("No Julia Project.toml in " .. path, vim.log.levels.WARN)
        return
      end
      client:notify("julia/setEnvironmentPath", { envPath = path })
    end, { nargs = 1, complete = "dir", desc = "Activate a Julia project directory" })
  end,
})

-- Keep lspconfig's project detection, including compile_commands.json for C++.
-- Mason adds its bin directory to PATH before this module is loaded.
for name, executable in pairs({
  pyright = "pyright-langserver",
  julials = "julia",
  clangd = "clangd",
  texlab = "texlab",
  ruff = "ruff",
}) do
  if vim.fn.executable(executable) == 1 then
    vim.lsp.enable(name)
  end
end
