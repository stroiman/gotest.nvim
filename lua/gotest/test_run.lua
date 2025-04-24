local M = {}

--- OutputBuffer controls a neovim buffer containing test output.
--- @class OutputBuffer
--- @field buf integer
local OutputBuffer = {}

--- @param buf integer Buffer number
function OutputBuffer:new(buf)
  local o = { buf = buf }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @param line string
function OutputBuffer:append(line)
  local buf = self.buf
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

--- TestRun represents a single execution of `go test`
--- @class TestRun
--- @field output OutputBuffer
local TestRun = {}

--- @class TestRunOptions
--- @field output_buf integer

--- Create a new test run
--- @param opt TestRunOptions
--- @return TestRun
function TestRun:new(opt)
  local o = {
    output = OutputBuffer:new(opt.output_buf),
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- Process a single line of output from `go test`
--- @param line string
function TestRun:process_line(line)
  local data = vim.json.decode(line)
  local output = data.Output
  if output then
    local olines = vim.split(output, "\n")
    for i, oline in ipairs(olines) do
      if i < #oline or oline ~= "" then
        if string.find(oline, "ok") ~= 1 and string.find(oline, "?") ~= 1 then
          self.output:append(oline)
        end
      end
    end
  end
end

M.TestRun = TestRun
M.OutputBuffer = OutputBuffer

return M
