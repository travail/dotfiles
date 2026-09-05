#!/bin/bash
set -euo pipefail
#
# Claude Code status line.
#
# Reads the session JSON on stdin and prints two lines:
#   1. model, reasoning effort, current branch and repository
#   2. context window usage, plan rate limits and session cost
#
# What each number on the second line measures:
#
#   🔋 ctx N%   How full this conversation's context window is right now.
#               Taken against context_window_size, which is 200k by default and
#               1M on models with extended context, and counted from input
#               tokens only: fresh input, cache writes and cache reads. Output
#               tokens are excluded, matching how Claude Code itself derives
#               used_percentage. This is a level rather than a running total --
#               /compact and /clear push it back down. Nearing 100% means
#               auto-compaction is close.
#
#   ⏳ plan 5h N% / 7d N%
#               How much of the subscription's rolling 5-hour and 7-day usage
#               allowances is already spent. Both windows count every session
#               inside the period, not just this one, so panes running side by
#               side add up here. Each window frees itself at its own resets_at;
#               at 100% that window is exhausted until it rolls over.
#
#   💰 $N       Estimated cost of this session in USD, computed client-side at
#               list price. On a subscription it is a yardstick for how much
#               work a session represents, not an amount that gets billed.
#
# Every percentage is "used", never "remaining", and is labelled with what it
# measures. The leading emoji are static category markers rather than gauges,
# so a full battery never reads as a full context window.
#
# Fields that Claude Code omits (rate limits before the first API response,
# effort on models without the parameter, repo outside a git checkout) drop
# their segment instead of printing a placeholder.
#
# Input schema: https://docs.claude.com/en/docs/claude-code/statusline

RESET=$'\033[0m'
DIM=$'\033[2m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
CYAN=$'\033[36m'

# Warn above this share of a window, and alert above the second threshold.
WARN_PCT=60
ALERT_PCT=80

input=$(cat)

model=""
effort=""
repo=""
cwd=""
project_dir=""
ctx=""
five_hour=""
seven_day=""
cost="0"

# One jq pass emits shell assignments; @sh quotes each interpolated value.
# Absent objects index to null in jq, so a missing .rate_limits is not an error.
assignments=$(printf '%s' "$input" | jq -r '
  def pct: if . == null then "" else (round | tostring) end;
  @sh "model=\(.model.display_name // "")",
  @sh "effort=\(.effort.level // "")",
  @sh "repo=\(.workspace.repo.name // "")",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "ctx=\(.context_window.used_percentage | pct)",
  @sh "five_hour=\(.rate_limits.five_hour.used_percentage | pct)",
  @sh "seven_day=\(.rate_limits.seven_day.used_percentage | pct)",
  @sh "cost=\(.cost.total_cost_usd // 0)"
' 2>/dev/null) || assignments=""
eval "$assignments"

# The branch is the one field the JSON does not carry, so ask git directly.
# Anchor it to the session directory: the script's own cwd is not guaranteed.
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null) || branch=""
fi

if [ -z "$repo" ] && [ -n "$project_dir" ]; then
  repo=$(basename "$project_dir")
fi

pct_color() {
  if [ "$1" -ge "$ALERT_PCT" ]; then
    printf '%s' "$RED"
  elif [ "$1" -ge "$WARN_PCT" ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# Line 1: what this session is.
line1=""
if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    line1="${CYAN}${model}·${effort}${RESET}"
  else
    line1="${CYAN}${model}${RESET}"
  fi
fi

# The branch comes first and the separator is padded, so a double click selects
# the branch name alone without dragging the repository name along with it.
location=""
if [ -n "$branch" ] && [ -n "$repo" ]; then
  location="${branch} ${DIM}/${RESET} ${repo}"
elif [ -n "$branch" ]; then
  location="$branch"
elif [ -n "$repo" ]; then
  location="$repo"
fi

if [ -n "$location" ]; then
  if [ -n "$line1" ]; then
    line1="${line1}  ${location}"
  else
    line1="$location"
  fi
fi

# Line 2: what this session has spent.
segments=()

if [ -n "$ctx" ]; then
  segments+=("🔋 ctx $(pct_color "$ctx")${ctx}%${RESET}")
fi

plan=""
if [ -n "$five_hour" ]; then
  plan="5h $(pct_color "$five_hour")${five_hour}%${RESET}"
fi
if [ -n "$seven_day" ]; then
  if [ -n "$plan" ]; then
    plan="${plan} ${DIM}·${RESET} "
  fi
  plan="${plan}7d $(pct_color "$seven_day")${seven_day}%${RESET}"
fi
if [ -n "$plan" ]; then
  segments+=("⏳ plan ${plan}")
fi

cost_display=$(printf '%.2f' "$cost" 2>/dev/null) || cost_display=""
if [ -n "$cost_display" ]; then
  segments+=("💰 \$${cost_display}")
fi

line2=""
for segment in ${segments[@]+"${segments[@]}"}; do
  if [ -z "$line2" ]; then
    line2="$segment"
  else
    line2="${line2}  ${segment}"
  fi
done

if [ -n "$line1" ]; then
  printf '%s\n' "$line1"
fi
if [ -n "$line2" ]; then
  printf '%s\n' "$line2"
fi
