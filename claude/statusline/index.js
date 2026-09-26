#!/usr/bin/env node
//
// Claude Code status line.
//
// Reads the session JSON on stdin and prints two lines:
//   1. model, reasoning effort, current branch and repository
//   2. context window usage, plan rate limits and this run's cost
//
// What each number on the second line measures:
//
//   ctx N%      How full this conversation's context window is right now.
//               Taken against context_window_size, which is 200k by default and
//               1M on models with extended context, and counted from input
//               tokens only: fresh input, cache writes and cache reads. Output
//               tokens are excluded, matching how Claude Code itself derives
//               used_percentage. This is a level rather than a running total --
//               /compact and /clear push it back down. Nearing 100% means
//               auto-compaction is close.
//
//   5h N% (2h13m) / 7d N% (3d11h20m)
//               How much of the subscription's rolling 5-hour and 7-day usage
//               allowances is already spent. Both windows count every session
//               inside the period, not just this one, so panes running side by
//               side add up here. Each window frees itself at its own resets_at;
//               at 100% that window is exhausted until it rolls over.
//
//               The time in parentheses is how long that rollover is away,
//               derived from resets_at against the current clock. It is relative
//               and never an absolute time of day: what a full window costs is
//               the wait, not the hour it ends.
//
//               A remainder counts down between messages, so the status line
//               needs to re-run while the session sits idle. That is what
//               refreshInterval in the statusLine settings is for. The used
//               percentages cannot be kept fresh the same way -- they only
//               change when the usage call (see usage.js) reports new numbers
//               -- but a remainder is a fixed instant minus the clock, so
//               recomputing it locally is enough.
//
//   credit N% ($N/$M)
//               Only shown in place of 5h/7d -- see usage.js's
//               selectPlanUsage() for exactly when. No resets_at ships
//               alongside it, so unlike 5h/7d there is no remaining-time
//               suffix here.
//
//   run $N      Estimated cost of this run in USD, computed client-side at
//               list price. Unlike ctx/5h/7d/credit, which all come from a
//               server (the stdin JSON's context/rate-limit fields, or the
//               usage call in usage.js), this is taken from the stdin
//               JSON's cost.total_cost_usd, which Claude Code computes and
//               accumulates locally in the running process -- never a
//               server round trip. On a subscription it is a yardstick for
//               how much work has happened, not an amount that gets billed.
//
//               "This run" is the Claude Code process, not the
//               conversation: confirmed by observation, /exit followed by a
//               fresh `claude` + /resume resets this to $0.00 even though
//               the resumed conversation is the very same one as before,
//               with the same session_id -- the new process starts
//               accumulating from zero, it does not re-derive the total
//               from the resumed transcript. /clear, which keeps the same
//               process and only resets the context, is expected not to
//               reset this number by the same logic, though that half is
//               not separately confirmed.
//
// Every percentage is "used", never "remaining", and no segment carries an
// emoji. A marker sitting in front of a group of numbers reads as qualifying
// the first of them alone: an hourglass ahead of "5h 61% / 7d 42%" looked as
// though it belonged to the five-hour window, though it applied to both. The
// words and units already say what each number measures, so the markers were
// paying for themselves with ambiguity.
//
// Fields that are unavailable (rate limits before the first API response,
// effort on models without the parameter, repo outside a git checkout) drop
// their segment instead of printing a placeholder.
//
// Input schema: https://docs.claude.com/en/docs/claude-code/statusline
//
// See usage.js for why the plan/credit numbers come from a live SDK call
// (refs #75) instead of the stdin JSON or a cache file.

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { basename } from "node:path";
import { CYAN, DIM, RESET, pctColor, remainingTime, round } from "./format.js";
import { fetchUsage, selectPlanUsage } from "./usage.js";

function readStdin() {
  try {
    return readFileSync(0, "utf8");
  } catch {
    return "";
  }
}

