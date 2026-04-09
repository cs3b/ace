---
id: 8r8erl
title: selfimprove-e2e-failure-identity-lock
type: standard
tags: [self-improvement, process-fix, e2e]
created_at: "2026-04-09 09:50:39"
status: active
---

# selfimprove-e2e-failure-identity-lock

## What Went Well

- The canonical scenario summary already contained the correct failed TC, so the underlying evidence model was strong enough to recover the truth.
- The previous E2E workflow hardening around implementation-backed `test-issue` classification still helped separate product behavior from scenario contract drift.
- The failure pattern was specific enough to translate into concrete process improvements instead of another vague "be more careful" retro.

## What Could Be Improved

- The fix loop treated a red scenario as a stable target even when the exact failing TC changed after rerun.
- The workflow did not force a scenario-wide review before TC-local edits, which made it too easy to leave shared contract drift inside the same scenario.
- The suite final report still allowed prose to describe failed tests without a deterministic identity lock, which encouraged over-trusting narrative summaries.

## Key Learnings

- In E2E work, the actionable unit is not just `TS-FOO-001`; it is `report-id / scenario / tc / canonical-source`.
- `summary.r.md` must remain the source of truth for failed TC identity; suite prose is supporting narrative only.
- A scenario can stay red while the failing TC changes, so every rerun must invalidate the old fix target.
- Scenario-local fixes require scenario-wide contract review before editing, because runner/verifier drift is usually shared across TCs.

## Workflow Proposals

- Add a failure identity lock to `e2e/analyze-failures` and `e2e/fix`.
- Require a whole-scenario runner/verifier review before the first edit in any red scenario.
- Force the fix loop to rebind to the latest `summary.r.md` after every rerun.
- Make suite reports preserve canonical failed TC IDs deterministically instead of paraphrasing them.

## Action Items

- Update `e2e/analyze-failures` to record `report_id`, `report_dir`, `scenario`, `tc`, and `canonical_evidence_source`.
- Update `e2e/fix` to reject edits when that tuple is missing or stale.
- Update suite report generation prompts and tests so failed TC IDs are copied verbatim from canonical result data.
- Keep future E2E execution summaries anchored to the active failure tuple, not just the package or scenario name.
