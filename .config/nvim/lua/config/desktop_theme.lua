-- Follow the desktop palette without changing buffers, mappings, or editor options.
local M = {}
local applied

function M.selected()
  local override = vim.env.DESKTOP_THEME
  if override == "rose-pine" or override == "gruvbox" then
    return override
  end
  local root = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
  local file = io.open(root .. "/desktop-themes/current/name", "r")
  local name = file and file:read("*l") or "rose-pine"
  if file then file:close() end
  return name == "gruvbox" and "gruvbox" or "rose-pine"
end

function M.apply()
  local name = M.selected()
  if name == "gruvbox" then
    -- Lazy loads the pinned plugin and runs its appearance-only setup first.
    require("gruvbox")
    vim.cmd.colorscheme("gruvbox")
  else
    vim.cmd.colorscheme("rose-pine-main")
  end
  applied = name
end

function M.setup()
  M.apply()
  vim.api.nvim_create_user_command("DesktopThemeReload", M.apply, {
    desc = "Apply the currently selected desktop palette",
    force = true,
  })
  local group = vim.api.nvim_create_augroup("DesktopTheme", { clear = true })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      -- Manual :colorscheme choices survive refocus until the desktop changes.
      if M.selected() ~= applied then
        M.apply()
      end
    end,
    desc = "Follow desktop palette changes when returning to Neovim",
  })
end

return M
