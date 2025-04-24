package.loaded["gotest.functions"] = nil
local f = require("gotest.functions")

local test_extract_filename = function()
  -- Example of a compile error emitted
  -- local example = "    /internal/v1.2.3/features/auth/authrouter/login_test.go:41:15: undefined: foo.Bar"
  local example = "            	/Users/peter/go/pkg/mod/github.com/stretchr/testify@v1.10.0/suite/suite.go:188 +0x22c "
  local bad = "internal/features/auth/authrouter/login_test.go:41: undefined: foo.Bar"

  local data = f.extract_position_from_line(example)
  if data then
    print("Filename: ", data.filename)
    print("Line: ", data.lnum)
    print("Col: ", data.col)
  else
    print("NIL")
  end
end

test_extract_filename()
