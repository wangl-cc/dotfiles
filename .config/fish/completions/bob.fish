# completion for bob, a version manager for neovim
complete -c bob -e

# Options
# -h, --help, it's available for bob and all subcommands
complete -f -c bob -s h -l help -d "Print help information"
# -V, --version, it's only available for bob
complete -f -c bob -n "__fish_use_subcommand" -s V -l version -d "Print version information"

# ls is aliased to list and uninstall is aliased to rm
# These are not included in the completion list to make sure
# that first characters are unique
set -l subcmds use install sync uninstall rm rollback erase list ls help
complete -f -c bob -n "__fish_use_subcommand" -a use -d "Use a specific version of neovim"
complete -f -c bob -n "__fish_use_subcommand" -a install -d "Install the specific versions of neovim"
complete -f -c bob -n "__fish_use_subcommand" -a sync -d "Sync the installed versions of neovim with the versions in the config file"
complete -f -c bob -n "__fish_use_subcommand" -a rm -d "Uninstall the specific version of neovim"
complete -f -c bob -n "__fish_use_subcommand" -a rollback -d "Rollback to and existing nightly rollback"
complete -f -c bob -n "__fish_use_subcommand" -a erase -d "Erase any changes made by bob"
complete -f -c bob -n "__fish_use_subcommand" -a list -d "List all installed and used versions of neovim"
complete -f -c bob -n "__fish_use_subcommand" -a help -d "Print help of bob or a specific command"

# we can only use and uninstall if there is a version installed and not used
function __bob_list_installed
  bob list | sed '1,3d' | sed '$d' | awk '{print $2}'
end

complete -f -c bob -n "__fish_seen_subcommand_from help" -a "$subcmds"
complete -f -c bob -n "__fish_seen_subcommand_from use rm" -a "$(__bob_list_installed)"
complete -f -c bob -n "__fish_seen_subcommand_from install" -a "nightly stable"
complete -f -c bob -n "__fish_seen_subcommand_from sync rollback list erase" # prevent completion
