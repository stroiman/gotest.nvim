local augroup = require("gotest.autogroup")

--- @class GoTestOutputWindowSettings
--- @field show? "auto" | "off" | "on"
--- @field win_config? vim.api.keyset.win_config

local M = {}

--- @type GoTestOutputWindowSettings
M.DEFAULT_SETTINGS = {
  show = "auto",
  win_config = {
    split = "right",
    win = -1,
    width = 80,
  },
}

--- @type GoTestOutputWindowSettings
local settings = {}
local last_success = true

vim.api.nvim_create_autocmd("User", {
  group = augroup,
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
        end
        if last_success and not data.success then
          M.show_output()
        end
        last_success = data.success
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
  M.win = vim.api.nvim_open_win(M.buf, false, settings.win_config)
  vim.wo[M.win].wrap = false
end

M.hide_output = function()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
end

return M
