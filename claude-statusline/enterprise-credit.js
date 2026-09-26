#!/usr/bin/env node
//
// Enterprise usage-credit formatter for ccstatusline custom-command widget.
// refs #103
//
// Fetches the live usage utilization via Claude Agent SDK (reusing usage.js)
// and prints the formatted credit segment if the current account is an Enterprise
// subscription with monthly usage-credit allowance.
// For standard plans (5h/7d) or on fetch failure, prints nothing and exits 0.

import { DIM, RESET, pctColor } from "./format.js";
import { fetchUsage, selectPlanUsage } from "./usage.js";

export function formatCredit(planUsage) {
  if (!planUsage || planUsage.kind !== "credit") {
    return "";
  }

  const { pct, used, limit } = planUsage;
  const usedDisplay = used !== null ? Math.round(used) : used;
  const limitDisplay = limit !== null ? Math.round(limit) : limit;
  return `credit ${pctColor(pct)}${pct}%${RESET} ${DIM}($${usedDisplay}/$${limitDisplay})${RESET}`;
}

async function main() {
  const usage = await fetchUsage();
  const planUsage = selectPlanUsage(usage);
  const output = formatCredit(planUsage);

  if (output) {
    process.stdout.write(output);
  }
}

main()
  .catch(() => {
    // Never crash the status line
  })
  .finally(() => {
    process.exit(0);
  });
