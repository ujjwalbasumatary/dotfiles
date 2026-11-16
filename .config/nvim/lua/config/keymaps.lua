local map = vim.keymap.set

-- A string expression lets julia-vim preserve this as its fallback for Tab.
-- Its buffer-local mapping still handles Unicode sequences such as \alpha.
-- Vimscript already encodes the returned keys; do not encode them again.
map({ "i", "s" }, "<Tab>",
  [[pumvisible() ? (complete_info().selected < 0 ? "\<C-n>\<C-y>" : "\<C-y>") : (v:lua.vim.snippet.active({'direction': 1}) ? "\<Cmd>lua vim.snippet.jump(1)\<CR>" : "\<Tab>")]],
  { expr = true, silent = true, replace_keycodes = false,
    desc = "Accept suggestion, next snippet field, or indent" })
map({ "i", "s" }, "<S-Tab>",
  [[v:lua.vim.snippet.active({'direction': -1}) ? "\<Cmd>lua vim.snippet.jump(-1)\<CR>" : "\<S-Tab>"]],
  { expr = true, silent = true, replace_keycodes = false, desc = "Previous snippet field" })

map({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to system clipboard" })
map("n", "<leader>Y", '"+y$', { desc = "Copy to end of line" })
map("n", "<leader>ay", function()
  vim.fn.setreg("+", vim.api.nvim_buf_get_lines(0, 0, -1, false), "V")
  vim.notify("Copied the whole document")
end, { desc = "Copy whole document" })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from system clipboard" })

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window below" })
map("n", "<C-k>", "<C-w>k", { desc = "Window above" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Leave terminal input mode" })
map("n", "<leader>w", "<Cmd>update<CR>", { desc = "Save changed file" })
map("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlighting" })
