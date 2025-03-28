local M = {}

local create_win_config = function()
  local width = vim.o.columns
  return {
    relative = "editor",
    height = 2,
    row = 1,
    col = width - 1,
    width = 16,
    anchor = "NE",
    focusable = false,
    border = "rounded",
    style = "minimal",
  }
end

--- Opens the status window. Ignored if the window is already open.
M.open_window = function()
  if M.winid then
    return
  end
  M.status_buf = vim.api.nvim_create_buf(false, true)
  M.winid = vim.api.nvim_open_win(M.status_buf, false, create_win_config())
  vim.wo[M.winid].signcolumn = "no"
  vim.wo[M.winid].number = false
  M.refresh()
end

M.realign = function()
  if M.winid then
    vim.api.nvim_win_set_config(M.winid, create_win_config())
  end
end

M.refresh = function()
  if not M.status_buf then
    return
  end
  local lines = { "Status: ?" }
  if M.success ~= nil then
    if M.success then
      lines = { "Status: OK", "Count: " .. M.successes }
    else
      lines = { "Status: FAILED" }
    end
  end
  vim.api.nvim_buf_set_lines(M.status_buf, 0, -1, false, lines)
end

--- Sets the outcome of tests
--- @param success boolean
M.set_success = function(success)
  M.success = success
  if M.success then
    M.successes = (M.successes or 0) + 1
  else
    M.successes = 0
  end
  M.refresh()
end

-- Close the status window. Ignored if the window is not open
M.close_win = function()
  if not M.winid then
    return
  end
  vim.api.nvim_win_close(M.winid, true)
  vim.api.nvim_buf_delete(M.status_buf, { force = true })
  M.winid = nil
  M.status_buf = nil
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
