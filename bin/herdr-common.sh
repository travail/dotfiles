# Shared helpers for herdr-init / herdr-spawn-*. Source only, not
# executable. Callers must have `set -euo pipefail` in effect.

HERDR_COMMON_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# ensure_dir_trusted DIR
#   Marks DIR as trusted in ~/.claude.json, so `claude` never raises its
#   one-time workspace trust prompt for it. Returns non-zero (with a
#   diagnostic) when that can't be arranged, so callers can refuse to spawn
#   instead of leaving an unattended pane parked on the prompt.
#
#   This used to be handled after the fact, by reading the pane and sending
#   Enter once the prompt's text showed up. That broke two ways over on
#   Claude Code v2.1.251: `pane read --source recent` returns nothing at all
#   while claude's TUI holds the alternate screen (only `visible` and
#   `detection` see it), so the text never matched -- and had it matched, the
#   prompt's initial cursor now sits on "No, exit", so the Enter would have
#   quit claude rather than trusting the directory. Matching on rendered text
#   is fragile by construction, since upstream can restyle the prompt or
#   reorder its options in any release, so the state that actually gates the
#   prompt is set up front instead.
#
#   hasTrustDialogAccepted is the same key the old code already *read* to
#   decide whether the prompt could appear at all, so writing it adds no new
#   dependency on claude's internal state format -- it only drops the far
#   more brittle dependency on what the prompt looks like.
ensure_dir_trusted() {
  local dir="$1" config="$HOME/.claude.json" trusted tmp

  trusted=$(jq -r --arg d "$dir" '.projects[$d].hasTrustDialogAccepted // false' \
            "$config" 2>/dev/null || echo false)
  if [ "$trusted" = "true" ]; then
    return 0
  fi

  if [ ! -f "$config" ]; then
    echo "ensure_dir_trusted: $config does not exist" >&2
    return 1
  fi

  # Written through a sibling temp file and a rename, so a concurrently
  # running claude never reads a half-written config. mktemp creates the
  # file 0600, which is what claude itself keeps this file at.
  tmp=$(mktemp "${config}.herdr.XXXXXX") || return 1
  if ! jq --arg d "$dir" \
       '.projects[$d] = ((.projects[$d] // {}) + {hasTrustDialogAccepted: true})' \
       "$config" >"$tmp" || ! mv -f "$tmp" "$config"; then
    rm -f "$tmp"
    echo "ensure_dir_trusted: failed to mark $dir as trusted in $config" >&2
    return 1
  fi

  # Read back rather than trusting the write: ~/.claude.json is shared by
  # every running claude, and one of them rewriting the whole file can land
  # between our read and our rename, dropping the key again.
  trusted=$(jq -r --arg d "$dir" '.projects[$d].hasTrustDialogAccepted // false' \
            "$config" 2>/dev/null || echo false)
  if [ "$trusted" = "true" ]; then
    return 0
  fi

  echo "ensure_dir_trusted: $dir still untrusted after writing $config" >&2
  return 1
}

# spawn_and_prime_agent PANE_ID
#   Spawns `claude` in PANE_ID and waits for the agent to go idle, having
#   first made sure the pane's directory is trusted so no trust prompt can
#   intercept the session.
spawn_and_prime_agent() {
  local pane="$1" dir

  # cwd is looked up per-pane (not passed in by the caller) so this works
  # whether it's called against herdr-init's root pane or a pane
  # herdr-spawn-* just split off elsewhere. Trust has to be settled
  # *before* claude starts -- it reads the flag once at startup, so a pane
  # already sitting on the prompt can't be rescued by writing it afterwards.
  dir=$(herdr pane get "$pane" | jq -r '.result.pane.cwd')
  if ! ensure_dir_trusted "$dir"; then
    echo "spawn_and_prime_agent: refusing to spawn in $pane -- run \`claude\` in $dir once, accept the trust prompt, then retry" >&2
    return 1
  fi

  herdr pane run "$pane" "claude" >&2

  # herdr needs a moment to detect the freshly spawned agent -- `herdr agent
  # wait` errors immediately (no retry) if the target isn't registered yet,
  # so a little polling is unavoidable before we can wait on it.
  for _ in $(seq 1 150); do
    herdr agent get "$pane" >/dev/null 2>&1 && break
    sleep 0.1
  done
  herdr agent wait "$pane" --until idle --timeout 15000 >&2
}

