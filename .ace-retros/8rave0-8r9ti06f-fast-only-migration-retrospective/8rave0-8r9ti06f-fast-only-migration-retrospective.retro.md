---
id: 8rave0
title: 8r9.t.i06.f fast-only migration retrospective
type: standard
tags: [testing, migration, ace-test]
created_at: "2026-04-11 20:55:34"
status: active
---

# 8r9.t.i06.f fast-only migration retrospective

## What Went Well
- Moved `ace-test` deterministic coverage into `test/fast/` with a minimal file-layout change and preserved all existing test assertions.
- Caught and fixed the nested-path regression quickly (`gem_root` resolution after file move), then re-verified both required commands:
  - `ace-test ace-test`
  - `ace-test ace-test all`
- Completed the package release surface in one pass (`ace-test` version bump + package/root changelog + lockfile refresh) with path-scoped commits.

## What Could Be Improved
- `ace-task plan <ref>` path-mode output was unusually sparse for this subtree and did not provide a full actionable checklist, requiring manual reconstruction from task spec + existing patterns.
- `pre-commit-review` fallback lint surfaced an em-dash warning in `ace-test/README.md`; this was non-blocking but remains as style debt.
- Release-step bump-level intent (`minor` vs `patch` for migration-only slices) is still interpretation-heavy and should be made more explicit per task to avoid ambiguity.

## Action Items
- Improve planner output validation so empty/truncated plan artifacts are detected and auto-regenerated before `work-on-task` begins.
- Add a migration helper/checklist for test-file moves that enforces root-path assertions when tests relocate under `test/fast/`.
- Tighten task specs for release steps by declaring the intended bump level directly when known.
