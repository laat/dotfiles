#!/usr/bin/env bash
# Claude Code status line.
# stdin: the status line JSON payload (see https://code.claude.com/docs/en/statusline)
# Shows: model initial + version (Opus 5 -> O 5) · dir · git branch (+ uncommitted changes) · context · 5h/7d limits · Fable weekly limit left.
#
# The Fable window is not part of the stdin payload, so it is read from the same
# endpoint /usage uses (/api/oauth/usage) and cached; the fetch runs in the
# background so the status line never blocks on the network.

set -u

input=$(cat)

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline"
usage_file="$cache_dir/usage.json"
lock_file="$cache_dir/usage.lock"
usage_ttl=300  # seconds before the usage cache is refreshed (undocumented endpoint; poll gently)

dim=$'\e[2m'; bold=$'\e[1m'; reset=$'\e[0m'
red=$'\e[31m'; yellow=$'\e[33m'; green=$'\e[32m'; cyan=$'\e[36m'; magenta=$'\e[35m'

# --- payload fields ---------------------------------------------------------
IFS=$'\t' read -r model cwd ctx_pct five_pct seven_pct has_limits < <(
  jq -r '[
    (.model.display_name // .model.id // "?"),
    (.workspace.current_dir // .cwd // "-"),
    (.context_window.used_percentage // "-" | if . == "-" then "-" else floor end),
    (.rate_limits.five_hour.used_percentage // "-" | if . == "-" then "-" else floor end),
    (.rate_limits.seven_day.used_percentage // "-" | if . == "-" then "-" else floor end),
    (if .rate_limits then "1" else "0" end)
  ] | map(tostring) | @tsv' <<<"$input"
)
# "-" marks an absent field (tab-separated reads collapse empty fields).
for v in cwd ctx_pct five_pct seven_pct; do [ "${!v}" = "-" ] && printf -v "$v" ''; done
model=${model#Claude }; ver=${model#* }; [ "$ver" = "$model" ] && ver=""; model=${model:0:1}${ver:+ $ver}  # "Opus 5" -> "O 5", "Fable 5.1" -> "F 5.1"

# --- git (mirrors zsh/.zshrc.d/prompt.zsh: (branch✗⚑), ✗ staged, ⚑ unstaged,
# ✗ replaces ⚑ when there are untracked files, tree icon in a linked worktree) --
git_part=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  gitdir=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null)
  common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  [ "$gitdir" != "$common" ] && branch=" ${branch}"
  staged=""; unstaged=""
  while IFS= read -r line; do
    x=${line:0:1}; y=${line:1:1}
    if [ "$x" = "?" ]; then unstaged="✗"; continue; fi
    [ "$x" != " " ] && staged="✗"
    [ "$y" != " " ] && [ "$unstaged" != "✗" ] && unstaged="⚑"
  done < <(git -C "$cwd" status --porcelain 2>/dev/null)
  git_part=" (${bold}${yellow}${branch}${reset}"
  [ -n "$staged$unstaged" ] && git_part+="${red}${staged}${unstaged}${reset}"
  git_part+=")"
fi

# --- usage colouring ---------------------------------------------------------
pct_color() {  # $1 = percent used
  if [ "$1" -ge 90 ]; then printf '%s' "$red"
  elif [ "$1" -ge 70 ]; then printf '%s' "$yellow"
  else printf '%s' "$green"; fi
}

fmt_left() {  # $1 = unix seconds of reset; prints "1d 3h" / "45m"
  local now secs d h m
  now=$(date +%s); secs=$(( $1 - now ))
  [ "$secs" -le 0 ] && { printf 'now'; return; }
  d=$(( secs / 86400 )); h=$(( (secs % 86400) / 3600 )); m=$(( (secs % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd %dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh %dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# --- Fable weekly window (from /api/oauth/usage, cached) ---------------------
refresh_usage() {
  mkdir -p "$cache_dir"
  # Skip if fresh, or if a refresh started in the last 30s.
  if [ -f "$usage_file" ] && [ -n "$(find "$usage_file" -newermt "-${usage_ttl} seconds" 2>/dev/null)" ]; then return; fi
  if [ -f "$lock_file" ] && [ -n "$(find "$lock_file" -newermt "-30 seconds" 2>/dev/null)" ]; then return; fi
  touch "$lock_file"
  (
    tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null \
          | jq -r '.claudeAiOauth.accessToken // empty')
    [ -z "$tok" ] && exit 0
    tmp="$usage_file.$$"
    # Headers go via a config on stdin so the token never shows up in `ps`.
    if printf 'header = "Authorization: Bearer %s"\nheader = "anthropic-beta: oauth-2025-04-20"\n' "$tok" \
       | curl -sf -m 5 -K - "https://api.anthropic.com/api/oauth/usage" -o "$tmp" \
       && jq -e . "$tmp" >/dev/null 2>&1; then
      mv -f "$tmp" "$usage_file"
    else
      rm -f "$tmp"
    fi
  ) >/dev/null 2>&1 &
  disown 2>/dev/null || true
}

fable_part=""
if [ "$has_limits" = "1" ]; then
  refresh_usage
  if [ -f "$usage_file" ]; then
    read -r f_pct f_reset < <(
      jq -r '
        (.limits // [] | map(select(.kind == "weekly_scoped"
                                    and (.scope.model.display_name // "" | ascii_downcase) == "fable")) | first)
        as $l
        | if $l == null then "- -"
          else "\($l.percent | floor) \($l.resets_at // "")" end' "$usage_file"
    )
    if [ "${f_pct:-"-"}" != "-" ]; then
      left=$(( 100 - f_pct ))
      reset_s=""
      if [ -n "$f_reset" ]; then
        # ISO 8601 with fractional seconds and +00:00 offset -> epoch
        iso=${f_reset%%.*}; reset_s=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$iso" +%s 2>/dev/null || true)
      fi
      fable_part=" ${dim}│${reset} $(pct_color "$f_pct")Fable ${left}% left${reset}"
      [ -n "$reset_s" ] && fable_part+=" ${dim}↻ $(fmt_left "$reset_s")${reset}"
    fi
  fi
fi

# --- assemble ----------------------------------------------------------------
out="${cyan}${model}${reset}"
[ -n "$cwd" ] && out+=" ${dim}${cwd##*/}${reset}"
out+="$git_part"
[ -n "$ctx_pct" ] && out+=" ${dim}│${reset} ctx $(pct_color "$ctx_pct")${ctx_pct}%${reset}"
if [ -n "$five_pct" ] || [ -n "$seven_pct" ]; then
  out+=" ${dim}│${reset}"
  [ -n "$five_pct" ]  && out+=" 5h $(pct_color "$five_pct")${five_pct}%${reset}"
  [ -n "$seven_pct" ] && out+=" 7d $(pct_color "$seven_pct")${seven_pct}%${reset}"
fi
out+="$fable_part"

printf '%s\n' "$out"