// The branch is the one field the stdin JSON does not carry, so ask git
// directly. Anchor it to the session directory: the script's own cwd is
// not guaranteed.
function currentBranch(cwd) {
  if (!cwd) return "";
  try {
    return execFileSync("git", ["-C", cwd, "branch", "--show-current"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return "";
  }
}

// What this session is: model, effort, branch and repository.
function renderSessionSummary({ model, effort, branch, repo }) {
  let line1 = "";
  if (model) {
    line1 = effort ? `${CYAN}${model}·${effort}${RESET}` : `${CYAN}${model}${RESET}`;
  }

  // The branch comes first and the separator is padded, so a double click
  // selects the branch name alone without dragging the repository name
  // along with it.
  let location = "";
  if (branch && repo) {
    location = `${branch} ${DIM}/${RESET} ${repo}`;
  } else if (branch) {
    location = branch;
  } else if (repo) {
    location = repo;
  }

  if (location) {
    line1 = line1 ? `${line1}  ${location}` : location;
  }
  return line1;
}

function renderPlanSegment(planUsage) {
  if (!planUsage) return "";

  if (planUsage.kind === "credit") {
    const { pct, used, limit } = planUsage;
    const usedDisplay = used !== null ? Math.round(used) : used;
    const limitDisplay = limit !== null ? Math.round(limit) : limit;
    return `credit ${pctColor(pct)}${pct}%${RESET} ${DIM}($${usedDisplay}/$${limitDisplay})${RESET}`;
  }

  const now = Date.now();
  let plan = "";
  if (planUsage.fiveHour) {
    const { pct, resetsAtMs } = planUsage.fiveHour;
    plan = `5h ${pctColor(pct)}${pct}%${RESET}`;
    if (resetsAtMs !== null) {
      plan += ` ${DIM}(${remainingTime(resetsAtMs, now)})${RESET}`;
    }
  }
  if (planUsage.sevenDay) {
    const { pct, resetsAtMs } = planUsage.sevenDay;
    if (plan) plan += ` ${DIM}·${RESET} `;
    plan += `7d ${pctColor(pct)}${pct}%${RESET}`;
    if (resetsAtMs !== null) {
      plan += ` ${DIM}(${remainingTime(resetsAtMs, now)})${RESET}`;
    }
  }
  return plan;
}

// What this session has spent: context window usage, plan rate limits and cost.
function renderUsage({ ctx, planUsage, cost }) {
  const segments = [];

  if (ctx !== null) {
    segments.push(`ctx ${pctColor(ctx)}${ctx}%${RESET}`);
  }

  const plan = renderPlanSegment(planUsage);
  if (plan) segments.push(plan);

  segments.push(`run $${cost.toFixed(2)}`);

  return segments.join("  ");
}

async function main() {
  const raw = readStdin();
  let input = {};
  try {
    input = JSON.parse(raw);
  } catch {
    input = {};
  }

  const model = input.model?.display_name ?? "";
  const effort = input.effort?.level ?? "";
  let repo = input.workspace?.repo?.name ?? "";
  const cwd = input.workspace?.current_dir ?? "";
  const projectDir = input.workspace?.project_dir ?? "";
  const ctx = round(input.context_window?.used_percentage);
  const cost = typeof input.cost?.total_cost_usd === "number" ? input.cost.total_cost_usd : 0;

  const branch = currentBranch(cwd);
  if (!repo && projectDir) {
    repo = basename(projectDir);
  }

  const usage = await fetchUsage();
  const planUsage = selectPlanUsage(usage);

  const line1 = renderSessionSummary({ model, effort, branch, repo });
  const line2 = renderUsage({ ctx, planUsage, cost });

  if (line1) process.stdout.write(`${line1}\n`);
  if (line2) process.stdout.write(`${line2}\n`);
}

main()
  .catch(() => {
    // Never crash the status line -- Claude Code would render the error
    // text in its place.
  })
  .finally(() => {
    process.exit(0);
  });
