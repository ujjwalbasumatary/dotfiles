-- All execution is explicit: opening or saving a source file starts no process.
local M = {}
local runs = {}
local build_job
local markers = { ".git", "pyproject.toml", "setup.py", "requirements.txt", ".venv", "Project.toml", "Makefile", "CMakeLists.txt" }
local makefiles = { "GNUmakefile", "makefile", "Makefile" }

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "Run / Build" })
end

local function source()
  local file = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or file == "" then
    notify("Open a named source file first.", vim.log.levels.WARN)
    return
  end
  local language = vim.bo.filetype
  if language ~= "python" and language ~= "julia" then
    notify("RunFile and OpenREPL support Python and Julia. Use Build for a Makefile project.", vim.log.levels.WARN)
    return
  end
  local project = language == "julia" and vim.fs.root(file, { "Project.toml" }) or nil
  return {
    file = file,
    language = language,
    project = project,
    root = project or vim.fs.root(file, { markers }) or vim.fs.dirname(file),
  }
end

local function command(context)
  if context.language == "julia" then
    if vim.fn.executable("julia") ~= 1 then
      notify("Julia is not on PATH.", vim.log.levels.ERROR)
      return
    end
    local argv = { "julia" }
    if context.project then
      argv[#argv + 1] = "--project=" .. context.project
    end
    return argv
  end

  local environments = { vim.env.VIRTUAL_ENV or "", vim.fs.joinpath(context.root, ".venv") }
  for _, environment in ipairs(environments) do
    if environment ~= "" then
      local python = vim.fs.joinpath(environment, "bin", "python")
      if vim.fn.executable(python) == 1 then
        return { python }, {
          VIRTUAL_ENV = environment,
          PATH = vim.fs.joinpath(environment, "bin") .. ":" .. (vim.env.PATH or ""),
        }
      end
    end
  end
  for _, python in ipairs({ "python3", "python" }) do
    if vim.fn.executable(python) == 1 then
      return { python }
    end
  end
  notify("Python is not on PATH and no usable virtual environment was found.", vim.log.levels.ERROR)
end

local function running(terminal)
  if not terminal or not terminal:buf_valid() then
    return false
  end
  local channel = vim.b[terminal.buf].terminal_job_id
  return channel and vim.fn.jobwait({ channel }, 0)[1] == -1
end

local function terminal_options(context, environment, repl)
  return {
    cwd = context.root,
    env = environment,
    count = repl and 1 or 2,
    auto_close = false,
    start_insert = true,
    auto_insert = true,
    win = { position = "bottom", height = 0.35 },
  }
end

function M.run_file()
  local context = source()
  if not context then
    return
  end
  local argv, environment = command(context)
  if not argv then
    return
  end
  local key = context.root .. "\n" .. context.language
  local previous = runs[key]
  if running(previous) then
    previous:show():focus()
    notify("A file is already running for this project. Use Ctrl-C in its terminal to interrupt it.", vim.log.levels.WARN)
    return
  end
  local saved, error = pcall(vim.cmd.update)
  if not saved then
    notify("Could not save the file: " .. tostring(error), vim.log.levels.ERROR)
    return
  end
  if vim.fn.filereadable(context.file) ~= 1 then
    notify("Save this file before running it.", vim.log.levels.WARN)
    return
  end
  if previous and previous:buf_valid() then
    previous:close()
  end
  if context.language == "python" then
    argv[#argv + 1] = "-u"
  end
  argv[#argv + 1] = context.file
  runs[key] = Snacks.terminal.open(argv, terminal_options(context, environment, false))
end

function M.open_repl()
  local context = source()
  if not context then
    return
  end
  local argv, environment = command(context)
  if not argv then
    return
  end
  local opts = terminal_options(context, environment, true)
  local existing = Snacks.terminal.get(argv, vim.tbl_extend("force", opts, { create = false }))
  if existing and not running(existing) then
    existing:close()
  end
  local terminal = Snacks.terminal.get(argv, opts)
  terminal:show():focus()
end

local function make_directory()
  local file = vim.api.nvim_buf_get_name(0)
  local start = vim.bo.buftype == "" and file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
  local makefile = vim.fs.find(makefiles, { path = start, upward = true, type = "file" })[1]
  if makefile then
    return vim.fs.dirname(makefile)
  end
  local root = vim.fs.root(start, { { ".git", "CMakeLists.txt" } }) or start
  local build = vim.fs.joinpath(root, "build")
  for _, name in ipairs(makefiles) do
    if vim.fn.filereadable(vim.fs.joinpath(build, name)) == 1 then
      return build
    end
  end
end

function M.build(args)
  if build_job then
    notify("A build is already running. Use :BuildStop to interrupt it.", vim.log.levels.WARN)
    return
  end
  local directory = make_directory()
  if not directory then
    notify("No Makefile found above this file or in the project's existing build/ directory.", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("make") ~= 1 then
    notify("make is not on PATH.", vim.log.levels.ERROR)
    return
  end
  local saved, error = pcall(function()
    if vim.bo.buftype == "" then
      vim.cmd.update()
    end
  end)
  if not saved then
    notify("Could not save the current buffer: " .. tostring(error), vim.log.levels.ERROR)
    return
  end

  local title = "make " .. table.concat(args or {}, " ") .. " [" .. directory .. "]"
  local lines = { "__NVIM_BUILD_CWD__" .. directory }
  local efm = "%-D__NVIM_BUILD_CWD__%f," .. vim.o.errorformat
  vim.fn.setqflist({}, " ", { title = title, items = {} })
  local quickfix_id = vim.fn.getqflist({ id = 0 }).id
  -- The fixed shell fragment only merges streams. All arguments and the cwd
  -- are passed separately, including project paths containing spaces.
  local argv = { "sh", "-c", 'exec "$@" 2>&1', "nvim-build", "make", "--print-directory" }
  vim.list_extend(argv, args or {})
  local job = vim.fn.jobstart(argv, {
    cwd = directory,
    env = { LC_ALL = "C", NO_COLOR = "1", GCC_COLORS = "", CLICOLOR = "0" },
    stdout_buffered = true,
    on_stdout = function(_, output)
      vim.list_extend(lines, output)
    end,
    on_exit = function(_, code)
      build_job = nil
      vim.schedule(function()
        vim.fn.setqflist({}, "r", { id = quickfix_id, title = title, lines = lines, efm = efm })
        if vim.fn.getqflist({ id = 0 }).id == quickfix_id then
          local items = vim.fn.getqflist()
          local diagnostics = vim.tbl_filter(function(item)
            return item.valid == 1
          end, items)
          if code ~= 0 or #diagnostics > 0 then
            vim.cmd.copen()
          end
        end
        notify("Build " .. (code == 0 and "finished" or ("exited with code " .. code)) .. ". Output: :copen",
          code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
      end)
    end,
  })
  if job <= 0 then
    notify("Could not start make.", vim.log.levels.ERROR)
    return
  end
  build_job = job
  notify("Building in " .. directory)
end

vim.api.nvim_create_user_command("RunFile", M.run_file, { desc = "Save and run the current Python/Julia file" })
vim.api.nvim_create_user_command("OpenREPL", M.open_repl, { desc = "Open the project's persistent Python/Julia REPL" })
vim.api.nvim_create_user_command("Build", function(opts)
  M.build(opts.fargs)
end, { nargs = "*", desc = "Save current file and run make asynchronously; optional targets/arguments" })
vim.api.nvim_create_user_command("BuildStop", function()
  if build_job then
    vim.fn.jobstop(build_job)
  else
    notify("No build is running.")
  end
end, { desc = "Stop the active build" })

vim.keymap.set("n", "<leader>rr", M.run_file, { desc = "Run current Python/Julia file" })
vim.keymap.set("n", "<leader>ri", M.open_repl, { desc = "Open Python/Julia REPL" })
vim.keymap.set("n", "<leader>rb", function() M.build({}) end, { desc = "Build project (make)" })
vim.keymap.set("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix error" })
vim.keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix error" })

return M
