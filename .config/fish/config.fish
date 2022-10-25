# path {{{
set -gx PATH $HOME/.local/bin $PATH
# path }}}

# conda initialize {{{
# set __conda_bin as a universal variable, set it after you install it
if test -f $__conda_bin
  eval $HOME/Conda/bin/conda "shell.fish" "hook" $argv | source
end
# conda initialize }}}

if status is-interactive # {{{
# abbreviates {{{
function _abbr
  abbr -a -g $argv
end
# rm
_abbr rm "rm -i"
# vi
_abbr vi vim
# ls
_abbr l  "ls --color"
_abbr ll "ls --color -lh"
_abbr la "ls --color -Alh"
# cd
_abbr ... "../.."
# git {{{
_abbr g   git
_abbr ga  git add
_abbr gb  git branch
_abbr gc  git commit
_abbr gd  git diff
_abbr gds git diff --staged
_abbr gs  git status
_abbr gsu git status -u
_abbr gl  git log
_abbr gp  git push
_abbr gpl git pull
_abbr gr  git remote
_abbr gco git checkout
_abbr gcm git checkout master
_abbr gcb git checkout -b
_abbr yadm yadm --yadm-repo ~/.git
_abbr y    yadm --yadm-repo ~/.git
_abbr ya   yadm --yadm-repo ~/.git add
_abbr yb   yadm --yadm-repo ~/.git branch
_abbr yc   yadm --yadm-repo ~/.git commit
_abbr yd   yadm --yadm-repo ~/.git diff
_abbr yds  yadm --yadm-repo ~/.git diff --staged
_abbr ys   yadm --yadm-repo ~/.git status
_abbr ysu  yadm --yadm-repo ~/.git status -u
_abbr yl   yadm --yadm-repo ~/.git log
_abbr yp   yadm --yadm-repo ~/.git push
_abbr ypl  yadm --yadm-repo ~/.git pull
_abbr yr   yadm --yadm-repo ~/.git remote
_abbr yco  yadm --yadm-repo ~/.git checkout
_abbr ycm  yadm --yadm-repo ~/.git checkout master
_abbr ycb  yadm --yadm-repo ~/.git checkout -b
# git }}}
# abbreviates }}}

# environments variables for interactive shells {{{
# don't set EDITOR, EDITOR has a higher priority than VISUAL in Homebrew
if type -q nvim
  _abbr vim nvim
  set -gx VISUAL nvim
  set -gx GIT_DIFF_TOOL nvimdiff
else
  set -gx VISUAL vim
  set -gx GIT_DIFF_TOOL vimdiff
end
set -gx ESH_SHELL /bin/bash
# environments variables for interactive shells }}}

# fish config {{{
set -g fish_greeting # set to null to disable greeting
set -g fish_key_bindings fish_vi_key_bindings
# fish config }}}

# starship initialize {{{
if type -q starship
  starship init fish | source
end
# starship initialize }}}

end # is-interactive }}}

# vim:ts=2:sw=2:ft=fish:fdm=marker:et
