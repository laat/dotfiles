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
      actions = {
        opencode_send = function(...) return require('opencode').snacks_picker_send(...) end,
      },
      win = {
        input = {
          keys = {
            ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
          },
        },
      },
    },
    input = {},
  },
  keys = {
    -- Explorer
    { ',n', function() Snacks.explorer() end, desc = 'Toggle file explorer' },

    -- Search
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sf', function() Snacks.picker.files({ hidden = true }) end, desc = '[S]earch [F]iles' },
    { '<leader>ss', function() Snacks.picker.pickers() end, desc = '[S]earch [S]elect Picker' },
    { '<leader>sw', function() Snacks.picker.grep_word({ hidden = true }) end, desc = '[S]earch current [W]ord', mode = { 'n', 'v' } },
    { '<leader>sg', function() Snacks.picker.grep({ hidden = true }) end, desc = '[S]earch by [G]rep' },
    { '<leader>si', function() Snacks.picker.diagnostics() end, desc = '[S]earch D[i]agnostics' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent Files' },
    { '<leader>sc', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
    { '<leader><leader>', function() Snacks.picker.buffers() end, desc = '[ ] Find existing buffers' },
    { '<leader>gf', function() Snacks.picker.git_files() end, desc = 'Search [G]it [F]iles' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },
    { '<leader>s/', function() Snacks.picker.grep({ search_dirs = vim.tbl_map(function(b) return vim.api.nvim_buf_get_name(b) end, vim.api.nvim_list_bufs()) }) end, desc = '[S]earch [/] in Open Files' },
    { '<leader>sn', function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end, desc = '[S]earch [N]eovim files' },

    -- LSP (set in config via LspAttach, but snacks also supports these directly)
    { 'grr', function() Snacks.picker.lsp_references() end, desc = '[G]oto [R]eferences' },
    { 'gri', function() Snacks.picker.lsp_implementations() end, desc = '[G]oto [I]mplementation' },
    { 'grd', function() Snacks.picker.lsp_definitions() end, desc = '[G]oto [D]efinition' },
    { 'gO',  function() Snacks.picker.lsp_symbols() end, desc = 'Open Document Symbols' },
    { 'gW',  function() Snacks.picker.lsp_workspace_symbols() end, desc = 'Open Workspace Symbols' },
    { 'grt', function() Snacks.picker.lsp_type_definitions() end, desc = '[G]oto [T]ype Definition' },
  },
}
