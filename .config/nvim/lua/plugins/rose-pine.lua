return {
  "rose-pine/neovim",
  name = "rose-pine",
  priority = 1000,
  lazy = false,
  opts = {
    variant = "main",
    dark_variant = "main",
    dim_inactive_windows = false,
    extend_background_behind_borders = false,
    styles = { transparency = true },
    highlight_groups = {
      -- Let Kitty supply the background; keep popup choices easy to read.
      NormalFloat = { fg = "text", bg = "none" },
      FloatBorder = { fg = "muted", bg = "none" },
      FloatTitle = { fg = "foam", bg = "none", bold = true },
      FloatFooter = { fg = "subtle", bg = "none" },
      FoldColumn = { fg = "muted", bg = "none" },
      LineNr = { fg = "muted", bg = "none" },
      CursorLineNr = { fg = "gold", bg = "none", bold = true },
      -- VimTeX option commas should remain delimiters.
      texOptSep = { link = "Delimiter", inherit = false },
      -- A single panel colour across native completion's columns and border.
      Pmenu = { fg = "text", bg = "surface", inherit = false },
      PmenuSel = { fg = "text", bg = "highlight_med", inherit = false },
      PmenuKind = { fg = "subtle", bg = "surface", inherit = false },
      PmenuKindSel = { fg = "text", bg = "highlight_med", inherit = false },
      PmenuExtra = { fg = "subtle", bg = "surface", inherit = false },
      PmenuExtraSel = { fg = "text", bg = "highlight_med", inherit = false },
      PmenuMatch = { fg = "rose", bold = true },
      PmenuMatchSel = { fg = "text", bold = true },
      PmenuSbar = { bg = "surface" },
      PmenuThumb = { bg = "highlight_high" },
      PmenuBorder = { fg = "muted", bg = "surface" },
      WinSeparator = { fg = "highlight_med", bg = "none" },
      SnacksPickerMatch = { fg = "rose", bold = true },
      SnacksPickerPrompt = { fg = "rose" },
      SnacksIndent = { fg = "highlight_low" },
      SnacksIndentScope = { fg = "muted" },
    },
  },
  config = function(_, opts)
    require("rose-pine").setup(opts)
    require("config.desktop_theme").setup()
  end,
}
