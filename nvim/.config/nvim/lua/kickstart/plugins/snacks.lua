---@module 'lazy'
---@type LazySpec
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    explorer = {
      replace_netrw = true,
    },
    picker = {
      sources = {
        explorer = {
          hidden = true,
        },
      },
    },
  },
  keys = {
    { ',n', function() Snacks.explorer() end, desc = 'Toggle file explorer' },
  },
}
