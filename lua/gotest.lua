--- Gotest module
-- @module M

local augroup = require("gotest.autogroup")
vim.api.nvim_create_augroup(augroup, { clear = true })

local autorunner = require("gotest.autorunner")
local analyzer = require("gotest.analyzer")
local status_window = require("gotest.status_window")
local output_window = require("gotest.output_window")
---
--- @class GoTestSettings
local DEFAULT_SETTINGS = {
  output_window = output_window.DEFAULT_SETTINGS,
  --- Name for a user command to create. Defaults to "Got", i.e., you can
  --- trigger commands like `:Got start`, `:Got stop`, etc. Set to `nil` to not
  --- create a user command.
  --- @type string | nil
  user_command = "Got",
}

local commands = {
  start = function()
    P("Start")
  end,
  stop = function()
    P("Stop")
  end,
}

local M = {}

--- Current configuration settings
--- @type GoTestSettings
local settings = DEFAULT_SETTINGS

--- Configures gotest.
--- @param opts? GoTestSettings Module overrides
M.setup = function(opts)
  settings = DEFAULT_SETTINGS
  if opts then
    settings = vim.tbl_deep_extend("force", settings, opts)
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
  output_window.setup(settings.output_window)

  vim.api.nvim_create_user_command(settings.user_command, function(args)
    P(args)
  end, {
    complete = function(args)
      local res = {}
      for k, _ in pairs(commands) do
        table.insert(res, k)
      end
      return res
    end,
    nargs = 1,
  })
end

M.start = function() end

--- Cleans up resources, e.g., removes autocommands.
-- This function primarily serves a purpose for it's own development, to allow
-- reloading the module without having to restart neovim. Client code _may_ find
-- it useful too in the current state of the plugin that doesn't allow for _any_
-- customization.
M.unload = function()
  if settings.user_command then
    pcall(vim.api.nvim_del_user_command, settings.user_command)
  end
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
