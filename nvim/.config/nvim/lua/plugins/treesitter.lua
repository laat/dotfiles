---@module 'lazy'
---@type LazySpec
return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  branch = 'main',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  config = function()
    local parsers = { 'bash', 'c', 'css', 'diff', 'go', 'html', 'javascript', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'python', 'query', 'rust', 'svelte', 'tsx', 'typescript', 'vim', 'vimdoc' }
    require('nvim-treesitter').install(parsers)

    ---@param buf integer
    ---@param language string
    local function treesitter_try_attach(buf, language)
      if not vim.treesitter.language.add(language) then return end
      vim.treesitter.start(buf, language)
      local has_indent_query = vim.treesitter.query.get(language, 'indents') ~= nil
      if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
    end

    local available_parsers = require('nvim-treesitter').get_available()
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        local buf, filetype = args.buf, args.match
        local language = vim.treesitter.language.get_lang(filetype)
        if not language then return end
        local installed_parsers = require('nvim-treesitter').get_installed 'parsers'
        if vim.tbl_contains(installed_parsers, language) then
          treesitter_try_attach(buf, language)
        elseif vim.tbl_contains(available_parsers, language) then
          require('nvim-treesitter').install(language):await(function() treesitter_try_attach(buf, language) end)
        else
          treesitter_try_attach(buf, language)
        end
      end,
    })

    -- Treesitter textobjects
    require('nvim-treesitter-textobjects')

    local ts_select = require('nvim-treesitter-textobjects.select')
    vim.keymap.set({ 'x', 'o' }, 'af', function() ts_select.select_textobject('@function.outer', 'textobjects') end, { desc = 'outer function' })
    vim.keymap.set({ 'x', 'o' }, 'if', function() ts_select.select_textobject('@function.inner', 'textobjects') end, { desc = 'inner function' })
    vim.keymap.set({ 'x', 'o' }, 'ac', function() ts_select.select_textobject('@class.outer', 'textobjects') end, { desc = 'outer class' })
    vim.keymap.set({ 'x', 'o' }, 'ic', function() ts_select.select_textobject('@class.inner', 'textobjects') end, { desc = 'inner class' })

    local ts_move = require('nvim-treesitter-textobjects.move')
    vim.keymap.set({ 'n', 'x', 'o' }, ']m', function() ts_move.goto_next_start('@function.outer', 'textobjects') end, { desc = 'Next function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']]', function() ts_move.goto_next_start('@class.outer', 'textobjects') end, { desc = 'Next class start' })
    vim.keymap.set({ 'n', 'x', 'o' }, ']M', function() ts_move.goto_next_end('@function.outer', 'textobjects') end, { desc = 'Next function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '][', function() ts_move.goto_next_end('@class.outer', 'textobjects') end, { desc = 'Next class end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[m', function() ts_move.goto_previous_start('@function.outer', 'textobjects') end, { desc = 'Prev function start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[[', function() ts_move.goto_previous_start('@class.outer', 'textobjects') end, { desc = 'Prev class start' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[M', function() ts_move.goto_previous_end('@function.outer', 'textobjects') end, { desc = 'Prev function end' })
    vim.keymap.set({ 'n', 'x', 'o' }, '[]', function() ts_move.goto_previous_end('@class.outer', 'textobjects') end, { desc = 'Prev class end' })

    local ts_swap = require('nvim-treesitter-textobjects.swap')
    vim.keymap.set('n', '<leader>a', function() ts_swap.swap_next('@parameter.inner') end, { desc = 'Swap next parameter' })
    vim.keymap.set('n', '<leader>A', function() ts_swap.swap_previous('@parameter.inner') end, { desc = 'Swap prev parameter' })

    vim.keymap.set({ 'n', 'x' }, '+', function() require('vim.treesitter._select').select_parent(vim.v.count1) end, { desc = 'Select parent node' })
    vim.keymap.set('x', '-', function() require('vim.treesitter._select').select_child(vim.v.count1) end, { desc = 'Select child node' })
  end,
}
