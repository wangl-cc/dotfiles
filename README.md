# dotfiles

Dotfiles for myself.

## Requirements

This repo is managed with [`TheLocehiliosan/yadm`](https://github.com/TheLocehiliosan/yadm),
and templates are processed by [`jirutka/esh`](https://github.com/jirutka/esh).
Those dependencies are submodules of this repo,
so you don't need to install them manually.
To bootstrap this repo, you need to have `bash` and `git` installed,
which are usually pre-installed on most Linux distributions.
Then you can run the following command to bootstrap this repo:
```bash
bash -c "$(curl https://raw.githubusercontent.com/wangl-cc/dotfiles/master/.config/yadm/install.sh)"
```
Options for the bootstrap script, see `install.sh --help`.

For users in China mainland, there is a mirror of this repo on Gitee:
```bash
bash -c "$(curl https://gitee.com/wangl-cc/dotfiles/raw/master/.config/yadm/install.sh)"
```

<!-- vim:set ts=2 sw=2 tw=76: -->