# spawn_agent SCRIPT_NAME [ARGS...]
#   Shared CLI implementation for herdr-spawn-hub-agent and
#   herdr-spawn-cowork-agent. Splits an existing pane and spawns a claude
#   agent in the new pane.
spawn_agent() {
  local opt_name="$1"
  shift 1

  local OPTIND=1
  local RATIO="" LABEL="" FOCUS_FLAG="--no-focus" AUTO=0
  local opt

  while getopts "r:l:nfah" opt; do
    case "$opt" in
      r)
        RATIO="$OPTARG"
        ;;
      l)
        LABEL="$OPTARG"
        ;;
      n)
        # Deprecated: no-op for backward compatibility. Skills are no longer primed at startup.
        ;;
      f)
        FOCUS_FLAG="--focus"
        ;;
      a)
        AUTO=1
        ;;
      h)
        cat <<EOF
Usage: $opt_name [-h] [-r RATIO] [-l LABEL] [-n] [-f] [-a] [<target> <right|down>]

Arguments:
  target      Pane id or label to split (e.g. dotfiles-p1). (required
              unless -a)
  right|down  Which side of target the new pane appears on. (required
              unless -a)

Options:
  -a        Auto-detect target/direction from the current layout instead of
             taking them as arguments (grows a 1/2/3-pane upper area toward
             a 2x2; errors out if the layout is already a complete 2x2 or
             isn't a recognized shape). Mutually exclusive with
             <target> <right|down>.
  -r RATIO  Size ratio, passed through to \`herdr pane split --ratio\`
            (sizes the pane being split, i.e. target -- the new pane gets
            the remainder).
  -l LABEL  Explicit label for the new pane. (default: auto-derived by
            mirroring the pane_id suffix herdr itself assigns to the new
            pane, e.g. "<workspace-label>-p3" or "<workspace-label>-pA" --
            never guessed/computed, so it always matches the real id)
  -n        Deprecated: no-op for backward compatibility.
  -f        Focus the new pane after creating it. (default: unfocused)
  -h        Show this help and exit.
EOF
        return 0
        ;;
      *)
        echo "Usage: $opt_name [-h] [-r RATIO] [-l LABEL] [-n] [-f] [-a] [<target> <right|down>]" >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  local target_ref="" direction="" target_pane=""
  if [ "$AUTO" -eq 1 ]; then
    if [ $# -ne 0 ]; then
      echo "$opt_name: -a is mutually exclusive with <target> <right|down>" >&2
      echo "Usage: $opt_name [-h] [-r RATIO] [-l LABEL] [-n] [-f] [-a] [<target> <right|down>]" >&2
      return 1
    fi
    auto_detect_split_target
    target_pane="$TARGET_PANE"
    direction="$DIRECTION"
  else
    if [ $# -ne 2 ]; then
      echo "Usage: $opt_name [-h] [-r RATIO] [-l LABEL] [-n] [-f] [-a] [<target> <right|down>]" >&2
      return 1
    fi

    target_ref="$1"
    direction="$2"

    case "$direction" in
      right | down) ;;
      *)
        echo "$opt_name: direction must be 'right' or 'down'" >&2
        return 1
        ;;
    esac

    # pane_ids contain a colon (e.g. w1:p1), labels don't -- same convention
    # herdr-id itself uses.
    case "$target_ref" in
      *:*)
        target_pane="$target_ref"
        ;;
      *)
        target_pane=$("$HERDR_COMMON_DIR/herdr-id" -p "$target_ref")
        ;;
    esac
  fi

  local workspace_id
  workspace_id=$(herdr pane get "$target_pane" | jq -r '.result.pane.workspace_id')

  echo "$opt_name: splitting $target_pane ($direction)..." >&2
  local split_args=(herdr pane split "$target_pane" --direction "$direction" "$FOCUS_FLAG")
  if [ -n "$RATIO" ]; then
    split_args+=(--ratio "$RATIO")
  fi
  local new_pane
  new_pane=$("${split_args[@]}" | jq -r '.result.pane.pane_id')

  if [ -z "$LABEL" ]; then
    # Derive the prefix from the workspace's own label (not the target pane's
    # label) so this stays correct even if panes were manually renamed.
    local prefix
    prefix=$(herdr workspace get "$workspace_id" | jq -r '.result.workspace.label')
    LABEL="${prefix}-${new_pane#*:}"
  fi
  herdr pane rename "$new_pane" "$LABEL" >&2

  echo "$opt_name: spawning claude in $new_pane ($LABEL)..." >&2
  spawn_and_prime_agent "$new_pane"

  echo "$new_pane"
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
  # herdr-spawn-* actually grows.
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
