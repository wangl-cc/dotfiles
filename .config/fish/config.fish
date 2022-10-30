# path {{{
set -gx PATH $HOME/.local/bin $PATH
# path }}}

if status is-interactive # {{{
# abbreviates {{{
function abbrg --description 'Create a new global abbreviation'
  abbr -a -g $argv
end
# rm
abbrg rm "rm -i"
# vi
abbrg vi vim
# ls
abbrg l  ls --color
abbrg ll ls --color -lh
abbrg la ls --color -Alh
# cd
abbrg ... ../..
# git {{{
abbrg g   git
abbrg ga  git add
abbrg gb  git branch
abbrg gc  git commit
abbrg gd  git diff
abbrg gds git diff --staged
abbrg gs  git status
abbrg gsu git status -u
abbrg gl  git log
abbrg gp  git push
abbrg gpl git pull
abbrg gr  git remote
abbrg gco git checkout
abbrg gcm git checkout master
abbrg gcb git checkout -b
abbrg y    yadm
abbrg ya   yadm add
abbrg yb   yadm branch
abbrg yc   yadm commit
abbrg yd   yadm diff
abbrg yds  yadm diff --staged
abbrg ys   yadm status
abbrg ysu  yadm status -u
abbrg yl   yadm log
abbrg yp   yadm push
abbrg ypl  yadm pull
abbrg yr   yadm remote
abbrg yco  yadm checkout
abbrg ycm  yadm checkout master
abbrg ycb  yadm checkout -b
# git }}}
# abbreviates }}}

# environments variables for interactive shells {{{
# don't set EDITOR, EDITOR has a higher priority than VISUAL in Homebrew
if type -q nvim
  abbrg vim nvim
  set -gx VISUAL nvim
  set -gx GIT_DIFF_TOOL nvimdiff
else
  set -gx VISUAL vim
  set -gx GIT_DIFF_TOOL vimdiff
end
set -gx ESH_SHELL /bin/bash
set -gx WAKATIME_HOME $HOME/.config/wakatime
# environments variables for interactive shells }}}

# fish config {{{
if type -q fastfetch
  # use fastfetch if installed
  function fish_greeting
      fastfetch
  end
  abbrg ff fastfetch
else
  set -g fish_greeting # set to null to disable greeting
end
set -g fish_key_bindings fish_vi_key_bindings
# fish config }}}

# starship initialize {{{
if type -q starship
  starship init fish | source
end
# starship initialize }}}

end # is-interactive }}}

# vim:ts=2:sw=2:ft=fish:fdm=marker:et
