--- @class TestRunMod
--- @field last_run TestRun
local M = {}

--- @class TestID
--- @field package string
--- @field test_name string
local TestID = {}

--- @param package string
--- @param test string
function TestID:new(package, test)
  local o = { package = package, test_name = test }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- Generate a string that can be used as a dictionary key.
--- @return string
function TestID:key()
  return self.package .. ":" .. self.test_name
end

--- @class Test
--- @field id TestID
--- @field output string[]
local Test = {}

function Test:new(id)
  local o = { id = id }
  setmetatable(o, self)
  self.__index = self
  return o
end

--- @return string
function Test:key()
  return self.id:key()
end

--- Process the JSON output returned by `go test -json`
--- @return string[] | nil
function Test:process_json(data)
  local action = data.Action
  if action == "pass" then
    self.result = "pass"
    return nil
  end
  if action == "fail" then
    self.result = "fail"
    return self.output
  end
  if action == "output" then
    if not self.output then
      self.output = {}
    end
    local lines = vim.split(data.Output, "\n")
    for i, line in ipairs(lines) do
      if i < #lines or line ~= "" then
        -- Output seems to always end with \n, but let's just actively check for
        -- an empty line, rather than indiscriminately remove the last element.
        table.insert(self.output, line)
      end
    end
  end
  return nil
end

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

--- @param lines string[]
function OutputBuffer:append(lines)
  local buf = self.buf
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

--- TestRun represents a single execution of `go test`
--- @class TestRun
--- @field output OutputBuffer
--- @field debug_raw_buf? integer A buffer containing the `raw go` test json
--- @field result "pass" | "fail"
local TestRun = {
  debug_raw = {},
  --- @type {[string]: Test}
  tests = {},
}

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

--- Gets the test with specified name in specified package. If the name is not
--- recognised, create a new instance.
--- @param package string Package name
--- @param test string Test name
--- @return Test
function TestRun:get_test(package, test)
  local id = TestID:new(package, test)
  local key = id:key()
  local result = self.tests[key]
  if not result then
    result = Test:new(id)
    self.tests[key] = result
  end
  return result
end

--- Process a single line of output from `go test`
--- @param line string
function TestRun:process_line(line)
  table.insert(self.debug_raw, line)
  local data = vim.json.decode(line)
  local package_name = data.Package
  local test_name = data.Test
  if not package_name or not test_name then
    return
  end
  local test = self:get_test(package_name, test_name)
  local res = test:process_json(data)
  if res then
    self.output:append(res)
  end

  -- return
  -- local output = data.Output
  -- if output then
  --   local olines = vim.split(output, "\n")
  --   for i, oline in ipairs(olines) do
  --     if i < #oline or oline ~= "" then
  --       if string.find(oline, "ok") ~= 1 and string.find(oline, "?") ~= 1 then
  --         self.output:append({oline})
  --       end
  --     end
  --   end
  -- end
end

function TestRun:debug_show_raw()
  local buf = self.debug_raw_buf
  if not buf then
    buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, self.debug_raw)
  end
  M.win = vim.api.nvim_open_win(buf, false, {
    split = "right",
    win = -1,
    width = 80,
  })
end

M.TestRun = TestRun
M.OutputBuffer = OutputBuffer

--- @param opts TestRunOptions
function M.new_test_run(opts)
  M.last_run = TestRun:new(opts)
  return M.last_run
end

--- Shows the raw JSON output in a new window. Not intended for normal use.
--- This is intended as a help when developing the plugin.
--- No compatibility guarantees for this function.
function M.debug_raw()
  if M.last_run then
    M.last_run:debug_show_raw()
  end
end

return M
