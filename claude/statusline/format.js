// Display primitives for the status line: ANSI colors, the warn/alert
// threshold rule, and the countdown format for a rate-limit window's
// resets_at. Nothing here knows about the SDK or the stdin JSON -- it only
// turns numbers into strings.

export const RESET = "\x1b[0m";
export const DIM = "\x1b[2m";
export const GREEN = "\x1b[32m";
export const YELLOW = "\x1b[33m";
export const RED = "\x1b[31m";
export const CYAN = "\x1b[36m";

// Warn above this share of a window, and alert above the second threshold.
const WARN_PCT = 60;
const ALERT_PCT = 80;

export function pctColor(pct) {
  if (pct >= ALERT_PCT) return RED;
  if (pct >= WARN_PCT) return YELLOW;
  return GREEN;
}

// How long until the given epoch millisecond, as "3d11h20m", "2h13m" or
// "6m". Larger units are dropped once they are zero, so a five-hour window
// never prints a leading "0d". Under a minute reads as "<1m" rather than
// rounding to zero, which would look like a window that has already rolled
// over; an instant already past clamps to "0m".
export function remainingTime(targetMs, nowMs) {
  const restSec = Math.floor((targetMs - nowMs) / 1000);
  if (restSec <= 0) return "0m";
  if (restSec < 60) return "<1m";
  const days = Math.floor(restSec / 86400);
  const hours = Math.floor((restSec % 86400) / 3600);
  const minutes = Math.floor((restSec % 3600) / 60);
  if (days > 0) return `${days}d${hours}h${minutes}m`;
  if (hours > 0) return `${hours}h${minutes}m`;
  return `${minutes}m`;
}

export function round(n) {
  return typeof n === "number" && Number.isFinite(n) ? Math.round(n) : null;
}
