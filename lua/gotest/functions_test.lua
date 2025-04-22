local f = require("gotest.functions")

local test_extract_filename = function()
  -- Example of a compile error emitted
  local example = "internal/features/auth/authrouter/login_test.go:41:15: undefined: foo.Bar"
  local bad = "internal/features/auth/authrouter/login_test.go:41: undefined: foo.Bar"

  local filename, line, col = example:match([[([%w_/]*.go):(%d*):(%d*)]])
  print("Filename: ", filename)
  print("Line: ", line)
  print("Col: ", col)
end

test_extract_filename()
