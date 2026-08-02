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

  herdr pane run "$pane" "claude" >&2

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
