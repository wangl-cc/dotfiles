# test if __fish_conda_root is set
# if not, use $HOME/Conda as default
set -l __CONDA_ROOT
if set -q __fish_conda_root
  set __CONDA_ROOT $__fish_conda_root
else
  set __CONDA_ROOT $HOME/Conda
end

set -gx CONDA_EXE $__CONDA_ROOT/bin/conda

# test if conda is installed
if not test -x $CONDA_EXN
  set -e CONDA_EXE
  return
end

set -gx CONDA_PYTHON_EXE $__CONDA_ROOT/bin/python

# avoid set PATH multiple times
if not set -q CONDA_SHLVL
  set -gx CONDA_SHLVL 0
  set -gx PATH $__CONDA_ROOT/condabin $PATH
end

function conda --inherit-variable CONDA_EXE
  if [ (count $argv) -lt 1 ]
    $CONDA_EXE
  else
    set -l cmd $argv[1]
    set -e argv[1]
    switch $cmd
      case activate deactivate
        eval ($CONDA_EXE shell.fish $cmd $argv)
      case install update upgrade remove uninstall
        $CONDA_EXE $cmd $argv
        and eval ($CONDA_EXE shell.fish reactivate)
      case '*'
        $CONDA_EXE $cmd $argv
    end
  end
end

conda activate base

# vim:sw=2:ts=2:et
