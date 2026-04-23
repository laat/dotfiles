local sel = require('incremental_selection')

local function setup_buf(lines, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = filetype
  vim.treesitter.start(buf, filetype)
  -- Wait for parser to be ready
  vim.treesitter.get_parser(buf, filetype):parse()
  return buf
end

local function node_range(node)
  if not node then return nil end
  local sr, sc, er, ec = node:range()
  return { sr, sc, er, ec }
end

local function assert_eq(actual, expected, msg)
  local ok = true
  if type(actual) == 'table' and type(expected) == 'table' then
    for i = 1, math.max(#actual, #expected) do
      if actual[i] ~= expected[i] then ok = false end
    end
  else
    ok = actual == expected
  end
  if not ok then
    local fmt = function(v)
      if type(v) == 'table' then return '{' .. table.concat(v, ', ') .. '}' end
      return tostring(v)
    end
    error(string.format('FAIL: %s\n  expected: %s\n  actual:   %s', msg or '', fmt(expected), fmt(actual)))
  end
end

local passed = 0
local failed = 0

local function test(name, fn)
  sel.reset()
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print('  PASS: ' .. name)
  else
    failed = failed + 1
    print('  FAIL: ' .. name)
    print('    ' .. err)
  end
end

print('=== Incremental Selection Tests ===')

-- JSON: { "name": "hello world" }
local json_lines = {
  '{',
  '  "name": "hello world"',
  '}',
}
local buf = setup_buf(json_lines, 'json')

test('expand from string_content selects string (with quotes)', function()
  -- Place cursor on "hello world" content (row 1, col 11 = 'h' in hello)
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  local node = sel.expand()
  assert_eq(node:type(), 'string_content', 'first expand should be string_content')
  -- Expand again to get string with quotes
  node = sel.expand()
  assert_eq(node:type(), 'string', 'second expand should be string')
  assert_eq(node_range(node), { 1, 10, 1, 23 }, 'string range includes quotes')
end)

test('expand then shrink returns to previous node', function()
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  sel.expand() -- string_content
  sel.expand() -- string
  sel.expand() -- pair
  local node = sel.shrink() -- back to string
  assert_eq(node:type(), 'string', 'shrink from pair should go to string')
  node = sel.shrink() -- back to string_content
  assert_eq(node:type(), 'string_content', 'shrink from string should go to string_content')
end)

test('shrink with no stack history goes to named child', function()
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  sel.expand() -- string_content
  sel.expand() -- string
  -- Now shrink twice to exhaust stack, then shrink further
  sel.shrink() -- back to string_content (pop)
  local node = sel.shrink() -- no stack, should find named child of string_content
  -- string_content has no named children, so should return nil
  assert_eq(node, nil, 'string_content has no named children to shrink to')
end)

test('shrink from string node finds string_content', function()
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  -- Manually push just the string node
  local ts_node = vim.treesitter.get_node() -- string_content
  local string_node = ts_node:parent() -- string
  sel._stack = { string_node }
  local node = sel.shrink()
  assert_eq(node:type(), 'string_content', 'shrink from string should find string_content')
  assert_eq(node_range(node), { 1, 11, 1, 22 }, 'string_content excludes quotes')
end)

test('shrink from pair finds largest child', function()
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  local ts_node = vim.treesitter.get_node() -- string_content
  local pair_node = ts_node:parent():parent() -- pair
  sel._stack = { pair_node }
  local node = sel.shrink()
  -- pair has two named children: string "name" and string "hello world"
  -- "hello world" is larger
  assert_eq(node:type(), 'string', 'shrink from pair should find a string child')
  assert_eq(node_range(node), { 1, 10, 1, 23 }, 'should pick the larger string')
end)

test('shrink at leaf returns nil', function()
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  local ts_node = vim.treesitter.get_node() -- string_content
  sel._stack = { ts_node }
  local node = sel.shrink()
  assert_eq(node, nil, 'leaf node has no named children')
end)

test('full cycle: expand expand expand shrink shrink shrink', function()
  vim.api.nvim_win_set_cursor(0, { 2, 11 })
  local n1 = sel.expand() -- string_content
  local n2 = sel.expand() -- string
  local n3 = sel.expand() -- pair
  assert_eq(n1:type(), 'string_content')
  assert_eq(n2:type(), 'string')
  assert_eq(n3:type(), 'pair')
  local s1 = sel.shrink() -- string
  local s2 = sel.shrink() -- string_content
  assert_eq(s1:type(), 'string', 'first shrink')
  assert_eq(s2:type(), 'string_content', 'second shrink')
end)

vim.api.nvim_buf_delete(buf, { force = true })

print(string.format('\n=== Results: %d passed, %d failed ===', passed, failed))
if failed > 0 then
  vim.cmd('cquit! 1')
end
