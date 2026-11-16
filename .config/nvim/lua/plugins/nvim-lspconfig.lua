return {
  "neovim/nvim-lspconfig",
  lazy = false,
  dependencies = { "mason-org/mason.nvim" },
  config = function()
    require("config.lsp")
  end,
}
