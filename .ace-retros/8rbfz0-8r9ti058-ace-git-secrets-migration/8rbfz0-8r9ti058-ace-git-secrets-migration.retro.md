---
id: 8rbfz0
title: 8r9.t.i05.8 ace-git-secrets migration
type: standard
tags: [assignment, 8r9.t.i05.8, migration, e2e]
created_at: "2026-04-12 10:38:54"
status: active
---

# 8r9.t.i05.8 ace-git-secrets migration

## What Went Well
- Completed the full migration contract for `ace-git-secrets` in one pass: deterministic tests moved to `test/fast`, E2E scenario retained, and docs aligned to `fast` / `feat` / `e2e`.
- Caught and fixed the post-move helper-path break quickly (`../test_helper` -> `../../test_helper`) after the first `ace-test` run surfaced load errors.
- Identified and resolved E2E sandbox setup fragility by switching scenario setup to `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` for `mise.toml`, then verified `ace-test-e2e` passed `8/8`.
- Release packaging remained clean: version/changelog/lockfile updates landed in coordinated release commits with a clean working tree afterward.

## What Could Be Improved
- Run a targeted grep for relative `test_helper` paths immediately after directory migrations to avoid an initial failed test cycle.
- Standardize the `mise.toml` setup line across package scenarios before migration batches to prevent repeated sandbox setup failures.
- Automate a short post-migration checklist (`fast path rewrites`, `scenario setup fallback`, `docs contract text`) to reduce manual repetition between sibling tasks.

## Action Items
- Add a migration helper check to future batch plans: scan moved test files for stale `require_relative "../test_helper"` and rewrite before first test run.
- Propose a shared scenario setup pattern update for remaining batch packages to use `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` where repo-root files are copied.
- Reuse this task's report references (`010.08.04`, `010.08.06`, `010.08.07`) as dependency context for subsequent batch siblings.
