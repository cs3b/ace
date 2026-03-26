---
id: 8qp20k
title: t-18h-done-task-filtering-assignment
type: standard
tags: [assign, workflow, release]
created_at: "2026-03-26 01:20:38"
status: active
---

# t-18h-done-task-filtering-assignment

## What Went Well

- Scoped assignment drive (`8qp1p5@010.01`) stayed deterministic: each sub-step was completed with explicit reports and verified state transitions.
- Implementation stayed narrowly aligned to the task boundary: `assign/prepare`, `assign/create`, and `ace-assign` usage docs were updated without touching unrelated runtime code.
- Verification was fast and reliable (`ace-test ace-assign`, profile run in verify-test), which kept confidence high before release.
- Release detection correctly identified only `ace-assign` from `origin/main...HEAD`, preventing accidental multi-package releases.

## What Could Be Improved

- Pre-commit review fallback (`ace-lint`) surfaced many pre-existing markdown/frontmatter issues, which reduced signal for newly introduced risk.
- The coordinated release workflow asked for one release commit, but `ace-git-commit` split package/root artifacts into two scope-based commits.
- Release-step context switching (manual workflow start before explicit skill handoff) added avoidable execution churn.

## Key Learnings

- For assignment subtrees with clean working trees, release package detection should still rely on `git diff origin/main...HEAD` to capture already-committed step output.
- This task confirmed the ownership boundary: done-task filtering behavior belongs in prepare/create workflow contracts rather than queue runtime execution.
- Review fallback behavior should be tuned for docs-heavy steps; otherwise lint noise can mask truly actionable findings.

## Action Items

- Add guidance to release workflows for handling multi-scope commit generation when strict single-commit output is required.
- Define a lower-noise pre-commit lint strategy for workflow/docs-only changes (or baseline-known lint debt) in assignment review steps.
- Add contract-focused regression coverage for done-task filtering language in `assign/prepare` and `assign/create` workflow files.
