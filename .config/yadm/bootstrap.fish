if type -q brew
  echo "Setup univarsal variables of homebrew"
  set -Ux HOMEBREW_PREFIX (brew --prefix)
  set -Ux HOMEBREW_CELLAR (brew --cellar)
  set -Ux HOMEBREW_REPOSITORY (brew --repo)
  set -l _homebrew_bin $HOMEBREW_PREFIX/bin
  if not contains $_homebrew_bin $fish_user_paths
    set -U fish_user_paths $_homebrew_bin $fish_user_paths
  end
end

# vim:ts=2:sw=2:et
