vim.api.nvim_create_augroup("stroiman_go_autorun", { clear = true })
local grp = vim.api.nvim_create_augroup("stroiman-go-autorun", { clear = true })

local ns = vim.api.nvim_create_namespace("stroiman-go-autotest")

local function find_test_line(bufnr, entry)
  P("Find line")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local parts = vim.split(entry.Test, "/")
  local test = parts[#parts]
  -- local pattern = string.format("func.*\\W%s\\W", test)
  local r = vim.regex(test)

  for i, l in ipairs(lines) do
    if r:match_str(l) then
      return i
    end
  end
  P("Line not found")
end

local function make_key(entry)
  assert(entry.Package, "Must have Package:" .. vim.inspect(entry))
  assert(entry.Test, "Must have Test:" .. vim.inspect(entry))
  return string.format("%s/%s", entry.Package, entry.Test)
end

local function add_golang_test(state, entry)
  local test = {
    name = entry.Test,
    line = find_test_line(state.bufnr, entry),
    output = {},
  }
  state.tests[make_key(entry)] = test
  state.test = test
end

local function add_golang_output(state, entry)
  assert(state.tests, vim.inspect(state))
  table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
end

local function mark_succss(state, entry)
  state.tests[make_key(entry)].success = entry.Action == "pass"
end

local attach_to_buffer = function(bufnr, command)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = grp,
    pattern = "*.go",
    callback = function()
      vim.cmd([[messages clear]])
      local state = {
        bufnr = bufnr,
        test = {},
        tests = {},
      }
      local append_data = function(_, data)
        if not data then -- data could be nil
          return
        end
        for _, line in ipairs(data) do
          local decoded
          pcall(function()
            decoded = vim.json.decode(line)
          end)
          if not decoded then
            return
          end
          if decoded.Action == "run" then
            P("Run")
            add_golang_test(state, decoded)
            P(state.test)
          elseif decoded.Action == "output" then
            -- if not decoded.Test then
            --   return
            -- end
            -- add_golang_output(state, decoded)
          elseif decoded.Action == "pass" or decoded.Action == "fail" then
            if decoded.Test then
              mark_succss(state, decoded)
              local test = state.test
              P({
                Msg = "Print?",
                Test = test,
                Buf = bufnr,
              })
              if test.success then
                local text = { "✓" }
                line = test.line
                if line then
                  vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, 0, { virt_text = { text } })
                end
              end
            end
          elseif
            decoded.Action == "skip"
            or decoded.Action == "pause"
            or decoded.Action == "cont"
            or decoded.Action == "start"
          then
            -- Do nothing
          else
            error("Failed to handle" .. vim.inspect(line))
          end
        end
      end
      -- vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
      vim.fn.jobstart(
        command,
        -- What do we do with the output
        {
          stdout_buffered = true, -- One output line at a time
          on_stdout = append_data,
          on_stderr = function() end,

          -- on_exit = function()
          --   local failed = {}
          --   for _, test in pairs(state.tests) do
          --     if test.line then
          --       if not test.success then
          --         table.insert(failed, {
          --           bufnr = bufnr,
          --           lnum = test.line,
          --           col = 0,
          --           severity = vim.diagnistic.severity.ERROR,
          --           source = "go-test",
          --           message = "Test Failed",
          --           user_data = {},
          --         })
          --       end
          --     end
          --   end
          --
          --   vim.diagnostic.set(ns, bufnr, failed, {})
          -- end,
        }
      )
    end,
  })
end

-- attach_to_buffer(23, { "go", "test", "./...", "-json", "-vet=off" })

vim.api.nvim_create_user_command("Got", function()
  local bufnr = vim.api.nvim_get_current_buf()
  attach_to_buffer(bufnr, { "go", "test", "./...", "-json", "-vet=off" })
end, {})
