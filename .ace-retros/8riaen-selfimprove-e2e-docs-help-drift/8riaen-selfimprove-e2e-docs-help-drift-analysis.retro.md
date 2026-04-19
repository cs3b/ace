---
id: 8riaen
title: selfimprove-e2e-docs-help-drift-analysis
type: standard
tags: [self-improvement, process-fix]
created_at: "2026-04-19 06:56:17"
status: active
---

# selfimprove-e2e-docs-help-drift-analysis

## What Went Well

- E2E workflow guidance already had a public-surface gate, so the process fix could stay narrow.
- The missing checkpoint was made explicit in `wfi://e2e/analyze-failures` instead of relying on agents to infer docs/help drift from general public-surface guidance.
- A fast handbook contract test now protects the required docs/help drift section in the analysis and fix workflows.

## What Could Be Improved

- Failure analysis previously classified code/test/runner issues without forcing a per-TC docs/help assessment.
- Agents could fix code or tests while missing stale docs, usage guides, or `--help` output that caused the E2E failure path.
- The fix workflow considered analysis complete without checking whether docs/help drift had been reported.

## Action Items

- Require `## Docs / Help Drift From E2E Failures` in every E2E failure analysis.
- Treat analysis as incomplete in `wfi://e2e/fix` when the docs/help drift section is absent.
- Keep docs/help fixes as first-class E2E fix targets when a valid user job is not discoverable from public docs or command help.
