--- Gotest module
-- @module M
--

-- Unload existing code from cache. This is used when developing the modules, I
-- can just resource this file, and it will stop the current plugin, reload new
-- changed files, and rerun the setup function with the same configuration.
local old_version = package.loaded["gotest"]
local auto_setup = nil
if old_version and type(old_version) == "table" then
  auto_setup = old_version.settings
  old_version.unload()
  for name, _ in pairs(package.loaded) do
    if name:match("^gotest.") then
      package.loaded[name] = nil
    end
  end
end

local M = {}

local augroup = require("gotest.autogroup")
vim.api.nvim_create_augroup(augroup, { clear = true })

local autorunner = require("gotest.autorunner")
local analyzer = require("gotest.analyzer")
local status_window = require("gotest.status_window")
local output_window = require("gotest.output_window")
local test_run = require("gotest.test_run")
---
--- @class GoTestSettings
--- @field aucommand_pattern string | string[]
local DEFAULT_SETTINGS = {
  output_window = output_window.DEFAULT_SETTINGS,
  --- Name for a user command to create. Defaults to "Got", i.e., you can
  --- trigger commands like `:Got start`, `:Got stop`, etc. Set to `nil` to not
  --- create a user command.
  --- @type string | nil
  user_command = "Got",
}

local commands = {
  Start = function()
    M.start()
  end,
  Stop = function()
    M.unload()
  end,
  OutputShow = function()
    output_window.show_output()
  end,
  ShowLast = function()
    test_run.debug_raw()
  end,
}

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
  M.settings = settings
  -- local default_options = {
  --   analyzer = {
  --     enabled = false,
  --   },
  -- }
  -- if opts.analyzer and opts.analyzer.enabled then
  --   analyzer.setup()
  -- end
  autorunner.setup({ aucommand_pattern = settings.aucommand_pattern })
  output_window.setup(settings.output_window)

  vim.api.nvim_create_user_command(settings.user_command, function(args)
    local command = commands[args.args]
    if command then
      command()
    end
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
    -- ignore error, command already deleted
    pcall(vim.api.nvim_del_user_command, settings.user_command)
  end
  status_window.unload()
  autorunner.unload()
  analyzer.unload()
end

if auto_setup then
  -- This is for the special case that this plugin file is executed straight
  -- from within neovim, to support a faster feedback cycle.
  M.setup(auto_setup)

  -- Replace the setup function, so any code that has loaded the old version
  -- will reference the new.
  old_version.setup = M.setup
end

--- @return "pass" | "fail" | "running" | nil
M.status = function()
  local last_run = test_run.last_run
  if not last_run then
    return nil
  end
  return last_run.status
end

return M
