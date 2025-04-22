local M = {}

local create_win_config = function()
  local width = vim.o.columns
  return {
    relative = "editor",
    height = 1,
    row = 0,
    col = width - 0,
    width = 16,
    anchor = "NE",
    focusable = false,
    border = "rounded",
    style = "minimal",
  }
end

--- Opens the status window. Ignored if the window is already open.
M.open_window = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    return
  end
  M.status_buf = vim.api.nvim_create_buf(false, true)
  M.win = vim.api.nvim_open_win(M.status_buf, false, create_win_config())
  vim.wo[M.win].signcolumn = "no"
  vim.wo[M.win].number = false
  M.refresh()
end

M.realign = function()
  if M.win then
    vim.api.nvim_win_set_config(M.win, create_win_config())
  end
end

M.refresh = function()
  if not M.status_buf then
    return
  end
  local status = M.status
  if not status then
    status = "?"
  end
  local lines = { " Tests: " .. status }
  vim.api.nvim_buf_set_lines(M.status_buf, 0, -1, false, lines)
end

M.set_status = function(status)
  M.status = status
  if M.status == "PASS" then
    M.successes = (M.successes or 0) + 1
  elseif M.status == "FAIL" then
    M.successes = 0
  end
  M.refresh()
end

--- Sets the outcome of tests
--- @param success boolean
M.set_success = function(success)
  M.success = success
  if M.success then
    M.set_status("PASS")
  else
    M.set_status("FAIL")
  end
end

-- Close the status window. Ignored if the window is not open
M.close_win = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    vim.api.nvim_buf_delete(M.status_buf, { force = true })
    M.win = nil
    M.status_buf = nil
  end
end

M.unload = function()
  M.close_win()
end

-- M.open_window()
-- vim.keymap.set("n", "<leader>xs", function()
--   M.set_success(true)
-- end)
-- vim.keymap.set("n", "<leader>xf", function()
--   M.set_success(false)
-- end)
-- vim.keymap.set("n", "<leader>xx", function()
--   M.close_win()
-- end)
--
return M
