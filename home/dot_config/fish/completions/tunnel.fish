# Completions for tunnel

# Main commands
set -l commands start stop restart status list help

# For generating port list completions - will return ports from existing tunnels
function __tunnel_list_ports
    # List all existing .conf files in the info directory
    set -l info_dir "$HOME/.local/state/tunnel/info"
    if test -d $info_dir
        find $info_dir -name "*.conf" -print0 | xargs -0 -n1 basename | sed 's/\.conf$//'
    end
end

# Complete main commands
complete -c tunnel -n "not __fish_seen_subcommand_from $commands" -a start -d "Start a new tunnel" -f
complete -c tunnel -n "not __fish_seen_subcommand_from $commands" -a stop -d "Stop an existing tunnel by local port(s)" -f
complete -c tunnel -n "not __fish_seen_subcommand_from $commands" -a restart -d "Restart an existing tunnel by local port(s)" -f
complete -c tunnel -n "not __fish_seen_subcommand_from $commands" -a status -d "Show status of a specific tunnel by local port" -f
complete -c tunnel -n "not __fish_seen_subcommand_from $commands" -a list -d "List all tunnels" -f
complete -c tunnel -n "not __fish_seen_subcommand_from $commands" -a help -d "Show usage information" -f

# --- Options for 'start' command ---

complete -c tunnel -n "__fish_seen_subcommand_from start" -f # force no file completion

# Required options for all tunnel types
complete -c tunnel -n "__fish_seen_subcommand_from start" -s t -l tunnel-type -d "Tunnel type (Required)" -r -f -a "ssh cloudflare"
complete -c tunnel -n "__fish_seen_subcommand_from start" -s n -l hostname -d "Hostname for tunnel (Required)" -r -f
complete -c tunnel -n "__fish_seen_subcommand_from start" -s l -l local-port -d "Local port (Required for cloudflare, defaults to remote port for ssh)" -r -f

# SSH specific options
complete -c tunnel -n "__fish_seen_subcommand_from start" -s H -l remote-host -d "[SSH] Remote host (Default: localhost)" -r -f
complete -c tunnel -n "__fish_seen_subcommand_from start" -s r -l remote-port -d "[SSH] Remote port (Required for ssh)" -r -f

# Common SSH options (passed directly to ssh when type is ssh)
complete -c tunnel -n "__fish_seen_subcommand_from start" -s i -d "[SSH] Identity file (passed to ssh)" -r
complete -c tunnel -n "__fish_seen_subcommand_from start" -s F -d "[SSH] Alternative ssh config file (passed to ssh)" -r
complete -c tunnel -n "__fish_seen_subcommand_from start" -s p -d "[SSH] Port for ssh connection (passed to ssh)" -r -f
complete -c tunnel -n "__fish_seen_subcommand_from start" -s o -d "[SSH] Additional SSH options (passed to ssh)" -r -f

# --- Argument completions for other commands ---

# For stop/restart/status commands, complete with existing port numbers
complete -c tunnel -n "__fish_seen_subcommand_from stop" -a "(__tunnel_list_ports)" -d "Local port(s)" -f
complete -c tunnel -n "__fish_seen_subcommand_from restart" -a "(__tunnel_list_ports)" -d "Local port(s)" -f
complete -c tunnel -n "__fish_seen_subcommand_from status" -a "(__tunnel_list_ports)" -d "Local port" -f

# For list commands, force no file completion
complete -c tunnel -n "__fish_seen_subcommand_from list" -f # force no file completion
