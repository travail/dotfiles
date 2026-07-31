# Shared helpers for herdr-init / herdr-spawn-agent. Source only, not
# executable. Callers must have `set -euo pipefail` in effect.

# spawn_and_prime_agent PANE_ID [PRIME=1]
#   Spawns `claude` in PANE_ID, clears the one-time trust-dialog prompt if it
#   appears, and waits for the agent to go idle. Unless PRIME=0, also sends
#   `/herdr` to preload the herdr CLI skill and waits idle again.
spawn_and_prime_agent() {
  local pane="$1" prime="${2:-1}"

  herdr pane run "$pane" "claude" >&2

  # herdr needs a moment to detect the freshly spawned agent, and the first
  # run in a not-yet-trusted directory shows a one-time trust prompt (herdr
  # reports agent_status idle even while that prompt is up). `herdr agent get`
  # can succeed *before* the prompt has even been rendered, so a single
  # successful check isn't proof the prompt won't show up. Only pay for the
  # extra confirmation delay when the directory isn't already trusted (per
  # ~/.claude.json).
  #
  # cwd is looked up per-pane (not passed in by the caller) so this works
  # whether it's called against herdr-init's root pane or a pane
  # herdr-spawn-agent just split off elsewhere.
  local dir trusted required_clean clean_checks
  dir=$(herdr pane get "$pane" | jq -r '.result.pane.cwd')
  trusted=$(jq -r --arg d "$dir" '.projects[$d].hasTrustDialogAccepted // false' \
            "$HOME/.claude.json" 2>/dev/null || echo false)
  if [ "$trusted" = "true" ]; then
    required_clean=1
  else
    required_clean=4
  fi

  clean_checks=0
  for _ in $(seq 1 30); do
    if herdr pane read "$pane" --source recent --lines 20 2>/dev/null | grep -q "trust this folder"; then
      herdr pane send-keys "$pane" Enter
      clean_checks=0
      sleep 0.5
      continue
    fi
    clean_checks=$((clean_checks + 1))
    if [ "$clean_checks" -ge "$required_clean" ] && herdr agent get "$pane" >/dev/null 2>&1; then
      break
    fi
    sleep 0.5
  done
  herdr agent wait "$pane" --until idle --timeout 15000 >&2

  if [ "$prime" -eq 1 ]; then
    # Prime the agent with the herdr skill up front, so it can act as hub
    # (dispatch to/pull from sibling panes) without the user having to
    # explain herdr in the task prompt.
    herdr pane run "$pane" "/herdr" >&2
    herdr agent wait "$pane" --until idle --timeout 15000 >&2
  fi
}
