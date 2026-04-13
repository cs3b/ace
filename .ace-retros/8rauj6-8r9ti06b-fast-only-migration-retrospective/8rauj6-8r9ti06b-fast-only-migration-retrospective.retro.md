---
id: 8rauj6
title: 8r9.t.i06.b fast-only migration retrospective
type: standard
tags: [migration, testing, ace-support-items, assignment]
created_at: "2026-04-11 20:21:19"
status: active
---

# 8r9.t.i06.b fast-only migration retrospective

## What Went Well

- The migration stayed package-scoped and preserved ATOM test organization while moving deterministic coverage into `test/fast/`.
- Verification remained deterministic across all required commands:
  - `ace-test ace-support-items`
  - `ace-test ace-support-items all`
  - `cd ace-support-items && ace-test all --profile 6`
- Release prep completed cleanly with coordinated package + root changelog and lockfile updates for `ace-support-items v0.15.8`.

## What Could Be Improved

- `ace-task plan 8r9.t.i06.b` path-mode invocation stalled in this environment; fallback worked, but plan retrieval reliability should be improved.
- Pre-commit review fallback had to lint an unrelated pre-existing modified file because no task-local uncommitted diff remained; scope detection for fallback lint could be tighter.

## Action Items

- Add follow-up to investigate `ace-task plan <ref>` path-mode stalls and improve timeout diagnostics.
- Consider refining pre-commit review fallback to prioritize task/package-scoped paths when available.
