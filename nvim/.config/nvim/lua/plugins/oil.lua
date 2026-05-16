---@module 'lazy'
---@type LazySpec
return {
  'stevearc/oil.nvim',
  lazy = false,
  dependencies = { 'nvim-mini/mini.nvim' },
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = false,
    view_options = { show_hidden = true },
  },
  keys = {
    { '-', '<cmd>Oil<CR>', desc = 'Open parent directory (oil)' },
  },
}
