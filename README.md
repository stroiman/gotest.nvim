# gotest.nvim - immediate test feedback in neovim

Automatically run unit tests, and get visible feedback in neovim whenever you
save a file.

Get status in lualine (manual setup instructions included here)

> [!WARNING]
> This plugin is a VERY EARLY prototype, but it seems to work ... Don't expect
> backwards compatibility either.

Whenever you save a `*.go` file, the plugin executes `go test` in the current
working directory, showing any failed tests automatically.

<img width="1895" alt="screenshot of a new window in neovim with test results showing, and lualine updated" src="https://github.com/user-attachments/assets/1d780d09-c735-4465-816a-1e7e69a75623" />

Failed tests or compilations will open an window showing output. Pressing `<cr>`
will quickly jump to the source code for

- Build errors
- Panic stack traces

Making this work for test errors reported by `t.Error()` and friends is next
priority.

## Hardcoded settings

These settings are hardcoded, but will of course be made customizable:

- Environment vairables has `GOEXPERIMENT=synctest`
- `go test` has the `-vet=off`. I want the fastest possible feedback, and leave
  it to build servers to perform thorough static code analysis.


## Getting started.

Install the plugin, `stroiman/gotest.nvim` using your favourite plugin manager. 

Call `setup` to get started.

```lua
local gotest = require("gotest")

-- These are the default values, so not really necessary.
gotest.setup({
  aucommand_pattern = { "*.go" },
  output_window = {
    show = "auto",
  },
})
```

There are 3 values for `show`, 

- `auto` opens the output window when status changes from `pass` to `fail`.
- `on` opens the output window when test run starts
- `off` nothing happens.

You can manually show the output window using `:Got OutputShow`

### Integration with lualine.

To integrate test status with lualine, you need to do two things:

- Install a function in lualine that retrieves the test status
- Call `lualine.refresh()` when test output updates.

#### Creating a lualing function

You just need to have a function that returns a string. `gotest.status()`
returns either `"running"`, `"pass"`, or `"fail"`. Before any test has executed,
it will return `nil`.

```lua
local gotest = require("gotest")
local lualine = require("lualine")

lualine.setup({
  sections = {
    lualine_a = { 
      "mode",
      function()
        -- res is nil before any tests have executed.
        local res = gotest.status()
        if res then
          return res
        end
        return "..."
      end,
    },
    -- ...
  }
})
```

#### Refresh lualine on test results

Gotest executes a few `User` auto commands when tests start/stop. We can react
to `"GoTestStart"` and `"GoTestDone"` to tell lualine to refresh.

```lua
local grp = vim.api.nvim_create_augroup("gotest_lualine", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = grp,
  pattern = { "GoTestDone", "GoTestStart" },
  callback = function()
    lualine.refresh()
  end,
})
```

## Future features

- Navigate to source code from failed assertions (i.e., `t.Error()` and friends)
- Overview of test suite
- Customize test packages to run, or select individual tests
- Rerun only failed tests until they pass
- Customize go test options and environment.
- Customize configuration pr. module

The plugin does perform a go package dependency analysis, 
Support other automatic tasks, e.g., trigger code generation, such as mock
generators. 

Codegen could also trigger running tests. This plugin reacts to neovim events,
so any files updated on the file systems will not be detected to rerun tests
automatically.

## Why not neotest

Neotest is a general neovim test runner plugin with watch mode, supporting
multiple languages through adaters. Two adapters, exist for Go, `neotest-go` and
`neotest-golang`, but the watch mode did not work reliably no matter the
configuration.

The watch mode is an _essential_ feature for me. All bells and whistles are
irrelevant if watch mode doesn't work.

This plugin _always_ runs on file save, and _should_ always provide feedback.

## Issues

There is one potential issue that I am aware of, though not an issue in my
normal workflow.

If neovim's working folder is modified, the wrong set of tests are executed.
