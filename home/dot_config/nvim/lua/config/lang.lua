-- Language Specific Configuration

local ls = require "putil.lsp"
local ts = require "putil.tree-sitter"
local fmt = require "putil.formatter"
local lt = require "putil.linter"
local opt = require "putil.ft-options"
local plugin = require "putil.ft-plugins"

-- C/C++
ls.register("clangd", {
  options = {
    cmd = {
      "clangd",
      "--background-index",
      "--clang-tidy",
      "--header-insertion=iwyu",
      "--completion-style=detailed",
      "--function-arg-placeholders",
      "--fallback-style=llvm",
      "--offset-encoding=utf-16",
    },
  },
})
ts.add_langs { "c", "cpp" }

-- Rust
ls.register("rust_analyzer", {
  options = {
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = { command = "clippy" },
        rustfmt = { extraArgs = { "+nightly" } },
      },
    },
  },
})
ts.add_langs { "rust" }
opt.indent_size("rust", 4)
opt.line_width("rust", 100)

-- Python
ls.register "pyright"
ls.register "ruff"
ts.add_langs { "python" }
opt.indent_size("python", 4)
vim.filetype.add { filename = {
  ["uv.lock"] = "toml",
} }

-- Lua
ls.register("lua_ls", {
  ---@type lspconfig.options.lua_ls
  ---@diagnostic disable: missing-fields
  options = {
    settings = {
      Lua = {
        telemetry = { enable = false },
        workspace = { checkThirdParty = false },
        hint = {
          enable = true,
          arrayIndex = "Disable",
        },
        runtime = {
          version = "LuaJIT",
        },
        format = {
          enable = false,
        },
      },
    },
  },
  ---@diagnostic enable: missing-fields
})
ts.add_langs { "lua" }
fmt.register("lua", "stylua")
plugin.register {
  "folke/lazydev.nvim",
  ft = "lua",
  version = "*",
  dependencies = {
    { "Bilal2453/luvit-meta" },
  },
  opts = {
    library = {
      { path = "luvit-meta/library", words = { "vim%.uv" } },
    },
  },
}

-- Julia
ls.register("julials", {
  disabled = vim.env.__JULIA_LSP_DISABLE == "true" or vim.fn.executable "julia" == 0,
  -- Julia LS is a package and some scripts are written in Julia,
  -- which can not be installed by system package manager (e.g. brew),
  -- and I don't want to maintain them manually.
  -- Mason extracts them from vscode extension and install them,
  -- so I use Mason to install Julia LS.
  mason = true,
  ---@type lspconfig.options.julials
  ---@diagnostic disable: missing-fields
  options = {
    settings = {
      julia = {
        lint = {
          run = true,
          missingrefs = "all",
          disabledDirs = { "test", "docs" },
        },
        inlayHints = {
          static = {
            enabled = true,
          },
        },
      },
    },
  },
  ---@diagnostic enable: missing-fields
})
ts.add_langs { "julia" }
opt.indent_size("julia", 4)
opt.line_width("julia", 92)

-- Bash / Fish
ls.register("bashls", {
  options = {
    filetypes = { "sh", "bash" },
  },
})
fmt.register("fish", "fish_indent")
lt.register_for_ft("bash", "shellcheck")
lt.register_for_ft("fish", "fish")
ts.add_langs { "bash", "fish" }
opt.indent_size("bash", 4)

-- JSON / JSONC / YAML / TOML
ls.register "jsonls" -- `jsonls` don't support JSON5
ls.register "yamlls"
ls.register "taplo"
ts.add_langs { "json", "jsonc", "yaml", "toml" }
for _, lang in ipairs { "json", "jsonc", "yaml" } do
  fmt.register(lang, "prettierd")
end
lt.register_for_pattern("%.github/workflows/.+%.ya?ml", "actionlint")

-- LaTeX
ts.add_langs { "latex" }
ts.disable_hl_for { "latex" }
opt.line_width("tex", 0)
plugin.register {
  "lervag/vimtex",
  ft = "tex",
  cmd = "VimtexInverseSearch", -- for inverse search
  init = function()
    vim.g.vimtex_view_method = "skim"
    vim.g.vimtex_view_skim_sync = 1
    vim.g.vimtex_view_skim_reading_bar = 1
    vim.g.vimtex_compiler_method = "tectonic"
    vim.g.vimtex_compiler_tectonic = {
      out_dir = "",
      hooks = {},
      options = {
        "-X",
        "compile",
        "--untrusted",
        "--synctex",
        "--keep-logs",
        "--keep-intermediates",
      },
    }
  end,
}
vim.g.tex_flavor = "latex"

-- Typst
vim.g.filetype_typ = "typst"
ls.register "tinymist"
ts.add_langs { "typst" }
opt.line_width("typst", 0)

-- Markdown
-- Marksman is a F# project which need a .NET runtime.
-- Use mason to install self-contained executable to avoid .NET runtime.
ls.register("marksman", { mason = true })
ts.add_langs { "markdown", "markdown_inline" }
fmt.register("markdown", "prettierd")
lt.register_for_ft("markdown", "markdownlint-cli2")
opt.line_width("markdown", 0)
plugin.register {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "codecompanion" },
  opts = {},
}

-- Git
ts.add_langs { "gitcommit", "git_config", "diff" }
opt.hard_tab "gitconfig"

-- MISC
opt.hard_tab "make"
ts.add_langs { "regex" }

-- Chezmoi Template
ts.add_langs { "gotmpl" }
vim.filetype.add {
  pattern = {
    [".*%.tmpl"] = function(path)
      local content_ft = vim.filetype.match { filename = path:gsub("%.tmpl", "") }
      if not content_ft then return "gotmpl" end
      local lang = vim.treesitter.language.get_lang(content_ft)
      local scm = string.format(
        [[
          ((text) @injection.content
          (#set! injection.language "%s")
          (#set! injection.combined))
        ]],
        lang
      )
      return "gotmpl",
        function(bufnr)
          vim.treesitter.query.set("gotmpl", "injections", scm)
          vim.treesitter.start(bufnr, "gotmpl")
        end
    end,
  },
}

-- General
ls.register "typos_lsp"

-- Enable AutoCmd for filetype specific options
opt.setup()
