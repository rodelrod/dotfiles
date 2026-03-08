return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = opts.ensure_installed or {}
        local parsers = { "go", "gomod", "gowork", "gosum" }
        for _, parser in ipairs(parsers) do
          if not vim.tbl_contains(opts.ensure_installed, parser) then
            table.insert(opts.ensure_installed, parser)
          end
        end
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "gopls",
      },
    },
  },
}
