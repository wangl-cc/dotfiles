local M = {}

--@alias BackgroundEnum string | '"light"' | '"dark"'

--@param bg BackgroundEnum
local function switch_bg(bg)
  if vim.o.background ~= bg then
    vim.o.background = bg
    vim.api.nvim_exec_autocmds("OptionSet", { pattern = "background" })
  end
end

--@class BackgroundSwitcher
--@field pre? fun(): void
--@field post? fun(): void

--@param bg BackgroundEnum
--@param switcher? BackgroundSwitcher
local function switch(bg, switcher)
  if not switcher then
    switch_bg(bg)
    return
  end
  if switcher.pre then
    switcher.pre()
  end
  switch_bg(bg)
  if switcher.post then
    switcher.post()
  end
end

--@class AutoBackgroundOptions
--@field is_dark fun(): boolean
--@field dark? BackgroundSwitcher
--@field light? BackgroundSwitcher

local autobg_lock = false
function M.autobg()
  if not autobg_lock then
    autobg_lock = true
    if M.options.is_dark() then
      switch("dark", M.options.dark)
    else
      switch("light", M.options.light)
    end
    autobg_lock = false
  end
end

--@param opts AutoBackgroundOptions
function M.setup(opts)
  opts = opts or {}

  M.options = vim.deepcopy(opts)

  local autobg_group =
    vim.api.nvim_create_augroup("AutoBackground", { clear = true })
  -- iTerm2 will send a SIGWINCH when the theme changes
  vim.api.nvim_create_autocmd("Signal", {
    pattern = "SIGWINCH",
    callback = M.autobg,
    group = autobg_group,
  })

  return autobg_group
end

return M

-- vim:tw=76:ts=2:sw=2:et
