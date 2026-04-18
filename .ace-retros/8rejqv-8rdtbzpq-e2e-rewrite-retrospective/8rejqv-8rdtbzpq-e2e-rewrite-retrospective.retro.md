---
id: 8rejqv
title: 8rd.t.bzp.q e2e rewrite retrospective
type: standard
tags: [assignment, e2e, ace-test-runner-e2e]
created_at: "2026-04-15 13:09:52"
status: active
---

# 8rd.t.bzp.q e2e rewrite retrospective

## What Went Well
- Replaced hidden fixture plumbing in `TS-RUNNER-001` with scenario-local `copy-fixtures`, which made discovery coverage explicit and reproducible.
- Added `TS-RUNNER-002` with full non-dry execution coverage and validated it with a passing end-to-end run (`3/3` cases).
- Updated `docs/usage.md` with deterministic `.ace-local/test-e2e/` shell-helper patterns and validated both rewritten scenarios plus package tests successfully.
- Completed assignment-driven flow with scoped commits, package verification (`ace-test all --profile 6`), and coordinated minor release bump to `ace-test-runner-e2e v0.38.0`.

## What Could Be Improved
- `ace-task plan <ref>` path-mode call stalled in this environment and required manual fallback to the cached/task-informed plan.
- Real-run fixture scenarios can drift due model-generated TC fidelity mismatch; initial fixture assumptions caused avoidable rerun/fix iterations.
- Release workflow instructions include post-publish proof checks that are not always feasible during local subtree release-prep steps.

## Action Items
- Add a deterministic fallback note to planning workflows when `ace-task plan` stalls repeatedly in fork contexts.
- Strengthen fixture authoring guidance for small nested E2E scenarios to reduce TC-fidelity mismatch risk (especially for glite/provider-driven executions).
- Consider documenting explicit “local release-prep vs post-publish verification” boundaries in release workflow notes.
