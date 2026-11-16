return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "zathura"
    vim.g.vimtex_view_automatic = 0
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = { continuous = 1 }
    vim.g.tex_auto_build = true
  end,
  keys = {
    { "<leader>lv", "<Cmd>VimtexView<CR>", desc = "View PDF at the current source line" },
    { "<leader>lb", "<Cmd>VimtexCompile!<CR>", desc = "Start LaTeX compilation" },
    { "<leader>lq", "<Cmd>VimtexErrors<CR>", desc = "LaTeX errors" },
    { "<leader>lt", "<Cmd>VimtexTocToggle<CR>", desc = "LaTeX contents" },
    {
      "<leader>uv",
      function()
        vim.g.tex_auto_build = not vim.g.tex_auto_build
        if not vim.g.tex_auto_build then vim.fn["vimtex#compiler#stop_all"]() end
        vim.notify("LaTeX build on save: " .. (vim.g.tex_auto_build and "on" or "off"))
      end,
      desc = "Toggle LaTeX build on save",
    },
  },
  config = function()
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("TexBuildOnSave", { clear = true }),
      pattern = "*.tex",
      callback = function(event)
        if not vim.g.tex_auto_build or vim.bo[event.buf].buftype ~= "" then return end
        vim.api.nvim_buf_call(event.buf, function()
          if vim.fn.exists("b:vimtex.compiler") == 1 then
            -- The bang starts a watcher only if one is not already running.
            -- VimTeX shares that watcher between the document's source files.
            vim.cmd("silent VimtexCompile!")
          end
        end)
      end,
    })
  end,
}
