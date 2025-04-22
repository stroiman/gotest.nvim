local status_window = require("gotest.status_window")
local autogroup = require("gotest.autogroup")
local f = require("gotest.functions")
local output_window = require("gotest.output_window")

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

vim.keymap.set("n", "<leader>xx", function()
  status_window.close_win()
end)

M.setup = function()
  vim.api.nvim_create_autocmd("VimResized", {
    group = autogroup.group,
    callback = function()
      status_window.realign()
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = autogroup.group_name,
    pattern = "*.go",
    callback = function()
      local errors = {}
      M.create_buffer()
      vim.api.nvim_set_option_value("modifiable", true, { buf = M.buffer })
      vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, {})

      vim.cmd([[messages clear]])
      vim.api.nvim_exec_autocmds("User", {
        pattern = "GoTestStart",
        data = { type = "start" },
      })
      status_window.set_status("RUNNING")
      local std_out_buffer = ""
      local std_err_buffer = ""
      vim.system({ "go", "test", "./...", "-test.short", "-vet=off" }, {
        env = { GOEXPERIMENT = "synctest" },
        text = true,
        stdout = function(err, chunk)
          if not chunk then
            return
          end
          local data = vim.split(chunk, "\n")
          data[1] = std_out_buffer .. data[1]
          std_out_buffer = table.remove(data)
          local output = {}
          for _, line in ipairs(data) do
            if string.find(line, "ok") ~= 1 and string.find(line, "?") ~= 1 then
              table.insert(output, line)
            end
          end
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, output)
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
        local exit_code = out.code
        if #errors > 0 then
          vim.schedule(function()
            vim.api.nvim_buf_set_lines(M.buffer, 0, 0, false, errors)
            status_window.open_window()
            vim.api.nvim_exec_autocmds("user", {
              pattern = "GoTestDone",
              data = {
                type = "done",
                exit_code = exit_code,
                success = exit_code == 0,
              },
            })
          end)
        end
      end)
    end,
  })
end

M.unload = function()
  M.del_buffer()
end

return M
