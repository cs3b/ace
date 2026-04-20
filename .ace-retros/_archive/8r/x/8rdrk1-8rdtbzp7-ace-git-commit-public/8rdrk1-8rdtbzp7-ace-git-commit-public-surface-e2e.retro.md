---
id: 8rdrk1
title: 8rd.t.bzp.7 ace-git-commit public-surface e2e rewrite
type: standard
tags: [assignment, ace-git-commit, e2e]
created_at: "2026-04-14 18:22:17"
status: active
---

# 8rd.t.bzp.7 ace-git-commit public-surface e2e rewrite

## What Went Well
- Rewrote split/no-split E2E goals to require explicit public setup and
  impact-first evidence, reducing hidden fixture coupling.
- Added end-to-end `--only-staged` contract coverage (`TC-007`) and wired it
  through scenario, runner, and verifier manifests.
- Updated package docs/help and validated package tests (`ace-test all --profile
  6`) with a clean pass.
- Completed coordinated package release (`ace-git-commit v0.25.0`) with package
  and root changelog updates in a single release commit.

## What Could Be Improved
- Task referenced migration artifacts under `.ace-local/e2e-migration/...` that
  were not present in the workspace, which increased planning ambiguity.
- Pre-commit review fallback produced many non-blocking lint warnings; trimming
  warning noise would make review signals sharper.

## Action Items
- Add a small pre-flight check in assignment task-load/plan flows to flag
  missing task-declared context files early and suggest fallback sources.
- Consider a focused lint rule profile for E2E goal docs to reduce repetitive
  non-actionable warnings during assignment pre-commit review.
