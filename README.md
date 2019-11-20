# my-vim-config

This is my own vim configuration with a install shell script.

## Usage

### Install

The `run.sh` provide some methods such as `install`, `uninstall` etc.
The `install` command will back up your own configuration and create
symbol links to this repo's configuration to make it work. All vim plugs
and coc extensions will be installed by default.
For more usage, you can run `run.sh help`.

### Custom

Custom plugs in `.vim/plugs.vim`, vim configuration in `.vim/config.vim`,
coc configuration in `.vim/coc-settings-user.json`. Notice, you must run
`:call joinjson#Update()` in vim to apply coc configuration changes.

## Requirements

### [Coc.nvim](https://github.com/neoclide/coc.nvim)

Coc depends on [node.js](https://nodejs.org/), which must be installed to
run coc and its extensions.
See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim)
for more information.

### [LSP](https://microsoft.github.io/language-server-protocol)

In this configuration, four language servers are used, which should be
install additionally.

* [palantir/python-language-server](
  https://github.com/palantir/python-language-server): Python language
  server.
* [clangd](https://clang.llvm.org/extra/clangd): LLVM c/c++ language
  server.
* [LanguageServer.jl](https://github.com/julia-vscode/LanguageServer.jl):
  Julia language server.
* [mads-hartmann/bash-language-server](
  https://github.com/mads-hartmann/bash-language-server): Bash language
  server.

See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Language-servers)
for more language server configuration tips.

<!-- vim modeline
vim:ts=2:sw=2:tw=74
-->
