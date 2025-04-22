-- Add a uuid to the group name, should guarantee no conflicts with other groups

local group_name = "go-autotest-fee42c62-0e06-11f0-9e7f-06888228c6fb"
local group_id = vim.api.nvim_create_augroup(group_name, { clear = true })

local M = {
  group = group_id,
  group_name = group_name,
}

M.get_group = function()
  return M.group
end

M.unload = function()
  vim.api.nvim_create_augroup(group_name, { clear = true })
end

return M
