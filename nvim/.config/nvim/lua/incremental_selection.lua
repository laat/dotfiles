local M = {}

M._stack = {}

function M.reset()
  M._stack = {}
end

function M.expand()
  local node
  if #M._stack == 0 then
    node = vim.treesitter.get_node()
  else
    node = M._stack[#M._stack]:parent()
  end
  if not node then return nil end
  table.insert(M._stack, node)
  return node
end

function M.shrink()
  if #M._stack > 1 then
    table.remove(M._stack)
    return M._stack[#M._stack]
  end

  if #M._stack == 0 then return nil end

  local cur = M._stack[1]
  local cur_sr, cur_sc, cur_er, cur_ec = cur:range()

  -- Find the largest named child strictly contained within current node
  local best = nil
  local best_span = -1
  for child in cur:iter_children() do
    if child:named() then
      local cr, cc, cer, cec = child:range()
      local strictly_contained = (cr > cur_sr or (cr == cur_sr and cc > cur_sc))
        or (cer < cur_er or (cer == cur_er and cec < cur_ec))
      if strictly_contained then
        local span = (cer - cr) * 100000 + (cec - cc)
        if span > best_span then
          best = child
          best_span = span
        end
      end
    end
  end

  if not best then return nil end
  M._stack[1] = best
  return best
end

function M.select_node(node)
  if not node then return end
  local sr, sc, er, ec = node:range()
  vim.fn.setpos("'<", { 0, sr + 1, sc + 1, 0 })
  vim.fn.setpos("'>", { 0, er + 1, ec, 0 })
  vim.cmd('normal! gv')
end

return M
