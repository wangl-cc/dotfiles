# completion for bob, a version manager for neovim
complete -c bob -e

function __fish_bob_needs_command
  set -l cmd (commandline -opc)
  set -e cmd[1]
  if set -q cmd[1]
    return 1
  end
  return 0
end

function __fish_bob_using_command
  set -l cmd (commandline -opc)
  set -e cmd[1]
  if set -q cmd[1]; and contains -- $cmd[1] $argv
    return 0
  end
  return 1
end

complete -f -c bob -s h -l help -d "Print help information"
complete -f -c bob -n "__fish_bob_needs_command" -s V -l version -d "Print version information"

#  ls is aliased to list and uninstall is aliased to rm
# These are not included in the completion list to make sure
# that first characters are unique
set -l subcmds use install erase rm list help 
complete -f -c bob -n "__fish_bob_needs_command" -a use -d "Use a specific version of neovim"
complete -f -c bob -n "__fish_bob_needs_command" -a install -d "Install the specific versions of neovim"
complete -f -c bob -n "__fish_bob_needs_command" -a rm -d "Uninstall the specific version of neovim"
complete -f -c bob -n "__fish_bob_needs_command" -a erase -d "Erase any changes made by bob"
complete -f -c bob -n "__fish_bob_needs_command" -a list -d "List all installed and used versions of neovim"
complete -f -c bob -n "__fish_bob_needs_command" -a help -d "Print help of bob or a specific command"

# we can only use and uninstall if there is a version installed and not used
function __bob_list_installed
  echo (bob list | grep "Installed" | cut -d  "|" -f 1)
end

complete -f -c bob -n "__fish_bob_using_command help" -a "$subcmds"
complete -f -c bob -n "__fish_bob_using_command use rm" -a "$(__bob_list_installed)"
complete -f -c bob -n "__fish_bob_using_command install" -a "nightly stable"
complete -f -c bob -n "__fish_bob_using_command list erase" # prevent completion
