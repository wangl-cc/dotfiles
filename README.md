# dotfiles

Dotfiles for myself.

## Requirements and Installation

### System Requirements

- `bash`: bootstrap script and dotfile manager are written in bash. (required)
- `git`: to clone this repository. (required)

### Third-party Dependencies

This repository is managed by [`yadm`][yadm], a dotfile manager written in bash.
Some of dotfiles are templates, which should be processed by [`esh`][esh].
For ease of use, `yadm` and `esh` are included in this repository,
so you don't need to install them manually.

### Installation

A bootstrap script is provided to install this repository:

```bash
bash -c "$(curl https://raw.githubusercontent.com/wangl-cc/dotfiles/master/.config/yadm/install.sh)"
```

Options for the bootstrap script, see `install.sh --help`.

For users in China mainland, there is a mirror of this repository on Gitee:

```bash
bash -c "$(curl https://gitee.com/wangl-cc/dotfiles/raw/master/.config/yadm/install.sh)"
```

## License

Most of the files in this repository is licensed under the MIT License.
See [LICENSE](LICENSE) for details.

However, some files are copied or derived from other repositories,
which may have different licenses:

- Copied files:
  - `yadm`: GPL-3.0, included files:
    - `.local/bin/yadm`
    - `.local/share/man/man1/yadm.1`
  - `esh`: [MIT][esh-license], included files:
    - `.local/bin/esh`
    - `.local/share/man/man1/esh.1`
- Derived files:
  - `install.sh`: GPL-3.0, this file is modified from `yadm`,
     so it is also licensed under GPL-3.0.

[yadm]: https://github.com/TheLocehiliosan/yadm
[esh]: https://github.com/jirutka/esh
[esh-license]: https://github.com/jirutka/esh/blob/1df78620ba661be00218923e8164283ab6f44103/LICENSE

<!-- vim:set ts=2 sw=2 tw=76: -->
