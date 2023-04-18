echo -e "\n\033[1;35mSetting up fish shell...\033[0m"

function set_verbose
  echo "  set" $argv
  set $argv
end

function set_user_path
  set -l paths
  for path in $argv
    if not contains $path $fish_user_paths
      set paths $path $paths
    end
  end
  if test -n "$paths"
    set_verbose -U fish_user_paths $paths $fish_user_paths
  end
end

function set_existent_path
  for path in $argv
    if test -d $path
      set_user_path $path
    end
  end
end

if type -q brew
  set_verbose -Ux HOMEBREW_PREFIX (brew --prefix)
  set_verbose -Ux HOMEBREW_CELLAR (brew --cellar)
  set_verbose -Ux HOMEBREW_REPOSITORY (brew --repo)
  set_user_path $HOMEBREW_PREFIX/bin $HOMEBREW_PREFIX/sbin
end

set_user_path $HOME/.local/bin

set_existent_path $HOME/.cargo/bin $HOME/.local/share/bob/nvim-bin

# vim:ts=2:sw=2:et
