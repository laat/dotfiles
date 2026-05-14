-- Run with:
--   nvim --headless -u NONE -c "set rtp+=$VIMRUNTIME" -c "set rtp+=." \
--        -c "lua require('tests.treesitter_select_spec')" -c "qa!"

local failures = 0

local function fail(msg)
  failures = failures + 1
  io.stderr:write('FAIL: ' .. msg .. '\n')
end

local function ok(msg)
  io.stdout:write('PASS: ' .. msg .. '\n')
end

local function setup_buf(lines)
  vim.cmd('enew!')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = 'lua'
  vim.treesitter.start(0, 'lua')
end

local function set_keymaps()
  vim.keymap.set({ 'n', 'x' }, '+', function()
    require('vim.treesitter._select').select_parent(vim.v.count1)
  end, { desc = 'Select parent node' })
  vim.keymap.set('x', '-', function()
    require('vim.treesitter._select').select_child(vim.v.count1)
  end, { desc = 'Select child node' })
end

local function feed(keys)
  local termcodes = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(termcodes, 'x', false)
end

local function selection_range()
  -- After visual mode, '<' and '>' marks hold the selection
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  return { s[2], s[3], e[2], e[3] }
end

local function expect_selection(name, want)
  local got = selection_range()
  if vim.deep_equal(got, want) then
    ok(name .. ' selection=' .. vim.inspect(got))
  else
    fail(name .. ' want=' .. vim.inspect(want) .. ' got=' .. vim.inspect(got))
  end
end

local function expect_mode(name, want)
  local got = vim.fn.mode()
  if got == want then
    ok(name .. ' mode=' .. got)
  else
    fail(name .. ' want mode=' .. want .. ' got=' .. got)
  end
end

set_keymaps()

-- Test 1: + from normal mode enters visual mode and selects parent of node at cursor
do
  setup_buf({
    'local function foo()',
    '  return x + 1',
    'end',
  })
  -- Cursor on 'x' in line 2, column 10 (1-indexed)
  vim.api.nvim_win_set_cursor(0, { 2, 9 })
  feed('+')
  expect_mode('t1', 'v')
  -- 'x' is an identifier; parent is the binary_expression 'x + 1' on line 2, cols 10..14
  expect_selection('t1 parent of x', { 2, 10, 2, 14 })
end

-- Test 2: pressing + again expands further
do
  feed('+')
  -- Parent of 'x + 1' should be the return_statement covering 'return x + 1'
  expect_selection('t2 expand again', { 2, 3, 2, 14 })
end

-- Test 3: - shrinks back
do
  feed('-')
  expect_selection('t3 shrink', { 2, 10, 2, 14 })
end

-- Test 4: count works
do
  setup_buf({
    'local function foo()',
    '  return x + 1',
    'end',
  })
  vim.api.nvim_win_set_cursor(0, { 2, 9 })
  feed('3+')
  -- After 3 parent climbs from 'x': x -> 'x + 1' -> 'return x + 1' -> function body
  -- Function body in lua-treesitter is the function_declaration's body block; ranges may vary.
  -- Just assert it grew to cover all 3 lines.
  local r = selection_range()
  if r[1] == 1 and r[3] == 3 then
    ok('t4 count=3 covers whole function: ' .. vim.inspect(r))
  else
    fail('t4 count=3 expected to span lines 1..3, got ' .. vim.inspect(r))
  end
end

io.stdout:write(string.format('\n%d failure(s)\n', failures))
if failures > 0 then os.exit(1) end
