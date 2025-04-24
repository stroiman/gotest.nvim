local f = require("gotest.functions")
local output_window = require("gotest.output_window")
local augroup = require("gotest.autogroup")
local test_run = require("gotest.test_run")

local M = {}

M.del_buffer = function()
  if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
    vim.api.nvim_buf_delete(M.buffer, { force = true })
  end
end

function M.create_buffer()
  if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
    return
  end
  M.buffer = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = M.buffer })
  output_window.set_buf(M.buffer)

  vim.keymap.set("n", "<cr>", function()
    local line = vim.api.nvim_get_current_line()
    local pos = f.extract_position_from_line(line)
    if pos then
      vim.cmd("wincmd p")
      vim.cmd.e(pos.filename)
      local lnum = pos.lnum or 1
      local col = pos.col or 1
      vim.fn.setpos(".", { 0, lnum, col, 0 })
    end
  end, { buffer = M.buffer })
end

M.store_test_result = function(data, errors)
  M.create_buffer()

  vim.api.nvim_set_option_value("modifiable", true, { buf = M.buffer })
  vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, {})
  if #errors > 1 then
    vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, { "Stderr:", "" })
    vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, errors)
    vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, { "", "---", "Stdout:", "" })
  end
  vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, data)
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.buffer })
end

--- @type vim.SystemObj | nil
local currentProcess

local killCurrent = function()
  local tmp = currentProcess
  if tmp then
    currentProcess = nil
    tmp:kill(15) -- 15 = TERM signal
  end
end

--- @class AutoRunnerOptions
--- @field aucommand_pattern? string | string[] Will be changed later to have module-specific config.

--- @param opts? AutoRunnerOptions
M.setup = function(opts)
  --- @type string | string[]
  local pattern = "*.go"
  if opts and opts.aucommand_pattern then
    pattern = opts.aucommand_pattern
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    pattern = pattern,
    callback = function()
      local errors = {}
      M.create_buffer()
      local instance = test_run.new_test_run({ output_buf = M.buffer })
      vim.api.nvim_set_option_value("modifiable", true, { buf = M.buffer })
      vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, {})

      killCurrent()
      vim.api.nvim_exec_autocmds("User", {
        pattern = "GoTestStart",
        data = { type = "start" },
      })
      local std_out_buffer = ""
      local std_err_buffer = ""
      currentProcess = vim.system({ "go", "test", "./...", "-test.short", "-json", "-vet=off" }, {
        env = { GOEXPERIMENT = "synctest" },
        text = true,
        stdout = function(err, chunk)
          if not chunk then
            return
          end
          local data = vim.split(chunk, "\n")
          data[1] = std_out_buffer .. data[1]
          std_out_buffer = table.remove(data)
          vim.schedule(function()
            for _, line in ipairs(data) do
              instance:process_line(line)
            end
          end)
        end,
        stderr = function(_, chunk)
          if not chunk then
            return
          end
          local data = vim.split(chunk, "\n")
          data[1] = std_err_buffer .. data[1]
          std_err_buffer = table.remove(data)
          for _, line in ipairs(data) do
            table.insert(errors, line)
          end
        end,
      }, function(out)
        currentProcess = nil
        local exit_code = out.code
        local success = exit_code == 0
        instance:set_success(success)
        vim.schedule(function()
          if #errors > 0 then
            vim.api.nvim_buf_set_lines(M.buffer, 0, 0, false, errors)
          end
          vim.api.nvim_exec_autocmds("user", {
            pattern = "GoTestDone",
            data = {
              type = "done",
              exit_code = exit_code,
              success = success,
            },
          })
        end)
      end)
    end,
  })
end

M.unload = function()
  M.del_buffer()
end

return M
