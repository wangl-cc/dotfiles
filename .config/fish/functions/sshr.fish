function sshr --description "ssh with remote forward"
  set -l port (random 10000 30000)
  printf "Use port %d for remote forward" $port
  ssh -t -R $port:localhost:22 -o RemoteCommand="
  export SHELL=/home/%r/.local/bin/$(basename $SHELL) \
    SSHR_PORT=$port \
    LC_HOST=$USER\@localhost LC_OS=(uname -s) \
    TERM_PROGRAM=$TERM_PROGRAM;
  exec \$SHELL -l" $argv
end
