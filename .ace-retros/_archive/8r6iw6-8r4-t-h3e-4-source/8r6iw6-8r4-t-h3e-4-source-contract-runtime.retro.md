---
id: 8r6iw6
title: 8r4-t-h3e-4-source-contract-runtime
type: standard
tags: [ace-assign, source-contract, runtime, migration]
created_at: "2026-04-07 12:35:46"
status: active
---

# 8r4-t-h3e-4-source-contract-runtime

## What Went Well
- Converted runtime parsing and execution to treat `source` as canonical while preserving backward compatibility for legacy `skill`/`workflow` step metadata.
- Kept changes localized to the expected ownership seams (`StepFileParser`, `Step`, `QueueScanner`, `SkillAssignSourceResolver`, `AssignmentExecutor`) without broad architectural churn.
- Added targeted coverage for source normalization and source protocol resolution, then validated with package-level test suite runs.
- Completed assignment subtree flow end-to-end (plan, implementation, verification, release, retro) with deterministic reports and scoped commits.

## What Could Be Improved
- The plan retrieval command (`ace-task plan <ref>`) stalled in this environment. A deterministic fallback path worked, but this should be diagnosed to avoid workflow friction.
- Release documentation lint checks surfaced many existing baseline style issues unrelated to this task; workflow guidance should clarify when to treat those as blocking vs informational.
- Root release update required follower package handling (`ace-overseer`) because dependency constraints lagged; automated follower detection/reporting can be more explicit before edits begin.

## Key Learnings
- Source-contract migrations are safest when introduced as additive precedence (`source` first, legacy fallback) rather than immediate field removal.
- Resolver-level source protocol helpers (`skill://`, `wfi://`) simplify executor logic and reduce duplicated conditional branches.
- Assignment subtree execution benefits from frequent status checks and report-driven closure at each step to keep the queue deterministic.

## Action Items
- Add or improve diagnostics for `ace-task plan` hangs so the command either progresses visibly or fails fast with actionable guidance.
- Add a pre-release helper check that prints dependency followers before version edits to reduce manual reasoning during coordinated release steps.
- Add doc lint hygiene tasks to progressively reduce longstanding workflow markdown style debt in release-related docs.
