-- Pane navigation with WezTerm integration
return {
  'mrjones2014/smart-splits.nvim',
  lazy = false,
  keys = {
    { '<M-h>', function() require('smart-splits').move_cursor_left()  end, desc = 'Navigate left' },
    { '<M-j>', function() require('smart-splits').move_cursor_down()  end, desc = 'Navigate down' },
    { '<M-k>', function() require('smart-splits').move_cursor_up()    end, desc = 'Navigate up' },
    { '<M-l>', function() require('smart-splits').move_cursor_right() end, desc = 'Navigate right' },
    { '<M-H>', function() require('smart-splits').resize_left()       end, desc = 'Resize left' },
    { '<M-J>', function() require('smart-splits').resize_down()       end, desc = 'Resize down' },
    { '<M-K>', function() require('smart-splits').resize_up()         end, desc = 'Resize up' },
    { '<M-L>', function() require('smart-splits').resize_right()      end, desc = 'Resize right' },
  },
  opts = {},
}
