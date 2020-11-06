# my-vim-config

This is my own vim configuration with a shell script to install it.

## Requirements

Most of plugs work independently and can be installed by
[`vim plug`](https://github.com/junegunn/vim-plug) but the plug
[`coc.nvim`](https://github.com/neoclide/coc.nvim). `Coc.nvim` depends on
[node.js](https://nodejs.org/), which must be installed to run `coc.nvim`
and its extensions.
See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim)
for more information.

## Install

The `run.sh` provide command `install`.  The `install` command will back up
your own configuration, create symbol links, install plugs and `coc.nvim`
plugs.

```bash
git clone https://github.com/wangl-cc/my-vim-config.git
cd my-vim-config
# install for vim
./run.sh install
# install for vim and neovim
./run.sh install --nvim
```

For more usage, run `./run.sh help`.

## Customize

Add additional plugs to `./vim/custom/plugs.vim` by `Plug 'plugs'`,
mapleader setting to `./vim/custom/leader.vim` and configuration to
`./vim/custom/config.vim`.

<!-- vim:set ts=2 sw=2 tw=76: -->
