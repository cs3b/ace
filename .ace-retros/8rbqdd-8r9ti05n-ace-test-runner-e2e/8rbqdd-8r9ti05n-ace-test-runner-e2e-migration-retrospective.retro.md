---
id: 8rbqdd
title: 8r9.t.i05.n ace-test-runner-e2e migration retrospective
type: standard
tags: [8r9.t.i05.n, testing, migration, fast, feat, e2e]
created_at: "2026-04-12 17:34:52"
status: active
---

# 8r9.t.i05.n ace-test-runner-e2e migration retrospective

## What Went Well
- Completed the package migration to the restarted `fast`/`feat`/`e2e` model end-to-end in one subtree pass, including deterministic test relocation, docs updates, scenario metadata refresh, and release.
- Verification coverage was comprehensive: `ace-test` default/feat/all and `ace-test-e2e` were all run and passed after targeted fixes.
- Release flow stayed scoped: package version bump (`0.33.1` -> `0.34.0`), package changelog entry, root changelog entry, and lockfile refresh were completed with dedicated release commits.
- Path-depth regressions from moving tests into `test/fast` were detected quickly by package tests and fixed with focused updates.

## What Could Be Improved
- `ace-task plan <taskref>` stalled repeatedly in this environment; fallback to manual plan authoring was required. This should be addressed in planner runtime behavior.
- A scenario verifier string check (`TC-003`) was brittle to harmless copy changes (`scenarios to execute` vs `execution phases`), causing a preventable E2E failure/retry cycle.
- Multiple moved tests depended on `__dir__`-relative path assumptions; these could be centralized in helper methods to reduce migration churn.

## Action Items
- Add or update planner reliability guidance/tooling for `ace-task plan` stall recovery so assignments can auto-fallback to path mode earlier.
- Replace fragile exact-phrase checks in E2E verifier docs with stable semantic markers where possible.
- Introduce a shared test helper for repository/package root resolution in `ace-test-runner-e2e` tests to avoid per-file relative-path breakage on directory migrations.
