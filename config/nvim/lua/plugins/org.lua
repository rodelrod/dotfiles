return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if opts.ensure_installed ~= "all" then
        opts.ensure_installed = opts.ensure_installed or {}
        if not vim.tbl_contains(opts.ensure_installed, "org") then
          table.insert(opts.ensure_installed, "org")
        end
      end
    end,
  },
}
