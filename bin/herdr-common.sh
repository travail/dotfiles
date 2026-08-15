# Shared helpers for herdr-init / herdr-spawn-agent. Source only, not
# executable. Callers must have `set -euo pipefail` in effect.

# spawn_and_prime_agent PANE_ID [PRIME=1]
#   Spawns `claude` in PANE_ID, clears the one-time trust-dialog prompt if it
#   appears, and waits for the agent to go idle. Unless PRIME=0, also sends
#   `/herdr` and `/herdr-hub` (in that order) to preload the herdr CLI skill
#   and our own multi-agent coordination conventions, waiting idle again
#   after each.
spawn_and_prime_agent() {
  local pane="$1" prime="${2:-1}"

  # HERDR_PRIMED=1 is a hard signal (distinct from HERDR_ENV=1, which just
  # means "running inside a herdr-managed pane") that /herdr and /herdr-hub
  # were actually sent to this pane by this function -- set only when we're
  # actually about to prime (prime=1), so a caller can check it instead of
  # assuming priming happened just because HERDR_ENV=1 is set (e.g. a pane
  # started by running `claude` directly was never routed through here).
  if [ "$prime" -eq 1 ]; then
    herdr pane run "$pane" "HERDR_PRIMED=1 claude" >&2
  else
    herdr pane run "$pane" "claude" >&2
  fi

  # herdr needs a moment to detect the freshly spawned agent -- `herdr agent
  # wait` errors immediately (no retry) if the target isn't registered yet,
  # so some polling is unavoidable here regardless of trust state.
  #
  # The first run in a not-yet-trusted directory additionally shows a
  # one-time trust prompt (herdr reports agent_status idle even while that
  # prompt is up), and `herdr agent get` can succeed *before* the prompt has
  # even been rendered, so a single successful check isn't proof the prompt
  # won't show up -- that path polls for the prompt text and requires a few
  # consecutive clean reads. Once a directory is trusted (per
  # ~/.claude.json), the prompt can never show again for it, so that check
  # is skipped entirely -- just poll for the agent to be detected.
  #
  # cwd is looked up per-pane (not passed in by the caller) so this works
  # whether it's called against herdr-init's root pane or a pane
  # herdr-spawn-agent just split off elsewhere.
  local dir trusted
  dir=$(herdr pane get "$pane" | jq -r '.result.pane.cwd')
  trusted=$(jq -r --arg d "$dir" '.projects[$d].hasTrustDialogAccepted // false' \
            "$HOME/.claude.json" 2>/dev/null || echo false)

  if [ "$trusted" = "true" ]; then
    for _ in $(seq 1 150); do
      herdr agent get "$pane" >/dev/null 2>&1 && break
      sleep 0.1
    done
  else
    local clean_checks=0
    for _ in $(seq 1 150); do
      if herdr pane read "$pane" --source recent --lines 20 2>/dev/null | grep -q "trust this folder"; then
        herdr pane send-keys "$pane" Enter
        clean_checks=0
        sleep 0.1
        continue
      fi
      clean_checks=$((clean_checks + 1))
      if [ "$clean_checks" -ge 4 ] && herdr agent get "$pane" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
    done
  fi
  herdr agent wait "$pane" --until idle --timeout 15000 >&2

  if [ "$prime" -eq 1 ]; then
    # Prime the agent with the herdr and herdr-hub skills up front, so it can
    # act as hub (dispatch to/pull from sibling panes) without the user
    # having to explain herdr in the task prompt. herdr-hub carries our own
    # coordination conventions (push/pull discipline, spawn-agent usage,
    # timeout handling, etc.) layered on top of herdr's generic CLI
    # reference -- both are separate skills invoked by name, so both need
    # priming here; neither loads on its own.
    #
    # A freshly spawned agent can report idle (via the wait right above)
    # slightly before its terminal UI is actually ready to receive input --
    # sending a slash command right at that instant can silently go nowhere
    # (verified empirically: the pane's prompt stays completely empty,
    # never even shows the command having been typed). Give it a moment to
    # settle, then confirm the agent actually transitioned to working
    # (proof the input was received and processing started, not just that
    # it was still sitting idle) -- retrying the send a couple of times if
    # it doesn't.
    sleep 1
    local skill primed
    for skill in herdr herdr-hub; do
      primed=0
      for _ in $(seq 1 3); do
        herdr pane run "$pane" "/$skill" >&2
        if herdr agent wait "$pane" --until working --timeout 3000 >&2; then
          primed=1
          break
        fi
      done
      if [ "$primed" -eq 0 ]; then
        echo "spawn_and_prime_agent: warning: /$skill priming may not have reached $pane" >&2
      fi
      # Non-fatal: this is just pacing before the next skill's prompt, not
      # the actual success signal (that's the working-transition check
      # above). Under load this wait can time out even though the agent
      # already finished -- don't let that flakiness abort priming the
      # remaining skills.
      herdr agent wait "$pane" --until idle --timeout 15000 >&2 \
        || echo "spawn_and_prime_agent: warning: idle-wait after /$skill timed out, continuing anyway" >&2
    done
  fi
}

