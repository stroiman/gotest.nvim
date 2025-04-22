local autogroup = require("gotest.autogroup")

--- @class GoTestOutputWindowSettings
--- @field show? "auto" | "off" | "on"

local M = {}

--- @type GoTestOutputWindowSettings
M.DEFAULT_SETTINGS = {
  show = "auto",
}

--- @type GoTestOutputWindowSettings
local settings = {}

vim.api.nvim_create_autocmd("User", {
  group = autogroup.group_name,
  pattern = { "GoTestDone", "GoTestStart" },
  callback = function(ev)
    local data = ev.data
    if settings.show == "on" then
      M.show_output()
    end
    if settings.show == "auto" then
      if data.type == "done" then
        if data.success then
          M.hide_output()
        else
          M.show_output()
        end
      end
    end
  end,
})

--- Configures output window settings
--- @param opts? GoTestOutputWindowSettings
function M.setup(opts)
  settings = M.DEFAULT_SETTINGS
  if opts then
    settings = vim.tbl_deep_extend("force", settings, opts)
  end
end

--- @param buf integer Buffer containing test output
function M.set_buf(buf)
  M.buf = buf
end

M.show_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    return
  end
  M.win = vim.api.nvim_open_win(M.buf, false, {
    split = "right",
    width = 80,
  })
  vim.wo[M.win].wrap = false
end

M.hide_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
end

return M
