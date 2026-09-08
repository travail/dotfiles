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
#   ctx N%      How full this conversation's context window is right now.
#               Taken against context_window_size, which is 200k by default and
#               1M on models with extended context, and counted from input
#               tokens only: fresh input, cache writes and cache reads. Output
#               tokens are excluded, matching how Claude Code itself derives
#               used_percentage. This is a level rather than a running total --
#               /compact and /clear push it back down. Nearing 100% means
#               auto-compaction is close.
#
#   5h N% (2h13m) / 7d N% (3d11h20m)
#               How much of the subscription's rolling 5-hour and 7-day usage
#               allowances is already spent. Both windows count every session
#               inside the period, not just this one, so panes running side by
#               side add up here. Each window frees itself at its own resets_at;
#               at 100% that window is exhausted until it rolls over.
#
#               The time in parentheses is how long that rollover is away,
#               derived from resets_at against the current clock. It is relative
#               and never an absolute time of day: what a full window costs is
#               the wait, not the hour it ends. Claude Code drops a window from
#               the JSON once it has rolled over, so a negative remainder should
#               not arise, but the boundary is clamped to zero regardless.
#
#               A remainder counts down between messages, so the status line
#               needs to re-run while the session sits idle. That is what
#               refreshInterval in the statusLine settings is for. The used
#               percentages cannot be kept fresh the same way -- they only
#               change when Claude Code hands over new JSON -- but a remainder
#               is a fixed instant minus the clock, so recomputing it locally
#               is enough.
#
#   $N          Estimated cost of this session in USD, computed client-side at
#               list price. On a subscription it is a yardstick for how much
#               work a session represents, not an amount that gets billed.
#
# Every percentage is "used", never "remaining", and no segment carries an
# emoji. A marker sitting in front of a group of numbers reads as qualifying
# the first of them alone: an hourglass ahead of "5h 61% / 7d 42%" looked as
# though it belonged to the five-hour window, though it applied to both. The
# words and units already say what each number measures, so the markers were
# paying for themselves with ambiguity.
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
five_hour_resets=""
seven_day=""
seven_day_resets=""
cost="0"

# One jq pass emits shell assignments; @sh quotes each interpolated value.
# Absent objects index to null in jq, so a missing .rate_limits is not an error.
assignments=$(printf '%s' "$input" | jq -r '
  def pct: if . == null then "" else (round | tostring) end;
  def epoch: if type == "number" then (floor | tostring) else "" end;
  @sh "model=\(.model.display_name // "")",
  @sh "effort=\(.effort.level // "")",
  @sh "repo=\(.workspace.repo.name // "")",
  @sh "cwd=\(.workspace.current_dir // "")",
  @sh "project_dir=\(.workspace.project_dir // "")",
  @sh "ctx=\(.context_window.used_percentage | pct)",
  @sh "five_hour=\(.rate_limits.five_hour.used_percentage | pct)",
  @sh "five_hour_resets=\(.rate_limits.five_hour.resets_at | epoch)",
  @sh "seven_day=\(.rate_limits.seven_day.used_percentage | pct)",
  @sh "seven_day_resets=\(.rate_limits.seven_day.resets_at | epoch)",
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

# How long until the given epoch second, as "3d11h20m", "2h13m" or "6m".
# Larger units are dropped once they are zero, so a five-hour window never
# prints a leading "0d". Under a minute reads as "<1m" rather than rounding to
# zero, which would look like a window that has already rolled over; an instant
# already past clamps to "0m".
remaining_time() {
  local target=$1 now=$2 rest days hours minutes
  rest=$((target - now))
  if [ "$rest" -le 0 ]; then
    printf '0m'
    return
  fi
  if [ "$rest" -lt 60 ]; then
    printf '<1m'
    return
  fi
  days=$((rest / 86400))
  hours=$((rest % 86400 / 3600))
  minutes=$((rest % 3600 / 60))
  if [ "$days" -gt 0 ]; then
    printf '%dd%dh%dm' "$days" "$hours" "$minutes"
  elif [ "$hours" -gt 0 ]; then
    printf '%dh%dm' "$hours" "$minutes"
  else
    printf '%dm' "$minutes"
  fi
}

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
  segments+=("ctx $(pct_color "$ctx")${ctx}%${RESET}")
fi

now=$(date +%s)

plan=""
if [ -n "$five_hour" ]; then
  plan="5h $(pct_color "$five_hour")${five_hour}%${RESET}"
  if [ -n "$five_hour_resets" ]; then
    plan="${plan} ${DIM}($(remaining_time "$five_hour_resets" "$now"))${RESET}"
  fi
fi
if [ -n "$seven_day" ]; then
  if [ -n "$plan" ]; then
    plan="${plan} ${DIM}·${RESET} "
  fi
  plan="${plan}7d $(pct_color "$seven_day")${seven_day}%${RESET}"
  if [ -n "$seven_day_resets" ]; then
    plan="${plan} ${DIM}($(remaining_time "$seven_day_resets" "$now"))${RESET}"
  fi
fi
if [ -n "$plan" ]; then
  segments+=("$plan")
fi

cost_display=$(printf '%.2f' "$cost" 2>/dev/null) || cost_display=""
if [ -n "$cost_display" ]; then
  segments+=("\$${cost_display}")
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
