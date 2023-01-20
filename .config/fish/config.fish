# path {{{
set -gx PATH $HOME/.local/bin $PATH
# path }}}

if status is-interactive # {{{
# abbreviates {{{
# rm
abbr --add rm rm -i
# ls
abbr --add l  ls --color
abbr --add ll ls --color -lh
abbr --add la ls --color -Alh
# cd
abbr --add .. cd ..
abbr --add ... cd ../..
abbr --add .... cd ../../..
# julia
abbr --add jl julia
abbr --add jp julia --project
# git {{{
abbr --add g   git
abbr --add ga  git add
abbr --add gb  git branch
abbr --add gbl git branch -l
abbr --add gba git branch -a
abbr --add gc  git commit
abbr --add gco git checkout
abbr --add gcm git checkout master
abbr --add gcb git checkout -b
abbr --add gci git check-ignore -v
abbr --add gd  git diff
abbr --add gds git diff --staged
abbr --add gl  git log
abbr --add gp  git push
abbr --add gpl git pull
abbr --add gr  git remote
abbr --add grv git remote -v
abbr --add gra git remote add
abbr --add gs  git status
abbr --add gsu git status -u
abbr --add y  yadm
abbr --add ya yadm alt
abbr --add yb yadm bootstrap
abbr --add yd yadm decrypt
abbr --add ye yadm encrypt
abbr --add yp yadm perms
abbr --add yg yadm git-crypt
abbr --add yt yadm transcrypt
# git }}}
# abbreviates }}}

# environments variables for interactive shells {{{
# don't set EDITOR, EDITOR has a higher priority than VISUAL in Homebrew
if type -q nvim
  if set -q NVIM # inside nvim
    abbr --add vi nvr
    abbr --add vim nvr
    abbr --add nvim nvr
    # if neovim-remote is not installed, fallback to nvim
    if not type -q nvr
      # this definition works but not as good as nvr
      # thus neovim-remote is highly recommended
      function nvr --description "neovim remote"
        nvim --server $NVIM --remote $argv
      end
    end
    # environments variables set in nvim
  else
    abbr --add vi nvim
    abbr --add vim nvim
    abbr --add nvim nvim
    set -gx VISUAL nvim
  end
else
  abbr --add vi vim
  set -gx VISUAL vim
end
set -gx ESH_SHELL /bin/bash
set -gx WAKATIME_HOME $HOME/.config/wakatime
# environments variables for interactive shells }}}

# fish greeting {{{
if type -q fastfetch
  # use fastfetch if installed
  function fish_greeting
      fastfetch
  end
  abbr --add ff fastfetch
else
  set -g fish_greeting # set to null to disable greeting
end
# fish_greeting }}}

# fish vi mode {{{
set -g fish_key_bindings fish_vi_key_bindings
function fish_user_key_bindings
  fish_default_key_bindings -M insert # set default key bindings for insert mode
  # then execute the vi-bindings so they take precedence when there's a conflict.
  fish_vi_key_bindings --no-erase insert
end
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace underscore
set fish_cursor_replace_one underscore
# fish vi mode}}}

# starship initialize {{{
if type -q starship
  starship init fish | source
end
# starship initialize }}}

end # is-interactive }}}

# vim:ts=2:sw=2:ft=fish:fdm=marker:et
