return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
      mode = { "n", "v" },
      desc = "Format code",
    },
    {
      "<leader>uf",
      function()
        vim.b.disable_autoformat = not vim.b.disable_autoformat
        vim.notify("Format on save: " .. (vim.b.disable_autoformat and "off" or "on"))
      end,
      desc = "Toggle format on save for this file",
    },
  },
  opts = {
    formatters_by_ft = {
      python = { "ruff_format" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      julia = { lsp_format = "fallback" },
    },
    format_on_save = function(bufnr)
      local ft = vim.bo[bufnr].filetype
      if vim.b[bufnr].disable_autoformat or vim.bo[bufnr].buftype ~= ""
          or not vim.tbl_contains({ "python", "julia", "c", "cpp" }, ft)
          or vim.api.nvim_buf_line_count(bufnr) > 20000 then
        return
      end
      -- Julia formats through its already running language server. Starting a
      -- separate Julia process on each save would be unnecessarily slow.
      -- The first Julia formatting request can need several seconds to compile.
      return { timeout_ms = ft == "julia" and 10000 or 1200, lsp_format = "fallback", quiet = false }
    end,
  },
}
