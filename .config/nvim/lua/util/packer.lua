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
  util.create_bufwrite_autocmd {
    pattern = "*/nvim/lua/plugins/*.lua",
    callback = function(args)
      util.info("Reload plugins", "AutoCompile")
      local mod = vim.fs.basename(args.file):sub(1, -5)
      if mod == "init" then
        util.reload "plugins"
        local ok = pcall(packer.compile)
        if not ok then
          util.info("Install missing plugins")
          pcall(packer.install)
        end
      else -- re-run config of given plugin configs
        pcall(util.reload("plugins." .. mod).config)
      end
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
  vim.api.nvim_create_user_command(
    "PackerReload",
    function()
      util.reload "plugins"
      local ok = pcall(packer.compile)
      if not ok then
        util.info("Install missing plugins")
        pcall(packer.install)
      end
    end,
    { desc = "Reload config and compile with packer" }
  )
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
