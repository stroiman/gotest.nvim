local M = {}

M.extract_position_from_line = function(input)
  local filename, lnum, col = input:match([[%s*([%w_/]*.go):(%d*):?(%d*)]])
  if filename then
    return { filename = filename, lnum = lnum, col = col }
  else
    return nil
  end
end

return M
