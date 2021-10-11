# dotfiles

Managed with [`TheLocehiliosan/yadm`](https://github.com/TheLocehiliosan/yadm).

## Enviroment variables required

### `PATH`

```zsh
typeset -U PATH path
path=("$HOME/.local/bin" "$path[@]")
export PATH
```

### Github mirrors URL

```zsh
export GITHUBURL="hub.fastgit.org"
export GITHUBUSERCONTENTURL="raw.fastgit.org"
```

### Set in `.zshenv`

```bash
echo """typeset -U PATH path
path=(\"\$HOME/.local/bin\" \"\$path[@]\")
export PATH

export GITHUBURL=\"hub.fastgit.org\"
export GITHUBUSERCONTENTURL=\"raw.fastgit.org\"
""" >> ~/zshenv
```

## Installation

```bash
cd ~
if [ -z ${GITHUBUSERCONTENTURL+x} ]; then
    curl -O https://GITHUBUSERCONTENTURL/TheLocehiliosan/yadm/master/yadm
else
    curl -O https://raw.githubusercontent.com/TheLocehiliosan/yadm/master/yadm
fi
sh ./yadm clone git@github.com:wangl-cc/dotfiles.git
rm ./yadm # clean local yadm if bootstrap succeed
```

<!-- vim:set ts=2 sw=2 tw=76: -->
