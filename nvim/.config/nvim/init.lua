-- Set <space> as the leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.g.have_nerd_font = true


-- [[ Setting options ]]
vim.o.number = true
vim.o.mouse = 'a'
vim.o.showmode = false
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.opt.directory = vim.fn.stdpath 'state' .. '/swap//'
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation is handled by smart-splits.nvim (alt+hjkl)

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Autocommands ]]
vim.api.nvim_create_autocmd('FocusLost', {
  desc = 'Save all buffers on focus loss',
  callback = function() vim.cmd 'silent! wall' end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Jump to last known cursor position',
  callback = function(args)
    local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line('$')
    local not_commit = vim.b[args.buf].filetype ~= 'commit'
    if valid_line and not_commit then
      vim.cmd([[normal! g`"]])
    end
  end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Restore session for cwd when nvim is launched with no args',
  nested = true,
  callback = function()
    if vim.fn.argc() == 0 and vim.bo.filetype == '' then
      require('persistence').load()
    end
  end,
})

-- Norwegian keyboard: map ø to : (ø is on the colon key)
vim.keymap.set({ 'n', 'x', 'o' }, 'ø', ':', { desc = 'Command mode (Norwegian keyboard)' })

-- Cmd+S to save (WezTerm sends <Esc>s as \x1bs)
vim.keymap.set({ 'n', 'v' }, '\x1bs', '<cmd>w<CR>', { desc = 'Save file (Cmd+S)' })
vim.keymap.set('i', '\x1bs', '<Esc><cmd>w<CR>', { desc = 'Save file (Cmd+S)' })

-- Comment aliases
vim.keymap.set('n', '<leader>cc', 'gcc', { remap = true, desc = 'Comment line' })
vim.keymap.set('v', '<leader>c', 'gc', { remap = true, desc = 'Comment selection' })

-- Move visual selection up/down (Super+j/k via Ghostty -> <M-j>/<M-k>)
vim.keymap.set('x', '<M-j>', ":m '>+1<CR>gv=gv", { silent = true, desc = 'Move selection down' })
vim.keymap.set('x', '<M-k>', ":m '<-2<CR>gv=gv", { silent = true, desc = 'Move selection up' })

vim.keymap.set('x', '<Tab>', '>gv', { desc = 'Indent selection' })
vim.keymap.set('x', '<S-Tab>', '<gv', { desc = 'Dedent selection' })



-- Reload config
vim.keymap.set('n', '<leader>R', function() vim.cmd('source $MYVIMRC') vim.notify('Config reloaded') end, { desc = '[R]eload config' })

-- Abbreviations
vim.cmd [[inoreabbrev ldis_ ಠ_ಠ]]

-- [[ Install lazy.nvim ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end
---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- [[ Plugins ]]
require('lazy').setup({
  { import = 'plugins' },
}, { ---@diagnostic disable-line: missing-fields
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
