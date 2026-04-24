---@module 'lazy'
---@type LazySpec
return {
  'nickjvandyke/opencode.nvim',
  version = '*',
  dependencies = { 'folke/snacks.nvim' },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = false,
        stop = false,
        toggle = function()
          vim.fn.system('tmux split-window -hb "opencode --port 0"')
        end,
      },
    }

    vim.o.autoread = true

    vim.keymap.set({ 'n', 'x' }, '<C-a>', function() require('opencode').ask('@this: ', { submit = true }) end, { desc = 'Ask opencode' })
    vim.keymap.set({ 'n', 'x' }, '<C-x>', function() require('opencode').select() end, { desc = 'Execute opencode action' })
    vim.keymap.set({ 'n', 't' }, '<C-.>', function() require('opencode').toggle() end, { desc = 'Toggle opencode' })

    vim.keymap.set({ 'n', 'x' }, 'go', function() return require('opencode').operator('@this ') end, { desc = 'Add range to opencode', expr = true })
    vim.keymap.set('n', 'goo', function() return require('opencode').operator('@this ') .. '_' end, { desc = 'Add line to opencode', expr = true })

    vim.keymap.set('n', '<S-C-u>', function() require('opencode').command('session.half.page.up') end, { desc = 'Scroll opencode up' })
    vim.keymap.set('n', '<S-C-d>', function() require('opencode').command('session.half.page.down') end, { desc = 'Scroll opencode down' })

    -- Restore increment/decrement since C-a/C-x are taken
    vim.keymap.set('n', '+', '<C-a>', { desc = 'Increment under cursor', noremap = true })
    vim.keymap.set('n', '-', '<C-x>', { desc = 'Decrement under cursor', noremap = true })
  end,
}
