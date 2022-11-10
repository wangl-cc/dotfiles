complete -c passwdgen -s h -l help -d "Print help message"
complete -c passwdgen -s e -l example -d "Print examples"

complete -c passwdgen -s p -l pattern -x -d "Pattern used to generate password"
complete -c passwdgen -s l -l length -x -d "Length of password"
complete -c passwdgen -s c -l charset -x -a "u l W d w s a" -d \
  "Charset used to generate password"
