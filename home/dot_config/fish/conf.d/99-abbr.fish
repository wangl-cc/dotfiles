status is-interactive; or return

abbr --add -- tx tar -xf
abbr --add -- tc tar -cf

if type -q eza
    alias eza 'eza --icons auto --group-directories-first'
    abbr --add -- l eza
    abbr --add -- ll eza -l
    abbr --add -- la eza -Al
    abbr --add -- lt eza -snew -l
    abbr --add -- lat eza -snew -Al
    abbr --add -- tree eza --tree
else
    abbr --add l -- ls --color
    abbr --add ll -- ls --color -lh
    abbr --add la -- ls --color -Alh
    abbr --add lt -- ls --color -trl
    abbr --add lat -- ls --color -Altr
end

function expand_dot
    string repeat -n (math (string length -- $argv[1]) - 1) ../
end
abbr --add --function expand_dot --regex '^\.\.+$' -- dots

abbr --add -- g git
abbr --add -- ga git add
abbr --add -- gaa git add --all
abbr --add -- gb git branch
abbr --add -- gba git branch -a
abbr --add -- gbd git branch -d
abbr --add -- gbl git branch -l
abbr --add -- gc git commit
abbr --add -- gcl git clone
abbr --add -- gco git checkout
abbr --add -- gcb git checkout -b
abbr --add -- gcm git checkout main
abbr --add -- gci git check-ignore -v
abbr --add -- gd git diff
abbr --add -- gds git diff --staged
abbr --add -- gl git log
abbr --add -- gp git push
abbr --add -- gpt git push --tags
abbr --add -- gpl git pull --ff-only
abbr --add -- gr git remote
abbr --add -- grv git remote -v
abbr --add -- gra git remote add
abbr --add -- grpo git remote prune origin
abbr --add -- grb git rebase
abbr --add -- grbm git rebase origin/main
abbr --add -- gs git status
abbr --add -- gsu git status -u
abbr --add -- gt git tag
type -q lazygit; and abbr --add -- gg lazygit

if type -q brew
    abbr --add -- b brew
    abbr --add -- bc brew cleanup
    abbr --add -- bca brew cleanup --prune=all
    abbr --add -- bi brew install
    abbr --add -- bl brew leaves
    abbr --add -- bls brew list
    abbr --add -- blc brew list --cask
    abbr --add -- br brew remove
    abbr --add -- bs brew search
    abbr --add -- bu brew upgrade
end

if type -q julia
    abbr --add -- jl julia
    abbr --add -- jp julia --project
end

if type -q cargo
    abbr --add -- c cargo
    abbr --add -- ca cargo add
    abbr --add -- crm cargo remove
    abbr --add -- cr cargo run
    abbr --add -- cb cargo build
    abbr --add -- ccl cargo clean
    abbr --add -- cck cargo check
    abbr --add -- cf cargo +nightly fmt
    abbr --add -- ct cargo test
    if type -q cargo-nextest
        abbr --add -- cnt cargo nextest run
    else
    end
    abbr --add -- ci cargo install
    abbr --add -- cil cargo install --locked
    abbr --add -- cl cargo install --list
    abbr --add -- clp cargo clippy --all-targets -- -D warnings
    abbr --add -- cu cargo uninstall
    abbr --add -- cup cargo update
end

if type -q chezmoi
    abbr --add -- cz chezmoi
    abbr --add -- cza chezmoi add
end
