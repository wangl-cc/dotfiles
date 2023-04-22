echo -e "\n\033[1;35mSetting up fish shell...\033[0m"

function set_verbose
  echo "  set" $argv
  set $argv
end

if type -q brew
  set_verbose -Ux HOMEBREW_PREFIX (brew --prefix)
  set_verbose -Ux HOMEBREW_CELLAR (brew --cellar)
  set_verbose -Ux HOMEBREW_REPOSITORY (brew --repo)
  fish_add_path -Up $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
  set_verbose -Ux HOMEBREW_API_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
  set_verbose -Ux HOMEBREW_BOTTLE_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
end

fish_add_path -Up $HOME/.local/bin $HOME/.cargo/bin $HOME/.local/share/bob/nvim-bin

# vim:ts=2:sw=2:et
