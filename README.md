# my-vim-config

This is my own vim configuration with a shell script to install.

## Install

The `run.sh` provide some methods such as `install`, `uninstall` etc.
The `install` command will back up your own configuration and create
symbol links to this repo's configuration to make it work. All vim plugs
and coc extensions will be installed by default.
For more usage, you can run `run.sh help`.

## Custom

Add you custom plugs to `./vim/plugs.vim` and your vim configuration to
`./vim/config.vim`. 

## Requirements

Most of plugs work independently and can be installed by vim itself,
but the plug `coc.nvim` and language servers.

### [Coc.nvim](https://github.com/neoclide/coc.nvim)

Coc depends on [node.js](https://nodejs.org/), which must be installed to
run coc and its extensions.
See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim)
for more information.

### [Language Server](https://microsoft.github.io/language-server-protocol)

A language servers is a language-specific server which communicate with
editor to provide various code editing features like autocompletion,
diagnostics, formatting etc. You must install language servers and
register them in coc.nvim configuration file for code editing features.

See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Language-servers)
for more language server configuration tips.

<!-- vim modeline
vim:ts=2:sw=2:tw=75
-->
