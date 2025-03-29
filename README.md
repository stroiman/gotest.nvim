# gotest.nvim - immediate test feedback in neovim

> [!WARNING]
> This plugin is a VERY EARLY prototype. But it works.

Whenever you save a `*.go` file, the plugin executes `go test ./... -vet=off` in
the current working directory, and notifies of the outcome. 

If the test result in an error, which can also be due to build errors, a new
window opens (split right, width 80 cols), displaying both stderr and stdout of
the test run.

<img width="1728" alt="Test feedback" src="https://github.com/user-attachments/assets/c24efa46-4ee4-46be-8583-63f782616453" />

Pressing `<cr>` when the cursor is on a line with a filename and path will open
the file in the _previous window_, and move the cursor to the indicated
position.

This behaviour works for build errors, and panic stack traces. Test errors
reported by `t.Error()` and friends don't _yet_ work, as the line doesn't have a
path. This [_will come_](#navigating-to-test-errors)

`-vet=off` is a personal preference as the goal is the fastest possible
feedback during normal development; and let the build servers handle thorough
code analysis.


## Getting started.

Install the plugin using your favourite plugin manager. 

```lua
require("gotest")
```


## Why not neotest

I tried neotest, using both golang plugins, `neotest-go` and `neotest-golang`.
But neither worked satisfactory.

When starting a neotest watcher, tests did not always run on file save. And a
test watcher that doesn't run reliably is useless.

This plugin _always_ runs on file save, and _should_ always provide feedback.

## Issues

This is extremely early, so there are bound to be issues.

- No tests run if current working directory out of sync

More will probably be discovered.

### Dir out of sync.

It is expected that you start neovim from the module root. If not, maybe not all
tests run. Working directory could also be changed by other means in neovim,
causing the wrong set of tests to run.

## Navigating to test errors

Navigating to test errors require a little more work. Only the file name and
line number is available in the output. The detailed JSON format include a
package name, from which the directory can be discovered using `go list`.

The plugin already does a package-to-folder analysis using `go list`, so the
foundation is possible, but the solution requires significantly more on the
reporting part than the current version that just renders test output.
