local autogroup = require("gotest.autogroup")
local autorunner = require("gotest.autorunner")

local M = {}

--- Configures gotest. Currently doesn't actually do anything
M.setup = function() end

--- Cleans up resources, e.g., removes autocommands.
-- This function primarily serves a purpose for it's own development, to allow
-- reloading the module without having to restart neovim. Client code _may_ find
-- it useful too in the current state of the plugin that doesn't allow for _any_
-- customization.
M.unload = function()
  autogroup.unload()
end

return M
