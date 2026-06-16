#!/usr/bin/env bash
# Claude Code statusLine script — mirrors starship prompt modules
# Receives Claude Code JSON on stdin

input=$(cat)

# ── fields from Claude Code JSON ──────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // .model.id // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ── helpers ───────────────────────────────────────────────────────────────────
# Shorten path: replace $HOME with ~, then abbreviate intermediate components
shorten_path() {
  local path="$1"
  path="${path/#$HOME/\~}"
  # Split on / and abbreviate everything except the last component
  local IFS='/'
  read -ra parts <<< "$path"
  local n=${#parts[@]}
  local result=""
  for (( i=0; i<n-1; i++ )); do
    local seg="${parts[$i]}"
    if [[ "$seg" == "~" || "$seg" == "" ]]; then
      result+="$seg/"
    else
      result+="${seg:0:1}/"
    fi
  done
  result+="${parts[$n-1]}"
  echo "$result"
}

# ── ANSI colours (starship dark-ansi-like palette) ───────────────────────────
reset='\e[0m'
bold='\e[1m'
dim='\e[2m'
cyan='\e[36m'
green='\e[32m'
yellow='\e[33m'
blue='\e[34m'
magenta='\e[35m'
red='\e[31m'
white='\e[37m'

# ── user ──────────────────────────────────────────────────────────────────────
user_str="$(whoami)"

# ── directory ─────────────────────────────────────────────────────────────────
dir_str="$(shorten_path "$cwd")"

# ── git branch + status ───────────────────────────────────────────────────────
git_part=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  # Compact status indicators matching your starship git_status glyphs
  status_flags=""
  git_status_output=$(git -C "$cwd" status --porcelain=v1 2>/dev/null)

  staged_count=$(echo "$git_status_output" | grep -c '^[MADRCU]' 2>/dev/null || echo 0)
  modified_count=$(echo "$git_status_output" | grep -c '^.[MD]' 2>/dev/null || echo 0)
  untracked_count=$(echo "$git_status_output" | grep -c '^??' 2>/dev/null || echo 0)
  deleted_count=$(echo "$git_status_output" | grep -c '^.D\|^D.' 2>/dev/null || echo 0)
  renamed_count=$(echo "$git_status_output" | grep -c '^R' 2>/dev/null || echo 0)

  ahead_behind=$(git -C "$cwd" rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null || echo "")
  ahead=0; behind=0
  if [[ -n "$ahead_behind" ]]; then
    behind=$(echo "$ahead_behind" | awk '{print $1}')
    ahead=$(echo "$ahead_behind"  | awk '{print $2}')
  fi

  [[ "$ahead"    -gt 0 ]] && status_flags+="󰳢 ${ahead} "   # arrow_up_circle_outline
  [[ "$behind"   -gt 0 ]] && status_flags+="󰳜 ${behind} "  # arrow_down_circle_outline
  [[ "$staged_count"   -gt 0 ]] && status_flags+="󰗡 ${staged_count} "   # check_circle_outline
  [[ "$modified_count" -gt 0 ]] && status_flags+="󰝶 ${modified_count} " # pencil_circle_outline
  [[ "$deleted_count"  -gt 0 ]] && status_flags+="󰍷 ${deleted_count} "  # minus_circle_outline
  [[ "$renamed_count"  -gt 0 ]] && status_flags+="󰳠 ${renamed_count} "  # arrow_right_circle_outline
  [[ "$untracked_count" -gt 0 ]] && status_flags+="󰐙 ${untracked_count} " # plus_circle_outline

  git_part="on 󰘬 ${branch} ${status_flags}"
fi

# ── model ─────────────────────────────────────────────────────────────────────
model_part=""
[[ -n "$model" ]] && model_part="[${model}]"

# ── context window ────────────────────────────────────────────────────────────
ctx_part=""
if [[ -n "$used_pct" ]]; then
  used_int=$(printf '%.0f' "$used_pct")
  if   [[ "$used_int" -ge 80 ]]; then ctx_color="$red"
  elif [[ "$used_int" -ge 50 ]]; then ctx_color="$yellow"
  else                                 ctx_color="$green"
  fi
  ctx_part="ctx:${used_int}%"
fi

# ── assemble ──────────────────────────────────────────────────────────────────
# Format: user at dir on  branch <git flags> ── [model] ctx:N%
printf "${bold}${white}%s${reset}" "$user_str"
printf " ${dim}at${reset} "
printf "${bold}${cyan}%s${reset}" "$dir_str"
if [[ -n "$git_part" ]]; then
  printf " ${dim}on${reset} ${bold}${magenta}󰘬 %s${reset}" "$branch"
  [[ -n "$status_flags" ]] && printf " ${yellow}%s${reset}" "${status_flags% }"
fi
printf " ${dim}──${reset}"
[[ -n "$model_part" ]] && printf " ${blue}%s${reset}" "$model_part"
if [[ -n "$ctx_part" ]]; then
  printf " ${ctx_color}%s${reset}" "$ctx_part"
fi
printf "\n"
