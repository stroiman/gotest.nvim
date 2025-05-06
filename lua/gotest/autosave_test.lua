local path = debug.getinfo(1).source:match("@?(.*/)")
local f = io.open(path .. "/test_data/registrator_test.go", "r")
local output = io.open(path .. "/test_data/test_output", "r")
if not f or not output then
  return
end

local data = f:read("*a")
local test_data = vim.split(data, "\n")
local output_lines = vim.split(output:read("*a"), "\n")

local function make_key(entry)
  assert(entry.Package, "Must have Package:" .. vim.inspect(entry))
  assert(entry.Test, "Must have Test:" .. vim.inspect(entry))
  return string.format("%s/%s", entry.Package, entry.Test)
end

local actions = {
  start = function() end,
  run = function(state, event)
    state.tests[make_key(event)] = {
      package = event.Package,
      test = event.Test,
      output = {},
    }
  end,
  pause = function() end,
  cont = function() end,
  pass = function(state, event)
    state.tests[make_key(event)].status = "success"
  end,
  bench = function() end,
  fail = function(state, event)
    state.tests[make_key(event)].status = "fail"
  end,
  output = function(state, event)
    local test = state.tests[make_key(event)]
    if not test then
      return
    end
    table.insert(test.output, vim.trim(event.Output))
  end,
  skip = function(state, event)
    state.tests[make_key(event)].status = "skipped"
  end,
}

local M = {
  state = { tests = {} },
}
M.process_line = function(self, line)
  local ok, record = pcall(vim.json.decode, line)
  if not ok or not record or not record.Test then
    return
  end
  local action = actions[record.Action]
  action(self.state, record)
end

--- Gets diagnostics messages for a buffer
--- @return vim.diagnostic.Opts
M.diag_lines = function(self)
  local result = {}
  for _, entry in pairs(self.state.tests) do
    local parts = vim.split(entry.test, "/")
    local test = parts[#parts]
    local r = vim.regex(test)
    local diag = {
      bufnr = 0,
      lnum = 0,
      col = 0,
      severity = vim.diagnostic.severity.ERROR,
      source = "go-test",
      message = "Test error",
      user_data = {},
    }
    table.insert(result, diag)
  end
  return result
end

vim.cmd([[messages clear]])
for _, line in ipairs(output_lines) do
  M:process_line(line)
end

local diags = M:diag_lines(test_data)

vim.keymap.set("n", "<leader>xx", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local r = vim.regex("func.*\\WTestValidLogin\\W")
  for i, l in ipairs(lines) do
    if r:match_str(l) then
    end
  end
end)
