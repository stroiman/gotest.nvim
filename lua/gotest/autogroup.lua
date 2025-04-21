-- Add a uuid to the group name, should guarantee no conflicts with other groups
--
local create_group = function()
  return vim.api.nvim_create_augroup("go-autotest-fee42c62-0e06-11f0-9e7f-06888228c6fb", { clear = true })
end

local M = {
  group = create_group(),
}

M.get_group = function()
  return M.group
end

--- "Unload" all autocommands by recreating the autogroup
M.unload = function()
  M.group = create_group()
end

return M
