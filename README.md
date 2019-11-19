# my-vim-config

There are my own vim configuration files include .vimrc file and .vim directory.

## Usage

### Install

The install.sh will rename your own configuration files and create a symbol
link to files in this repository, then install plugs and extension.

### Custom

Custom plugs in `.vim/plugs.vim`, vim configurations in `.vim/config.vim`,
coc configurations in `.vim/coc-settings-user.json`. Once coc configurations
changed, you must run `:call joinjson#Update()` to apply changes.

## Dependencies

### [Coc.nvim](https://github.com/neoclide/coc.nvim)

See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim)

### [LSP](https://microsoft.github.io/language-server-protocol)

See [coc wiki](https://github.com/neoclide/coc.nvim/wiki/Language-servers).
There are three language servers:

* [pyls](https://github.com/palantir/python-language-server): Python language server
* [clangd](https://clang.llvm.org/extra/clangd): LLVM c/c++ language server
* [LanguageServer.jl](https://github.com/julia-vscode/LanguageServer.jl): Julia language server
