require("gotest.autorunner")

local M = {
  dirs = {},
  packages = {},
  modules = {},
}
M.setup = function(self) end

--- Generate diagnostics messages for a file
--- @param path string: The full file path
--- @param lines string[]: The file contents
local parse_dependencies = function(path, lines) end

--- Get the directory for the file in a buffer
--- @param buffer integer: Buffer handle
--- @return string
local get_buf_dir = function(buffer)
  local name = vim.api.nvim_buf_get_name(buffer)
  return vim.fn.fnamemodify(name, ":p:h")
end

local ensure_key = function(tbl, key)
  if not tbl[key] then
    tbl[key] = {}
  end
  return tbl[key]
end

--- Process the dependencies of a single package
local process_module_package = function(dir, package)
  if package == "" then
    return
  end
  local pkg = ensure_key(M.packages, package)
  vim.fn.jobstart({ "go", "list", "-json", package }, {
    cwd = dir,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end
      data = table.concat(data, "\n")

      local parsed = vim.json.decode(data)
      local dirObj = ensure_key(M.dirs, parsed.Dir)
      dirObj.package = package

      pkg.module = parsed.Module.Path
      pkg.deps = parsed.Deps
      if parsed.XTestImports then
        for _, imp in ipairs(parsed.XTestImports) do
          table.insert(pkg.deps, imp)
        end
      end
      if parsed.Deps then
        for _, dep in ipairs(parsed.Deps) do
          local depPkg = ensure_key(M.packages, dep)
          local dependees = ensure_key(depPkg, "dependees")
          dependees[package] = true
        end
      end
    end,
    on_exit = function(k) end,
  })
end

--- Process dependency information about all packages in a module dir
--- @param dir string: The root dir of a module
local process_module_packages = function(dir)
  vim.fn.jobstart({ "go", "list", "./..." }, {
    cwd = dir,
    stdout_buffered = true,
    on_stdout = function(_, data)
      P(data)
      if data then
        for _, package in ipairs(data) do
          process_module_package(dir, package)
        end
      end
    end,
  })
end

--- Given a directory, find the module that it belongs to, and process
--- dependency information in all its packages.
local init_module = function(dir)
  vim.fn.jobstart({ "go", "list", "-m", "-json" }, {
    cwd = dir,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        local parsed = vim.json.decode(table.concat(data, "\n"))
        local module = ensure_key(M.modules, parsed.Path)
        module.dir = parsed.Dir
        module.main = parsed.Main
        process_module_packages(module.dir)
      end
    end,
  })
end

--- Processes the current buffer for it's package dependencies
--- @param buffer integer: Buffer handle
M.process_buf_dependencies = function(self, buffer)
  local dir = get_buf_dir(buffer)
  if not M.dirs[dir] then
    init_module(dir)
    return
  end
  vim.fn.jobstart({ "go", "list", "-json" }, {
    cwd = dir,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end
      data = table.concat(data, "\n")
      local parsed = vim.json.decode(data)
      local package = parsed.ImportPath
      ensure_key(self.dirs, dir).package = package
      local pkg = ensure_key(self.packages, package)
      pkg.dir = dir
      pkg.deps = parsed.Deps
    end,
    on_exit = function(k) end,
  })
  vim.fn.jobstart({ "go", "list", "-test", "-json" }, {
    cwd = dir,
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then
        return
      end
      data = table.concat(data, "\n")
    end,
    on_exit = function(k) end,
  })
end

local augrp = vim.api.nvim_create_augroup("stroiman-gotest", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPre" }, {
  group = augrp,
  pattern = "*.go",
  callback = function(event)
    local buf = event.buf
    M:process_buf_dependencies(buf)
  end,
})

vim.cmd([[messages clear]])

return M
