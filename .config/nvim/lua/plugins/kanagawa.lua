return {
  "rebelot/kanagawa.nvim",
  lazy = true,
  opts = {
    theme = "wave",
    background = { dark = "wave", light = "lotus" },
    transparent = true,
    dimInactive = false,
    overrides = function(colors)
      local theme = colors.theme
      local menu_bg = theme.ui.float.bg
      local selection_bg = theme.ui.bg_visual
      return {
        -- Let Kitty supply the background for editing, gutters, and floats.
        NormalFloat = { fg = theme.ui.float.fg, bg = "NONE" },
        FloatBorder = { fg = theme.ui.bg_p2, bg = "NONE" },
        FloatTitle = { fg = theme.ui.special, bg = "NONE", bold = true },
        FloatFooter = { fg = theme.ui.nontext, bg = "NONE" },
        SignColumn = { fg = theme.ui.special, bg = "NONE" },
        FoldColumn = { fg = theme.ui.nontext, bg = "NONE" },
        LineNr = { fg = theme.ui.nontext, bg = "NONE" },
        CursorLineNr = { fg = theme.diag.warning, bg = "NONE", bold = true },
        -- Keep VimTeX option commas styled as delimiters.
        texOptSep = { link = "Delimiter" },
        -- Native completion: a charcoal panel with one muted selection row.
        -- Keep every column and its border on the same background.
        Pmenu = { fg = theme.ui.fg, bg = menu_bg },
        PmenuSel = { fg = theme.ui.fg, bg = selection_bg },
        PmenuKind = { fg = theme.ui.fg_dim, bg = menu_bg },
        PmenuKindSel = { fg = theme.ui.fg, bg = selection_bg },
        PmenuExtra = { fg = theme.ui.fg_dim, bg = menu_bg },
        PmenuExtraSel = { fg = theme.ui.fg, bg = selection_bg },
        PmenuMatch = { fg = theme.syn.fun, bold = true },
        PmenuMatchSel = { fg = theme.ui.fg, bold = true },
        PmenuSbar = { bg = menu_bg },
        PmenuThumb = { bg = theme.ui.bg_p2 },
        PmenuBorder = { fg = theme.ui.bg_p2, bg = menu_bg },
        WinSeparator = { fg = theme.ui.bg_p1 },
        SnacksPickerMatch = { fg = theme.syn.fun, bold = true },
        SnacksPickerPrompt = { fg = theme.syn.fun },
        SnacksIndent = { fg = theme.ui.bg_p1 },
        SnacksIndentScope = { fg = theme.ui.nontext },
      }
    end,
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
  end,
}
