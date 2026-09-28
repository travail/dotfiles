// Formats selectPlanUsage()'s result into the display string shared by
// every entry point that renders the plan/credit segment: the ccstatusline
// custom-command widget (enterprise-credit.js) and the legacy status line
// (index.js). Pure formatting only -- importing this module never calls
// the SDK or does anything else with side effects; callers fetch usage
// themselves and pass the result in.
//
// The percentage is colored by pctColor() and reset with the plain RESET.
// ccstatusline's custom-command widget renders this without
// "preserveColors" (see settings.json), so ccstatusline strips these ANSI
// codes itself and paints the segment in its own theme foreground instead
// -- the color codes here only take visible effect in the legacy status
// line (index.js), which prints plain text with no background segment.

import { DIM, RESET, pctColor, remainingTime } from "./format.js";

// planUsage: selectPlanUsage()'s return value (or null). Returns "" when
// there is nothing to show.
export function formatPlanUsage(planUsage) {
  if (!planUsage) return "";

  if (planUsage.kind === "credit") {
    const { pct, used, limit } = planUsage;
    const usedDisplay = used !== null ? Math.round(used) : used;
    const limitDisplay = limit !== null ? Math.round(limit) : limit;
    return `credit: ${pctColor(pct)}${pct}%${RESET} ${DIM}($${usedDisplay}/$${limitDisplay})${RESET}`;
  }

  const now = Date.now();
  let plan = "";
  if (planUsage.fiveHour) {
    const { pct, resetsAtMs } = planUsage.fiveHour;
    plan = `5h: ${pctColor(pct)}${pct}%${RESET}`;
    if (resetsAtMs !== null) {
      plan += ` ${DIM}(${remainingTime(resetsAtMs, now)})${RESET}`;
    }
  }
  if (planUsage.sevenDay) {
    const { pct, resetsAtMs } = planUsage.sevenDay;
    if (plan) plan += ` ${DIM}·${RESET} `;
    plan += `7d: ${pctColor(pct)}${pct}%${RESET}`;
    if (resetsAtMs !== null) {
      plan += ` ${DIM}(${remainingTime(resetsAtMs, now)})${RESET}`;
    }
  }
  return plan;
}
