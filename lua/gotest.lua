local autogroup = require("gotest.autogroup")
local autorunner = require("gotest.autorunner")
local analyzer = require("gotest.analyzer")
local status_window = require("gotest.status_window")

local M = {}

--- @class GoTestStatusWindowSettings
--- @field show? "auto" | "off" | "on"

--- @class GoTestSettings
--- @field status_window? GoTestStatusWindowSettings

--- @type GoTestSettings
local DEFAULT_SETTINGS = {
  status_window = {
    show = "auto",
  },
}

--- Configures gotest.
--- @param opts GoTestSettings Module overrides
M.setup = function(opts)
  M.current = DEFAULT_SETTINGS
  if opts then
    M.current = vim.tbl_deep_extend("force", M.current, opts)
  end
  -- local default_options = {
  --   analyzer = {
  --     enabled = false,
  --   },
  -- }
  -- if opts.analyzer and opts.analyzer.enabled then
  --   analyzer.setup()
  -- end
  autorunner.setup()
end

M.start = function() end

--- Cleans up resources, e.g., removes autocommands.
-- This function primarily serves a purpose for it's own development, to allow
-- reloading the module without having to restart neovim. Client code _may_ find
-- it useful too in the current state of the plugin that doesn't allow for _any_
-- customization.
M.unload = function()
  autogroup.unload()
  status_window.unload()
  autorunner.unload()
  analyzer.unload()
end

vim.api.nvim_create_user_command("GotestStart", function()
  M.start()
end, {})

vim.api.nvim_create_user_command("GotestStop", function()
  M.unload()
end, {})

return M
