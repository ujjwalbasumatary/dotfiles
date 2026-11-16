return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      globalstatus = true,
      section_separators = { left = "", right = "" },
      component_separators = { left = "│", right = "│" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = {
        { "filename", file_status = true, symbols = { modified = "●" } },
      },
      lualine_x = {
        { "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" } },
      },
      lualine_y = {},
      lualine_z = { "location" },
    },
  },
}
