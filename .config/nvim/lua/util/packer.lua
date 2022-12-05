local util = require "util"
local M = {}

-- install packer.nvim if not installed
local function bootstrap()
  local fn = vim.fn
  local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system {
      "git",
      "clone",
      "--depth",
      "1",
      "https://github.com/wbthomason/packer.nvim",
      install_path,
    }
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local function auto_compile(packer)
  local group = vim.api.nvim_create_augroup("AutoCompile", { clear = true })
  util.create_source_autocmd {
    pattern = {
      "*/nvim/lua/plugins/*.lua",
      "*/nvim/lua/util/*.lua",
    },
    callback = function()
      util.info("Reload plugins", "AutoCompile")
      for mod, _ in pairs(package.loaded) do
        if mod:match "^plugins" or mod:match "^util" then
          util.unload(mod)
        end
      end
      require "plugins"
      packer.compile()
    end,
    group = group,
  }
  vim.api.nvim_create_autocmd("User", {
    pattern = "PackerCompileDone",
    callback = function()
      util.info("Packer compile done", "AutoCompile")
    end,
    group = group,
  })
end

function M.setup(config, startup)
  local bootstraped = bootstrap()

  local packer = require "packer"
  packer.init(config)
  packer.reset()

  local function use(spec)
    if type(spec) == "table" and spec.plugin then
      spec = vim.tbl_deep_extend("force", spec, require("plugins." .. spec.plugin))
    end
    return packer.use(spec)
  end

  startup(use)

  if bootstraped then
    packer.sync()
  end

  auto_compile(packer)

  return packer
end

return M

-- vim:ts=2:sw=2:et
