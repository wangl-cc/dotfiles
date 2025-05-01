# Completions for ssh-tunnel
# Place this file in ~/.config/fish/completions/ssh-tunnel.fish

# Main commands
set -l commands start stop restart status list help

# For generating port list completions - will return ports from existing tunnels
function __ssh_tunnel_list_ports
    # List all existing .conf files in the info directory
    set -l info_dir "$HOME/.local/state/ssh-tunnel/info"
    if test -d $info_dir
        find $info_dir -name "*.conf" | xargs -n1 basename | sed 's/\.conf$//'
    end
end

# Complete main commands
complete -f -c ssh-tunnel -n "not __fish_seen_subcommand_from $commands" -a start -d "Start a new SSH tunnel"
complete -f -c ssh-tunnel -n "not __fish_seen_subcommand_from $commands" -a stop -d "Stop an existing SSH tunnel"
complete -f -c ssh-tunnel -n "not __fish_seen_subcommand_from $commands" -a restart -d "Restart an existing SSH tunnel"
complete -f -c ssh-tunnel -n "not __fish_seen_subcommand_from $commands" -a status -d "Show status of a specific tunnel"
complete -f -c ssh-tunnel -n "not __fish_seen_subcommand_from $commands" -a list -d "List all SSH tunnels"
complete -f -c ssh-tunnel -n "not __fish_seen_subcommand_from $commands" -a help -d "Show usage information"

# Options for 'start' command
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s H -l remote-host -d "Remote host to connect to (Default: localhost)" -r
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s r -l remote-port -d "Port on the remote host (Required)" -r
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s l -l local-port -d "Local port to listen on, +N for relative" -r

# For stop/restart/status commands, complete with existing port numbers
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from stop" -a "(__ssh_tunnel_list_ports)" -d "Local port"
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from restart" -a "(__ssh_tunnel_list_ports)" -d "Local port"
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from status" -a "(__ssh_tunnel_list_ports)" -d "Local port"

# Common SSH options for 'start' command
# These are common SSH options that might be used with tunneling
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s i -d "Identity file" -r
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s p -d "Port to connect to on the remote host" -r
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s F -d "Specify alternative ssh config file" -r
complete -f -c ssh-tunnel -n "__fish_seen_subcommand_from start" -s o -d "Additional SSH options" -r
