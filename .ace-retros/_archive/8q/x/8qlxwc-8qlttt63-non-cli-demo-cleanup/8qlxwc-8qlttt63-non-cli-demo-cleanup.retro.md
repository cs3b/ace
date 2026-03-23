---
id: 8qlxwc
title: 8ql.t.tt6.3-non-cli-demo-cleanup
type: standard
tags: []
created_at: "2026-03-22 22:35:57"
status: active
task_ref: 8ql.t.tt6.3
---

# 8ql.t.tt6.3-non-cli-demo-cleanup

## What Went Well
- Scoped cleanup stayed aligned to behavioral spec: removed non-CLI `ace-test` demo artifacts and eliminated the built-in `ace-test` tape from `ace-demo` defaults.
- Validation was explicit and fast: `ace-demo list` confirmed inventory cleanup immediately, and focused `ace-demo` tests passed after fixture updates.
- Path-scoped commits prevented cross-contamination from large unrelated repo changes that were already present in the working tree.

## What Could Be Improved
- `ace-assign status` updates lagged right after `ace-assign finish`, which caused repeated status checks and minor workflow friction.
- The `ace-task plan` command produced no usable output in this environment; fallback to prior plan/report was effective but slower.
- Native `/review` is unavailable in this terminal runtime, so pre-commit-review had to skip gracefully instead of producing structured findings.

## Key Learnings
- Removing a demo from user-facing inventory can require updates in three places: artifact files, docs copy, and tests with hardcoded example names.
- For verification steps, distinguish package code changes from docs-only edits; docs-only packages can be safely skipped for profile runs when the step allows it.
- Release steps in a dirty monorepo should always use explicit path scoping to avoid accidental multi-package release noise.

## Action Items
- Add a reliability note or automation check around post-`ace-assign finish` status propagation to reduce duplicate polling.
- Investigate `ace-task plan` no-output behavior in this runtime and add a deterministic fallback path in workflow docs.
- Consider adding a native-review capability check helper so pre-commit-review can skip without a failed command attempt.
