vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.termguicolors = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.scrolloff = 5
opt.sidescrolloff = 5
opt.splitright = true
opt.splitbelow = true
opt.undofile = true
opt.updatetime = 300
opt.timeoutlen = 400
opt.mouse = "a"
opt.confirm = true
opt.inccommand = "split"
opt.wrap = false
opt.laststatus = 3
opt.showmode = false -- The mode is already shown in Lualine.
opt.cursorline = true
opt.winborder = "single"
opt.pumborder = "single"
opt.fillchars:append({ eob = " " })

-- Ordinary Vim registers keep their usual meaning. Explicit clipboard
-- shortcuts are defined in config/keymaps.lua; Neovim selects the provider.
local group = vim.api.nvim_create_augroup("PersonalEditing", { clear = true })
local function current_line(enabled)
  local win = vim.api.nvim_get_current_win()
  -- Keep the focus cue in ordinary editing windows. Pickers and other
  -- plugin windows retain their own selection highlights.
  if vim.bo.buftype == "" and vim.api.nvim_win_get_config(win).relative == "" then
    vim.api.nvim_set_option_value("cursorline", enabled, { win = win, scope = "local" })
  end
end
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter", "WinLeave" }, {
  group = group,
  callback = function(event)
    current_line(event.event ~= "WinLeave")
  end,
})
vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  callback = function()
    -- Closing a run terminal can return to the source without WinEnter.
    -- Wait until the closing window has gone before checking the new focus.
    vim.schedule(function() current_line(true) end)
  end,
})
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "lua", "tex", "bib" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})
