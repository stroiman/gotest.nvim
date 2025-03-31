local autogroup = require("gotest.autogroup")
local autorunner = require("gotest.autorunner")
local analyzer = require("gotest.analyzer")
local status_window = require("gotest.status_window")

local M = {}

--- Configures gotest. Currently doesn't actually do anything
M.setup = function(opts)
  print("Setup gotest")
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

return M
