# dotfiles

Dotfiles for myself.

## Requirements

This repo is managed with [`TheLocehiliosan/yadm`](https://github.com/TheLocehiliosan/yadm),
and templates are processed by [`jirutka/esh`](https://github.com/jirutka/esh).
Those dependencies can be installed with your favourite package manager,
or with the `install.sh` script:
```bash
zsh -c "$(curl https://raw.githubusercontent.com/wangl-cc/dotfiles/master/.config/yadm/install.sh)"
```

This will install all dependencies and clone this repo to `$HOME/.git` and run bootstrap script of YADM. If you install dependencies other way, you need to clone this repo to `$HOME/.git` manually:
```bash
yadm --yadm-repo "$HOME/.git" clone $REPOSITORY # replace $REPOSITORY with your repository url
```

For users in China mainland, download from Gitee instead:
```bash
YADM_RAW="https://gitee.com/wangl-cc/yadm/raw" \
ESH_RAW="https://gitee.com/wangl-cc/esh/raw" \
zsh -c "$(curl https://gitee.com/wangl-cc/dotfiles/raw/master/.config/yadm/install.sh)"
```

<!-- vim:set ts=2 sw=2 tw=76: -->
