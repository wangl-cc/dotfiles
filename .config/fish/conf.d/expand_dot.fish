function expand_dot
    string repeat -n (math (string length -- $argv[1]) - 1) ../
end
