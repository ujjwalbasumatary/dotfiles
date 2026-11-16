return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = true,
  opts = {
    flavour = "mocha",
    transparent_background = false,
    float = { transparent = false },
    dim_inactive = { enabled = true, shade = "dark", percentage = 0.08 },
    integrations = {
      snacks = { enabled = true, indent_scope_color = "lavender" },
    },
    custom_highlights = function(colors)
      return {
        FloatBorder = { fg = colors.surface2, bg = colors.mantle },
        WinSeparator = { fg = colors.surface0 },
        SnacksPickerMatch = { fg = colors.lavender, bold = true },
        SnacksPickerPrompt = { fg = colors.lavender },
      }
    end,
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
  end,
}
