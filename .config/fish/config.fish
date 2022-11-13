# path {{{
set -gx PATH $HOME/.local/bin $PATH
# path }}}

if status is-interactive # {{{
# abbreviates {{{
function gabbr --description 'Create a new global abbreviation'
  abbr -a -g $argv
end
# rm
gabbr rm rm -i
# ls
gabbr l  ls --color
gabbr ll ls --color -lh
gabbr la ls --color -Alh
# cd
gabbr ... ../..
# git {{{
gabbr g   git
gabbr ga  git add
gabbr gb  git branch
gabbr gbl git branch -l
gabbr gba git branch -a
gabbr gc  git commit
gabbr gd  git diff
gabbr gds git diff --staged
gabbr gs  git status
gabbr gsu git status -u
gabbr gl  git log
gabbr gp  git push
gabbr gpl git pull
gabbr gr  git remote
gabbr grv git remote -v
gabbr gra git remote add
gabbr gco git checkout
gabbr gcm git checkout master
gabbr gcb git checkout -b
gabbr y    yadm
gabbr ya   yadm add
gabbr yb   yadm branch
gabbr yc   yadm commit
gabbr yd   yadm diff
gabbr yds  yadm diff --staged
gabbr ys   yadm status
gabbr ysu  yadm status -u
gabbr yl   yadm log
gabbr yp   yadm push
gabbr ypl  yadm pull
gabbr yr   yadm remote
gabbr yco  yadm checkout
gabbr ycm  yadm checkout master
gabbr ycb  yadm checkout -b
# git }}}
# abbreviates }}}

# environments variables for interactive shells {{{
# don't set EDITOR, EDITOR has a higher priority than VISUAL in Homebrew
if type -q nvim
  if set -q NVIM # inside nvim
    gabbr vi nvr
    gabbr vim nvr
    gabbr nvim nvr
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
    gabbr vi nvim
    gabbr vim nvim
    gabbr nvim nvim
    set -gx VISUAL nvim
    set -gx GIT_DIFF_TOOL nvimdiff
    set -gx GIT_MERGE_TOOL nvimdiff
  end
else
  gabbr vi vim
  set -gx VISUAL vim
  set -gx GIT_DIFF_TOOL vimdiff
  set -gx GIT_MERGE_TOOL vimdiff
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
  gabbr ff fastfetch
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
