---
id: 8rcy4n
title: selfimprove-e2e-goal-style-guidance
type: standard
tags: [self-improvement, process-fix, e2e]
created_at: "2026-04-13 22:45:10"
status: done
---

# selfimprove-e2e-goal-style-guidance

## What Went Well

- The newer goal-based E2E style proved more stable once scenarios were rewritten around final sandbox state and runner observations.
- The harness changes already supported canonical runner observations, so the missing piece was propagating that contract back into handbook guidance and workflow instructions.

## What Could Be Improved

- The shared E2E workflows still taught an older artifact-heavy style after the harness contract had changed.
- `create`, `review`, and parts of `rewrite` still encouraged command-capture-first or helper-artifact-driven thinking, which made it easy to reintroduce brittle scenarios.
- Review guidance still referenced legacy `test/atoms`, `test/molecules`, and `test/organisms` inventory instead of the current `test/fast` and `test/feat` layout.

## Action Items

- Updated the E2E workflow instructions (`create`, `review`, `rewrite`, `run`, `execute`) to make final sandbox state the primary oracle and runner observations the only non-filesystem secondary evidence source.
- Updated the shared guides and templates (`e2e-testing`, `tc-authoring`, `scenario.yml` reference/template) so new scenarios no longer teach helper artifacts in `results/tc/{NN}/`.
- Treat future helper-artifact-driven scenarios as rewrite targets during E2E review until the remaining older scenarios are normalized.
