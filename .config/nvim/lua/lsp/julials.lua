--@type LspConfig
local M = {}

if vim.fn.executable "julia" ~= 1 or vim.env.__JULIA_LSP_DISABLE == "true" then
  M.disabled = true
  return M
end

local Job = require "plenary.job"

M.setup_capabilities = function(capabilities)
  -- from wiki of LanguageServer.jl
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  capabilities.textDocument.completion.completionItem.preselectSupport = true
  capabilities.textDocument.completion.completionItem.tagSupport =
    { valueSet = { 1 } }
  capabilities.textDocument.completion.completionItem.deprecatedSupport = true
  capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
  capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
  capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
  capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = { "documentation", "detail", "additionalTextEdits" },
  }
  capabilities.textDocument.completion.completionItem.documentationFormat =
    { "markdown" }
  capabilities.textDocument.codeAction = {
    dynamicRegistration = true,
    codeActionLiteralSupport = {
      codeActionKind = {
        valueSet = (function()
          local res = vim.tbl_values(vim.lsp.protocol.CodeActionKind)
          table.sort(res)
          return res
        end)(),
      },
    },
  }
  return capabilities
end

local os_name = vim.loop.os_uname().sysname
local julia_img_user = os_name == "Darwin"
    and vim.fn.expand "~/.config/julials/compiler/sys.dylib"
  or vim.fn.expand "~/.config/julials/sys.so"
local julia_cmd = {
  "julia",
  "--startup-file=no",
  "--history-file=no",
  vim.fn.expand "~/.config/julials/nvim_lsp/julials.jl",
}
if vim.fn.filereadable(julia_img_user) == 1 then
  table.insert(julia_cmd, "-J")
  table.insert(julia_cmd, julia_img_user)
end

function M.install()
  return Job:new({
    command = "julia",
    args = {
      "--startup-file=no",
      "--history-file=no",
      "--project=~/.config/julials/nvim_lsp",
      "-e",
      [[using Pkg; Pkg.instantiate()]],
    },
    on_exit = function(_, code)
      if code == 0 then
        print "julials installed."
      else
        print "julials installation failed."
      end
    end,
  }):start()
end

function M.compile()
  return Job:new({
    command = "julia",
    args = {
      "--history-file=no",
      "--project=~/.config/julials/nvim_lsp",
      vim.fn.expand "~/.config/julials/compiler/compile.jl",
    },
    on_exit = function(_, code)
      if code == 0 then
        print "julials compiled."
      else
        print "julials compilation failed."
      end
    end,
  }):start()
end

M.options = {
  cmd = julia_cmd,
  settings = {
    julia = {
      lint = {
        run = true,
        missingrefs = "none",
        disabledDirs = { "test", "docs" },
      },
    },
  },
  on_new_config = function(config, root_dir)
    -- read config from .julials.json in root_dir
    -- and then merge it into config
    -- Example: { "lint": { "run": false } } will disable linting,
    -- more options see: https://github.com/julia-vscode/LanguageServer.jl/blob/main/src/requests/workspace.jl#L96-L110
    local jl_config = root_dir .. "/.julials.json"
    if vim.fn.filereadable(jl_config) == 1 then
      local f = io.open(jl_config, "r")
      if not f then
        return
      end
      local content = f:read "*a"
      local decoded = vim.json.decode(content)
      if decoded then
        config.settings.julia = vim.tbl_deep_extend(
          "force",
          config.settings.julia,
          decoded
        )
      end
      f:close()
    end
  end
}

return M
