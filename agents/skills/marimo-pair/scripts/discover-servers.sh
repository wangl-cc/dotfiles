#!/usr/bin/env bash
# List running marimo instances.
#
# Primary source: marimo's local server registry. Authenticated servers do not
# register there by design, so if the registry is empty this script falls back
# to probing local listening ports for marimo's HTTP endpoints.
# No marimo installation required.
set -euo pipefail

# Locate the servers directory
is_windows=false
if [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
  is_windows=true
  servers_dir="$HOME/.marimo/servers"
else
  servers_dir="${XDG_STATE_HOME:-$HOME/.local/state}/marimo/servers"
fi

# Liveness check. On POSIX, `kill -0 $pid` is cheap and reliable. On Windows
# (Git Bash/MSYS2) `kill` operates on Cygwin PIDs, not the native Windows PIDs
# marimo writes, so fall back to an HTTP probe against marimo's /health.
check_live() {
  local f="$1"
  if [[ "$is_windows" == false ]]; then
    local pid
    pid=$(jq -r '.pid' "$f" 2>/dev/null) || return 1
    kill -0 "$pid" 2>/dev/null
  else
    local host port base_url
    host=$(jq -r '.host' "$f" 2>/dev/null) || return 1
    port=$(jq -r '.port' "$f" 2>/dev/null) || return 1
    base_url=$(jq -r '.base_url' "$f" 2>/dev/null) || return 1
    curl -sf --max-time 1 "http://${host}:${port}${base_url}/health" >/dev/null 2>&1
  fi
}

probe_marimo_http() {
  local host="$1"
  local port="$2"
  local base="http://${host}:${port}"

  curl -sf --max-time 0.5 "${base}/health" >/dev/null 2>&1 || return 1

  local version=""
  version=$(curl -sf --max-time 0.5 "${base}/api/version" 2>/dev/null || true)
  if [[ -z "$version" || "$version" != *.* ]]; then
    local sessions_status
    sessions_status=$(curl -s -o /dev/null -w '%{http_code}' --max-time 0.5 "${base}/api/sessions" 2>/dev/null || true)
    [[ "$sessions_status" == "200" || "$sessions_status" == "401" || "$sessions_status" == "403" ]] || return 1
  fi

  local sessions="{}"
  sessions=$(curl -sf --max-time 0.5 "${base}/api/sessions" 2>/dev/null || echo "{}")
  jq -n \
    --arg server_id "127.0.0.1:${port}" \
    --argjson port "$port" \
    --arg version "$version" \
    --argjson sessions "$sessions" \
    '{
      server_id: $server_id,
      pid: null,
      host: "127.0.0.1",
      port: $port,
      base_url: "",
      started_at: null,
      version: (if ($version | length) > 0 then $version else null end),
      source: "port-probe",
      sessions: $sessions
    }'
}

list_listening_ports() {
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null \
      | awk 'NR > 1 {print $9}' \
      | sed -nE 's/.*:([0-9]+)$/\1/p' \
      | sort -nu
  else
    seq 2718 2738
  fi
}

registry_results="[]"
if [[ -d "$servers_dir" ]]; then
for f in "$servers_dir"/*.json; do
  [[ -e "$f" ]] || continue

  if ! check_live "$f"; then
    # On Windows the HTTP probe can fail transiently (slow start, busy server),
    # so keep the entry; only POSIX `kill -0` is reliable enough to delete on.
    [[ "$is_windows" == false ]] && rm -f "$f"
    continue
  fi

  entry=$(jq '.' "$f" 2>/dev/null) || continue
  registry_results=$(echo "$registry_results" | jq --argjson e "$entry" '. + [$e]')
done
fi

if [[ "$(echo "$registry_results" | jq 'length')" -gt 0 ]]; then
  echo "$registry_results" | jq .
  exit 0
fi

probe_results="[]"
for port in $(list_listening_ports); do
  [[ "$port" =~ ^[0-9]+$ ]] || continue
  entry=$(probe_marimo_http "127.0.0.1" "$port" 2>/dev/null || true)
  [[ -n "$entry" ]] || continue
  probe_results=$(echo "$probe_results" | jq --argjson e "$entry" '. + [$e]')
done

echo "$probe_results" | jq .
