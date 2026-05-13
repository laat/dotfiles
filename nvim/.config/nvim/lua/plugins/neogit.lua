return {
  'NeogitOrg/neogit',
  commit = '0cac75a5', -- pinned: 7a3daecb introduced scope+buf bug incompatible with nvim 0.12
  dependencies = {
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
  },
  config = function()
    require('neogit').setup()
    vim.keymap.set('n', '<leader>gs', require('neogit').open, { desc = 'Open [G]it [S]tatus' })
  end,
}
