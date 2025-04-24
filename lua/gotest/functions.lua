local M = {}

--- @class PositionInformation
--- @field filename string
--- @field lnum integer
--- @field col? integer

--- Extract file, line no, and possibly position from line
--- @param input string
--- @return PositionInformation | nil
M.extract_position_from_line = function(input)
  local filename, lnum, col = input:match([[^%s*([%w_/\.@]*.go):(%d*):?(%d*)]])
  if filename then
    return { filename = filename, lnum = lnum, col = col }
  else
    return nil
  end
end

return M
