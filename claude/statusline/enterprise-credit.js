#!/usr/bin/env node
//
// Usage formatter for ccstatusline's custom-command widget. refs #103,
// refs #118
//
// Fetches the live usage utilization via Claude Agent SDK (reusing
// usage.js) and prints the formatted plan/credit segment for whichever
// shape the account's response reports: 5h/7d rate-limit windows, a
// monthly usage-credit allowance, or nothing if neither is present. See
// usage.js's selectPlanUsage() for why this isn't simply "Pro/Max gets
// 5h/7d, Enterprise gets credit". On fetch failure, prints nothing and
// exits 0.
//
// The file and widget id (settings.json's "enterprise-credit") predate
// this: it used to be Enterprise-only, with Pro/Max handled by
// ccstatusline's own built-in session-usage/weekly-usage widgets. Those
// widgets call /api/oauth/usage directly, which 429s for an Enterprise
// seat (issue #118) -- this command's SDK-based fetch does not have that
// problem for either account type, so it now covers both and the built-in
// widgets were removed from settings.json instead of being kept for
// Pro/Max only.

import { fetchUsage, selectPlanUsage } from "./usage.js";
import { formatPlanUsage } from "./plan-usage-line.js";

async function main() {
  const usage = await fetchUsage();
  const planUsage = selectPlanUsage(usage);
  const output = formatPlanUsage(planUsage);

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
