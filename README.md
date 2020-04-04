# my-vim-config

This is my own vim configuration with a shell script to install it.

## Requirements

Most of plugs work independently and can be installed by vim itself
but the plug [`coc.nvim`](https://github.com/neoclide/coc.nvim).
`Coc.nvim` depends on [node.js](https://nodejs.org/), which must be
installed to run `coc.nvim` and its extensions.
See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim)
for more information.

## Install

The `run.sh` provide command `install`.  The `install` command will back up
your own configuration, create symbol links, install plugs and `coc.nvim`
plugs.

```bash
git clone https://github.com/wangl-cc/my-vim-config.git
cd my-vim-config
# vim
./run.sh install
# neovim
./run.sh install --nvim
```

For more usage, run `./run.sh help`.

## Custom

Add your custom plugs to `./vim/custom/plugs.vim`, vim configuration to
`./vim/custom/config.vim` and `coc.nvim` configuration to
`./vim/coc-settings.json`.

## [Language Server](https://microsoft.github.io/language-server-protocol)

A language servers is a language-specific server which communicate with
editor to provide various code editing features like autocompletion,
diagnostics, formatting etc. Install language servers and
register them in `coc.nvim` configuration file for code editing features.

See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Language-servers)
for more language server configuration tips.

<!-- vim modeline
vim:ts=2:sw=2:tw=75
-->
