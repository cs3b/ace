---
id: 8rczcj
title: selfimprove-e2e-public-surface-gate
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-04-13 23:33:57"
status: active
---

# selfimprove-e2e-public-surface-gate

## What Went Well

- The earlier handbook work had already established the runner/verifier split, impact-first verification, and the ban on helper artifacts in `results/tc/{NN}/`.
- Runner observations were already available in harness reports, which gave a natural place to capture friction instead of pushing more sandbox-side artifacts into scenarios.
- The review/fix loop exposed a consistent pattern across multiple packages, which made the real process gap obvious instead of looking like isolated scenario mistakes.

## What Could Be Improved

- The handbook did not explicitly require goal-style E2E tests to prove that a user can do the job from the tool's public surface (`README`, usage docs, `--help`, CLI) without hidden recipes or workaround instructions.
- Because that rule was missing, scenario authors could over-instruct runners with exact command recipes and fallback detours, and those TCs still looked "valid" as long as they produced evidence.
- The review and planning workflows judged evidence quality, but they did not grade public-surface fit or friction, so workaround-driven scenarios were not being flagged early enough.
- Workarounds were treated as useful execution notes rather than as failure signals against the public-surface contract.

## Action Items

- Add a Public-Surface Gate to `create`, `review`, `plan-changes`, and `rewrite` so goal-style TCs must be achievable from docs/help/public CLI without hidden recipes or workarounds.
- Update guides/templates so runner files stay outcome-oriented and do not teach fallback procedures or supporting-tool probes as the way to reach the goal.
- Update `run`, `execute`, `analyze-failures`, and `fix` so workaround pressure in runner observations is treated as a product/docs/help or scenario-design gap, not as a stable testing pattern.
- Use review output to grade both `Public Surface Fit` and `Friction`, so future rewrite plans can remove or narrow workaround-driven TCs before they spread.
