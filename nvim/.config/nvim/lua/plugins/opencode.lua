---@module 'lazy'
---@type LazySpec
return {
  'nickjvandyke/opencode.nvim',
  enabled = false,
  version = '*',
  dependencies = { 'folke/snacks.nvim' },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = false,
        stop = false,
        toggle = function()
          if vim.env.TMUX then
            local pane = vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_current_command}' | grep -i opencode | awk '{print $1}' | head -1")
            pane = pane:gsub('%s+', '')
            if pane ~= '' then
              vim.fn.system('tmux select-pane -t ' .. pane)
            else
              vim.fn.system('tmux split-window -hb "opencode --port 0"')
            end
          elseif vim.env.WEZTERM_PANE then
            local json = vim.fn.system('wezterm cli list --format json 2>/dev/null')
            local panes = vim.fn.json_decode(json) or {}
            local pane_id = nil
            for _, pane in ipairs(panes) do
              if pane.title and pane.title:lower():find('opencode') then
                pane_id = pane.pane_id
                break
              end
            end
            if pane_id ~= nil then
              vim.fn.system('wezterm cli activate-pane --pane-id ' .. pane_id)
            else
              vim.fn.system('wezterm cli split-pane --left -- opencode --port 0')
            end
          end
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
  end,
}
