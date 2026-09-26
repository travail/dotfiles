// Everything that talks to the Claude Agent SDK, and the one piece of
// domain knowledge that sits on top of it: which of the plan's rate-limit
// windows to show.
//
// refs #75 -- this used to shell out to `jq` and read ~/.claude.json's
// cachedUsageUtilization cache for the Enterprise usage-credit fallback,
// but that cache only refreshes when some other action (e.g. running
// /usage) happens to fetch usage, so it silently goes stale otherwise.
// Calling the Claude Agent SDK's
// usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET() takes the
// same path as /usage itself, so the numbers here are always current.
// That name is Anthropic's own warning that the API is unstable and may
// change or disappear without notice -- and it pulls in the SDK's
// dependency tree and adds roughly a second of startup latency to every
// render.

import { query } from "@anthropic-ai/claude-agent-sdk";
import { round } from "./format.js";

// How long the SDK usage call is allowed to take before we give up and
// render without the plan/credit segment.
const USAGE_TIMEOUT_MS = 3000;

// Ask the SDK for the same data /usage renders. Returns null on any failure
// (timeout, rejection, missing fields) so the caller can drop the segment
// instead of erroring the whole status line.
export async function fetchUsage() {
  // We only want the control channel, never an actual turn -- this
  // generator yields nothing and ends immediately. A generator that instead
  // awaits forever (to "keep the stream open") was measured to make the
  // whole call unpredictably slow, sometimes tens of seconds; ending the
  // input right away keeps it at the sub-2s latency the SDK call is
  // expected to have.
  async function* noInput() {}

  const q = query({ prompt: noInput(), options: {} });
  try {
    return await Promise.race([
      q.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET({
        skipBehaviors: true,
      }),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("usage call timed out")), USAGE_TIMEOUT_MS),
      ),
    ]);
  } catch {
    return null;
  } finally {
    try {
      await q.interrupt();
    } catch {
      // best-effort cleanup only
    }
    try {
      await q.return();
    } catch {
      // best-effort cleanup only
    }
  }
}

// Pick which of the plan's rate-limit windows to show, from the raw
// usage_EXPERIMENTAL...() response (or null, if the call failed).
//
// A Claude.ai Pro/Max seat reports rate_limits.five_hour / .seven_day. An
// Enterprise seat billed through a Claude apps gateway (e.g. AWS
// Marketplace) gets those back as null -- it runs on a monthly usage-credit
// allowance instead, reported in the same response under
// rate_limits.extra_usage. Both shapes come back in the same call; this is
// a display choice between them, not two separate fetches, so it is only
// ever one or the other, never both.
//
// Returns { kind: "plan", fiveHour, sevenDay } or { kind: "credit", pct,
// used, limit } or null when neither is available. fiveHour/sevenDay are
// each null or { pct, resetsAtMs }.
export function selectPlanUsage(usage) {
  const rateLimits = usage?.rate_limits ?? null;
  if (!rateLimits) return null;

  const fiveHour = toWindow(rateLimits.five_hour);
  const sevenDay = toWindow(rateLimits.seven_day);
  if (fiveHour || sevenDay) {
    return { kind: "plan", fiveHour, sevenDay };
  }

  const extra = rateLimits.extra_usage;
  if (extra && extra.is_enabled === true) {
    const pct = round(extra.utilization);
    if (pct === null) return null;
    return {
      kind: "credit",
      pct,
      used: typeof extra.used_credits === "number" ? extra.used_credits / 100 : null,
      limit: typeof extra.monthly_limit === "number" ? extra.monthly_limit / 100 : null,
    };
  }

  return null;
}

function toWindow(window) {
  const pct = round(window?.utilization ?? null);
  if (pct === null) return null;
  const resetsAtMs = window?.resets_at ? Date.parse(window.resets_at) : null;
  return { pct, resetsAtMs: Number.isNaN(resetsAtMs) ? null : resetsAtMs };
}
