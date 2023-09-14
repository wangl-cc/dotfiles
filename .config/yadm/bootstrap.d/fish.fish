echo -e "\n\033[1;35mSetting up fish shell...\033[0m"

function set_verbose
  set -l opt $argv[1]
  # if opt start with dash, then it's a option, thus we need to shift argv
  if string match -qr -- "^-.*" $opt
    set -e -- argv[1]
  end
  set -l var $argv[1]
  set -l val $argv[2..-1]
  if test "$$var" != $val
    echo -e "    set" $opt "\033[1;33m$var\033[0m" "\033[1;34m$val\033[0m"
    set $opt $var $val
  end
end

if type -q brew
  echo -e "  Setting up \033[1;34mHomebrew\033[0m..."
  set_verbose -Ux HOMEBREW_PREFIX (brew --prefix)
  set_verbose -Ux HOMEBREW_CELLAR (brew --cellar)
  set_verbose -Ux HOMEBREW_REPOSITORY (brew --repo)
  fish_add_path -Up $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
  set_verbose -Ux HOMEBREW_API_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
  set_verbose -Ux HOMEBREW_BOTTLE_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
end

echo -e "  Setting up \033[1;34mPATH\033[0m..."
fish_add_path -Up $HOME/.local/bin $HOME/.cargo/bin $HOME/.local/share/bob/nvim-bin

# vim:ts=2:sw=2:et