# auto_detect_split_target [PANE_ID]
#   Inspects the current layout (via `herdr pane edges`) and decides which
#   pane to split and in which direction to grow a 1-pane -> 2 -> 3 -> 4
#   (2x2) layout one step at a time. Sets the caller's TARGET_PANE and
#   DIRECTION variables on success. On any shape it doesn't recognize
#   (including an already-complete 2x2), prints a diagnostic to stderr and
#   returns 1 without setting either variable -- callers run under `set -e`,
#   so a plain (unwrapped) call aborts the script.
#
#   PANE_ID defaults to the caller's own pane (`herdr pane current`), since
#   this is meant to be run from inside the hub/agent pane doing the
#   delegating.
auto_detect_split_target() {
  local pane="${1:-}"
  if [ -z "$pane" ]; then
    pane=$(herdr pane current | jq -r '.result.pane.pane_id')
  fi

  local layout
  layout=$(herdr pane edges --pane "$pane" | jq -c '.result.edges.layout')

  # The bottom terminal band spans the full width of the area and sits at
  # the largest y -- exclude it. What's left is the "upper area" that
  # herdr-spawn-agent actually grows.
  local upper
  upper=$(echo "$layout" | jq -c '
    (.area.width) as $aw
    | (.panes | map(select(.rect.width == $aw)) | max_by(.rect.y).pane_id) as $bottom
    | .panes | map(select(.pane_id != $bottom))
  ')

  local count
  count=$(echo "$upper" | jq 'length')

  case "$count" in
    1)
      # A single upper pane: match the general split heuristic (wide pane ->
      # right, narrow/tall pane -> down) instead of hardcoding a direction,
      # so this stays consistent with how the 2/3-pane cases already reason
      # about shape.
      TARGET_PANE=$(echo "$upper" | jq -r '.[0].pane_id')
      if echo "$upper" | jq -e '.[0].rect | .width > .height' >/dev/null; then
        DIRECTION="right"
      else
        DIRECTION="down"
      fi
      return 0
      ;;
    2)
      # Vertically stacked: same x, different y. Split the top one (smaller
      # y) to the right, growing an L-shape.
      local xs
      xs=$(echo "$upper" | jq '[.[].rect.x] | unique | length')
      if [ "$xs" -eq 1 ]; then
        TARGET_PANE=$(echo "$upper" | jq -r 'min_by(.rect.y).pane_id')
        DIRECTION="right"
        return 0
      fi
      ;;
    3)
      # L-shape: grouping by x gives one column of 2 (stacked) and one
      # column of 1, and the lone pane's y lines up with the pair column's
      # top. Split the pair column's bottom pane to the right, completing
      # the 2x2. Grouped by x rather than assuming "left column" -- stays
      # correct even if panes were manually rearranged left/right.
      local shape sizes
      shape=$(echo "$upper" | jq -c 'group_by(.rect.x) | map({panes: ., n: length})')
      sizes=$(echo "$shape" | jq -c '[.[].n] | sort')
      if [ "$sizes" = "[1,2]" ]; then
        local single_y pair_min_y
        single_y=$(echo "$shape" | jq -r '.[] | select(.n == 1) | .panes[0].rect.y')
        pair_min_y=$(echo "$shape" | jq -r '.[] | select(.n == 2) | (.panes | min_by(.rect.y).rect.y)')
        if [ "$single_y" = "$pair_min_y" ]; then
          TARGET_PANE=$(echo "$shape" | jq -r '.[] | select(.n == 2) | (.panes | max_by(.rect.y).pane_id)')
          DIRECTION="right"
          return 0
        fi
      fi
      ;;
    4)
      echo "auto_detect_split_target: layout already has a complete 2x2 grid -- pass <target> <right|down> explicitly to grow further" >&2
      return 1
      ;;
  esac

  echo "auto_detect_split_target: unrecognized pane layout ($count pane(s) in the upper area) -- pass <target> <right|down> explicitly (manually rearranged?)" >&2
  return 1
}
