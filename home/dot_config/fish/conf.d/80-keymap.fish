set -g fish_key_bindings fish_vi_key_bindings
function fish_user_key_bindings
    fish_default_key_bindings -M insert # set default key bindings for insert mode
    # then execute the vi-bindings so they take precedence when there's a conflict.
    fish_vi_key_bindings --no-erase insert
end
set -g fish_cursor_default block
set -g fish_cursor_insert line
set -g fish_cursor_replace underscore
set -g fish_cursor_replace_one underscore
