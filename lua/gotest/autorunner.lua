local status_window = require("gotest.status_window")
local f = require("gotest.functions")

M = {}

M.hide_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
end

M.show_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    return
  end
  M.win = vim.api.nvim_open_win(M.buffer, false, {
    split = "right",
    width = 80,
  })
  vim.wo[M.win].wrap = false
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

M.store_test_result = function(data, errors)
  if not M.buffer then
    M.buffer = vim.api.nvim_create_buf(false, true)
    init_buffer(M.buffer)
  end
  vim.api.nvim_buf_set_lines(M.buffer, 0, -1, false, {})
  if #errors > 1 then
    vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, { "Stderr:", "" })
    vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, errors)
    vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, { "", "---", "Stdout:", "" })
  end
  vim.api.nvim_buf_set_lines(M.buffer, -1, -1, false, data)
end

local grp = vim.api.nvim_create_augroup("stroiman-go-autorun-2", { clear = true })

vim.api.nvim_create_autocmd("VimResized", {
  group = grp,
  callback = function()
    status_window.realign()
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = grp,
  pattern = "*.go",
  callback = function()
    local output = {}
    local errors = {}
    vim.cmd([[messages clear]])
    status_window.set_status("RUNNING")
    vim.fn.jobstart({ "go", "test", "./...", "-vet=off" }, {
      env = { GOEXPERIMENT = "synctest" },
      stdout_buffered = true, -- One output line at a time
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if string.find(line, "ok") ~= 1 and string.find(line, "?") ~= 1 then
            table.insert(output, line)
          end
        end
      end,
      on_stderr = function(_, data)
        for _, line in ipairs(data) do
          table.insert(errors, line)
        end
      end,
      on_exit = function(job_id, exit_code)
        status_window.open_window()
        M.store_test_result(output, errors)
        if exit_code == 0 then
          status_window.set_status("PASS")
          M.hide_output()
        else
          status_window.set_status("FAIL")
          M.show_output()
        end
      end,
    })
  end,
})
vim.keymap.set("n", "<leader>xx", function()
  status_window.close_win()
end)
