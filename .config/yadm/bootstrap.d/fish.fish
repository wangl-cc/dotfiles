echo -e "\n\033[1;35mSetting up fish shell...\033[0m"

function set_verbose
  echo "  set" $argv
  set $argv
end

if test (uname -s) = "Darwin"; and test (uname -m) = "arm64"
  set_verbose -Ux CONDARC_MIRROR "bfsu.edu.cn"
else
  set_verbose -Ux CONDARC_MIRROR "aliyun.com"
end

if type -q brew
  set_verbose -Ux HOMEBREW_PREFIX (brew --prefix)
  set_verbose -Ux HOMEBREW_CELLAR (brew --cellar)
  set_verbose -Ux HOMEBREW_REPOSITORY (brew --repo)
  set -l _homebrew_bin $HOMEBREW_PREFIX/bin
  if not contains $_homebrew_bin $fish_user_paths
    set_verbose -U fish_user_paths $_homebrew_bin $fish_user_paths
  end
end

# vim:ts=2:sw=2:et
