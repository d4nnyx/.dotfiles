#!/bin/bash

# Claude Code two-line statusline
# Line 1: directory, git branch, model
# Line 2: context progress bar, cost, duration

input=$(cat)

# --- Parse JSON fields ---
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Token counts from context window usage
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')

# Ensure numeric defaults
pct=${pct%.*}  # truncate to int
[ -z "$pct" ] || [ "$pct" = "null" ] && pct=0
[ -z "$duration_ms" ] || [ "$duration_ms" = "null" ] && duration_ms=0
[ "$input_tokens" = "null" ] && input_tokens=0
[ "$cache_creation" = "null" ] && cache_creation=0
[ "$cache_read" = "null" ] && cache_read=0
[ "$output_tokens" = "null" ] && output_tokens=0

# --- Directory (shorten home to ~) ---
display_dir="${dir/#$HOME/\~}"

# --- Git branch (cached 5s) ---
branch=""
if [ -n "$dir" ] && [ -d "$dir" ]; then
  cache_key=$(echo "$dir" | md5 -q 2>/dev/null || echo "$dir" | md5sum 2>/dev/null | cut -d' ' -f1)
  cache_file="/tmp/claude-statusline-git-${cache_key}"

  if [ -f "$cache_file" ] && [ "$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null || echo 0) ))" -lt 5 ]; then
    branch=$(cat "$cache_file")
  else
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
    echo "$branch" > "$cache_file"
  fi
fi

# --- Duration formatting ---
total_sec=$((duration_ms / 1000))
if [ "$total_sec" -ge 3600 ]; then
  hrs=$((total_sec / 3600))
  mins=$(( (total_sec % 3600) / 60 ))
  secs=$((total_sec % 60))
  duration_str="${hrs}h ${mins}m ${secs}s"
elif [ "$total_sec" -ge 60 ]; then
  mins=$((total_sec / 60))
  secs=$((total_sec % 60))
  duration_str="${mins}m ${secs}s"
else
  duration_str="${total_sec}s"
fi

# --- Token count formatting ---
total_tokens=$((input_tokens + cache_creation + cache_read + output_tokens))
if [ "$total_tokens" -ge 1000000 ]; then
  token_str="$(( total_tokens / 1000000 )).$(( (total_tokens % 1000000) / 100000 ))M"
elif [ "$total_tokens" -ge 1000 ]; then
  token_str="$(( total_tokens / 1000 ))k"
else
  token_str="${total_tokens}"
fi
token_str="${token_str} tokens"

# --- Lightsaber (fixed blade, color by usage tier) ---
# Color: green <25%, blue 25-49%, magenta 50-74%, red 75%+
if [ "$pct" -ge 75 ]; then
  blade_color='\e[31m'  # red
elif [ "$pct" -ge 50 ]; then
  blade_color='\e[35m'  # magenta
elif [ "$pct" -ge 25 ]; then
  blade_color='\e[34m'  # blue
else
  blade_color='\e[32m'  # green
fi

bar="\e[2m▬▬ι\e[0m${blade_color}═══════════════\e[0m"

# --- Line 1: directory, branch, model ---
line1="\e[33m${display_dir}\e[0m"
if [ -n "$branch" ]; then
  line1+=" | \e[35m${branch}\e[0m"
fi
if [ -n "$model" ]; then
  line1+=" | \e[36m${model}\e[0m"
fi

# --- Line 2: lightsaber bar, tokens, duration ---
line2="${bar} ${pct}% | \e[33m${token_str}\e[0m | \e[2m${duration_str}\e[0m"

# --- Output ---
printf '%b\n%b\n' "$line1" "$line2"
