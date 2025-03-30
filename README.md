# gotest.nvim - immediate test feedback in neovim

Automatically run unit test, and get visible feedback in neovim when you save a
file.

> [!WARNING]
> This plugin is a VERY EARLY prototype. But it works... Sometimes ...

Whenever you save a `*.go` file, the plugin executes `go test ./... -vet=off` in
the current working directory, and notifies of the outcome. This also sets the
env var `GOEXPERIMENT=synctest` because I am currently experimenting with that.

If the test result in an error, which can also be due to build errors, a new
window opens (split right, width 80 cols), displaying both stderr and stdout of
the test run.

<img width="1728" alt="Test feedback" src="https://github.com/user-attachments/assets/c24efa46-4ee4-46be-8583-63f782616453" />

Pressing `<cr>` when the cursor is on a line with a filename and path will open
the file and move the cursor to the indicated position in the _previous window_.
This works for:

- Build errors
- Panic stack traces

Test errors reported by `t.Error()` and friends doesn't contain a path, so that
doesn't work yet. This [_will come_](#navigating-to-test-errors)

`-vet=off` is a personal preference as the goal is the fastest possible
feedback during normal development; and let the build servers handle thorough
code analysis.

Everything will of course eventually be customizable through options.

## Getting started.

Install the plugin using your favourite plugin manager. 

```lua
require("gotest")
```

## Future features

Cusomize which tests to run, e.g. whether to only run tests in the updated
package, or packages depending on in.

Support other automatic tasks, e.g., trigger code generation, such as mock
generators. 

Codegen could also trigger running tests. This plugin reacts to neovim events,
so files updated on the file systems will not rerun tests automatically.

## Why not neotest

I tried neotest, using both golang plugins, `neotest-go` and `neotest-golang`.
But neither worked to my satisfaction.

When starting a neotest watcher, tests did not always run on file save. And a
test watcher that doesn't run reliably is useless.

This plugin _always_ runs on file save, and _should_ always provide feedback.

## Issues

This is extremely early, so there are bound to be issues.

- The wrong set of tests are executed run if current working directory gets out
  of sync.

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
