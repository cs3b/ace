---
id: 8r6hr7
title: 8r4-t-ilo-2-github-issue-sync-primitives
type: standard
tags: [ace-task, ace-git, ace-review]
created_at: "2026-04-07 11:50:13"
status: active
---

# 8r4-t-ilo-2-github-issue-sync-primitives

## What Went Well
- Completed the `8r4.t.ilo.2` implementation end-to-end inside the scoped assignment subtree without leaving a dirty working tree.
- Landed a clean integration boundary: `ace-git` now owns reusable GitHub issue operations, and `ace-review` consumers moved to the shared executor.
- Added focused molecule tests for new `ace-git` components and validated all impacted packages (`ace-git`, `ace-review`, `ace-task`) with passing suites.
- Kept commits scoped and traceable by concern: implementation, migration, task metadata, and release metadata.

## What Could Be Improved
- Pre-commit review fallback surfaced lint debt (markdown spacing + two Ruby lint findings) after implementation; this should be shifted earlier in the change loop.
- The release proof workflow instruction used an outdated `ace-test-e2e` flag (`--test-id`), requiring manual command correction during execution.
- Coordinated release guidance assumes one commit, but scoped multi-root commit tooling split the release into per-scope commits; this mismatch should be documented.

## Action Items
- Add a quick pre-push lint pass for touched files before entering `pre-commit-review` to reduce known low-severity findings.
- Update release workflow docs/examples to use current E2E syntax: `ace-test-e2e <package> <TEST_ID>`.
- Add explicit guidance in release workflows for expected multi-scope commit behavior when `ace-git-commit` applies scope-aware splitting.
