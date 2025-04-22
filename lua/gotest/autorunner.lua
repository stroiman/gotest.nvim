local status_window = require("gotest.status_window")
local autogroup = require("gotest.autogroup")
local f = require("gotest.functions")

M = {}

local create_buffer = function()
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  return buf
end

M.del_buffer = function()
  if M.buffer and vim.api.nvim_buf_is_valid(M.buffer) then
    vim.api.nvim_buf_delete(M.buffer, { force = true })
  end
end

M.hide_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
end

local init_buffer = function(buffer)
  vim.keymap.set("n", "<cr>", function()
    local line = vim.api.nvim_get_current_line()
    local pos = f.extract_position_from_line(line)
    if pos then
      vim.cmd("wincmd p")
      vim.cmd.e(pos.filename)
      local lnum = pos.lnum or 1
      local col = pos.col or 1
      vim.fn.setpos(".", { 0, lnum, col, 0 })
      -- vim.api.nvim_set_current_win
    end
  end, { buffer = buffer })
end

M.show_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    return
  end
  init_buffer(M.buffer)
  M.win = vim.api.nvim_open_win(M.buffer, false, {
    split = "right",
    width = 80,
  })
  vim.wo[M.win].wrap = false
end

vim.api.nvim_create_autocmd("User", {
  pattern = "GoTestDone",
  callback = function(ev)
    local success = ev.data.success
    if success then
      status_window.set_status("PASS")
      M.hide_output()
    else
      status_window.set_status("FAIL")
      M.show_output()
    end
  end,
})

M.store_test_result = function(data, errors)
  if not M.buffer then
    M.buffer = create_buffer()
  end

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
      if not M.buffer then
        M.buffer = create_buffer()
      end
      vim.api.nvim_set_option_value("modifiable", true, { buf = M.buffer })
      vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, {})

      vim.cmd([[messages clear]])
      vim.api.nvim_exec_autocmds("user", { pattern = "GoTestStart" })
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
  M.hide_output()
  M.del_buffer()
  autogroup.unload()
end

return M
