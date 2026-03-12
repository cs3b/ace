# Typed Skill Migration Inventory

Generated: 2026-03-09 03:00:02 UTC

## Summary

- Total projected skills inventoried: 88
- Migrated to canonical package-owned skills: 27
- Pending migration candidates: 37
- Workflow-only exceptions tracked: 24

## Inventory Matrix

| Skill | Source | Kind | Workflow | Canonical Path | Disposition | Notes |
|---|---|---|---|---|---|---|
| `as-assign-compose` | `ace-assign` | `workflow` | `wfi://assign/compose` | `ace-assign/handbook/skills/as-assign-compose/SKILL.md` | `migrated` | canonical file present |
| `as-assign-create` | `ace-assign` | `workflow` | `wfi://assign/create` | `ace-assign/handbook/skills/as-assign-create/SKILL.md` | `migrated` | canonical file present |
| `as-assign-drive` | `ace-assign` | `workflow` | `wfi://assign/drive` | `ace-assign/handbook/skills/as-assign-drive/SKILL.md` | `migrated` | canonical file present |
| `as-assign-prepare` | `ace-assign` | `workflow` | `wfi://assign/prepare` | `ace-assign/handbook/skills/as-assign-prepare/SKILL.md` | `migrated` | canonical file present |
| `as-assign-run-in-batches` | `ace-assign` | `workflow` | `wfi://assign/run-in-batches` | `ace-assign/handbook/skills/as-assign-run-in-batches/SKILL.md` | `migrated` | canonical file present |
| `as-assign-start` | `ace-assign` | `orchestration` | `wfi://assign/start` | `ace-assign/handbook/skills/as-assign-start/SKILL.md` | `migrated` | canonical file present |
| `as-b36ts` | `ace-b36ts` | `capability` | `wfi://b36ts` | `ace-b36ts/handbook/skills/as-b36ts/SKILL.md` | `migrated` | canonical file present |
| `as-bug-analyze` | `ace-task` | `workflow` | `wfi://bug/analyze` | `ace-task/handbook/skills/as-bug-analyze/SKILL.md` | `migrated` | canonical file present |
| `as-bug-fix` | `ace-task` | `workflow` | `wfi://bug/fix` | `ace-task/handbook/skills/as-bug-fix/SKILL.md` | `migrated` | canonical file present |
| `as-bundle` | `ace-bundle` | `workflow` | `(none)` | `(none)` | `workflow-only` | no explicit workflow binding in projected skill |
| `as-demo-create` | `ace-demo` | `workflow` | `wfi://demo/create` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-demo-record` | `ace-demo` | `workflow` | `wfi://demo/record` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-docs-create-adr` | `generated` | `workflow` | `wfi://docs/create-adr` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-docs-create-api` | `generated` | `workflow` | `wfi://docs/create-api` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-docs-create-user` | `generated` | `workflow` | `wfi://docs/create-user` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-docs-maintain-adrs` | `generated` | `workflow` | `wfi://docs/maintain-adrs` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-docs-squash-changelog` | `(unset)` | `workflow` | `wfi://docs/squash-changelog` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-docs-update-roadmap` | `ace-task` | `workflow` | `wfi://docs/update-roadmap` | `ace-task/handbook/skills/as-docs-update-roadmap/SKILL.md` | `migrated` | canonical file present |
| `as-docs-update-tools` | `custom` | `workflow` | `wfi://docs/update-tools` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-docs-update-usage` | `ace-task` | `workflow` | `wfi://docs/update-usage` | `ace-task/handbook/skills/as-docs-update-usage/SKILL.md` | `migrated` | canonical file present |
| `as-docs-update` | `ace-docs` | `workflow` | `wfi://docs/update` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-create` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/create` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-fix` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/analyze-failures` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-manage` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/manage` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-plan-changes` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/plan-changes` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-review` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/review` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-rewrite` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/rewrite` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-e2e-setup-sandbox` | `ace-test-runner-e2e` | `workflow` | `wfi://e2e/setup-sandbox` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-git-commit` | `ace-git-commit` | `workflow` | `wfi://git/commit` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-git-rebase` | `ace-git` | `workflow` | `wfi://git/rebase` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-git-reorganize-commits` | `ace-git` | `workflow` | `wfi://git/reorganize-commits` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-git-security-audit` | `ace-git-secrets` | `workflow` | `wfi://git/security-audit` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-git-worktree` | `ace-git-worktree` | `workflow` | `wfi://git/worktree` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-github-pr-create` | `ace-git` | `workflow` | `wfi://github/pr/create` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-github-pr-update` | `ace-git` | `workflow` | `wfi://github/pr/update` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-handbook-init-project` | `generated` | `workflow` | `wfi://handbook/init-project` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-handbook-manage-agents` | `custom` | `workflow` | `wfi://handbook/manage-agents` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-handbook-manage-guides` | `custom` | `workflow` | `wfi://handbook/manage-guides` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-handbook-manage-workflows` | `custom` | `workflow` | `wfi://handbook/manage-workflows` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-handbook-parallel-research` | `ace-handbook` | `workflow` | `wfi://handbook/parallel-research` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-handbook-perform-delivery` | `ace-handbook` | `workflow` | `wfi://handbook/perform-delivery` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-handbook-review-guides` | `custom` | `workflow` | `wfi://handbook/review-guides` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-handbook-review-workflows` | `custom` | `workflow` | `wfi://handbook/review-workflows` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-handbook-selfimprove` | `ace-retro` | `workflow` | `wfi://retro/selfimprove` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-handbook-synthesize-research` | `ace-handbook` | `workflow` | `wfi://handbook/synthesize-research` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-handbook-update-docs` | `custom` | `workflow` | `wfi://handbook/update-docs` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-idea-capture-features` | `ace-task` | `workflow` | `wfi://idea/capture-features` | `ace-task/handbook/skills/as-idea-capture-features/SKILL.md` | `migrated` | canonical file present |
| `as-idea-capture` | `ace-task` | `workflow` | `wfi://idea/capture` | `ace-task/handbook/skills/as-idea-capture/SKILL.md` | `migrated` | canonical file present |
| `as-idea-prioritize` | `ace-task` | `workflow` | `wfi://idea/prioritize` | `ace-task/handbook/skills/as-idea-prioritize/SKILL.md` | `migrated` | canonical file present |
| `as-integration-update-claude` | `custom` | `workflow` | `wfi://integration/update-claude` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-lint-fix-issue-from` | `generated` | `workflow` | `wfi://lint/run` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-lint-process-report` | `ace-lint` | `workflow` | `wfi://lint/process-report` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-lint-run` | `ace-lint` | `workflow` | `wfi://lint/run` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-onboard` | `ace-meta` | `workflow` | `(none)` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-overseer` | `ace-overseer` | `workflow` | `(none)` | `(none)` | `workflow-only` | no explicit workflow binding in projected skill |
| `as-prompt-prep` | `(unset)` | `workflow` | `(none)` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-release-bump-version` | `ace-handbook` | `workflow` | `wfi://release/bump-version` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-release-navigator` | `ace-task` | `workflow` | `(none)` | `(none)` | `workflow-only` | no explicit workflow binding in projected skill |
| `as-release-update-changelog` | `ace-handbook` | `workflow` | `wfi://release/update-changelog` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-release` | `ace-handbook` | `workflow` | `wfi://release/publish` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-retro-create` | `ace-task` | `workflow` | `wfi://retro/create` | `ace-task/handbook/skills/as-retro-create/SKILL.md` | `migrated` | canonical file present |
| `as-retro-synthesize` | `ace-task` | `workflow` | `wfi://retro/synthesize` | `ace-task/handbook/skills/as-retro-synthesize/SKILL.md` | `migrated` | canonical file present |
| `as-review-apply-feedback` | `ace-review` | `workflow` | `wfi://review/apply-feedback` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-review-package` | `custom` | `workflow` | `(none)` | `(none)` | `workflow-only` | projection-owned or source package not canonicalized in this slice |
| `as-review-pr` | `ace-review` | `workflow` | `wfi://review/pr` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-review-run` | `ace-review` | `workflow` | `wfi://review/run` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-review-verify-feedback` | `ace-review` | `workflow` | `wfi://review/verify-feedback` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-search-feature-research` | `ace-search` | `workflow` | `wfi://search/feature-research` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-search-research` | `ace-search` | `workflow` | `wfi://search/research` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-search-run` | `ace-search` | `workflow` | `wfi://search/run` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-sim-run` | `ace-sim` | `workflow` | `wfi://sim/run` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-task-document-unplanned` | `ace-task` | `workflow` | `wfi://task/document-unplanned` | `ace-task/handbook/skills/as-task-document-unplanned/SKILL.md` | `migrated` | canonical file present |
| `as-task-draft` | `ace-task` | `workflow` | `wfi://task/draft` | `ace-task/handbook/skills/as-task-draft/SKILL.md` | `migrated` | canonical file present |
| `as-task-finder` | `ace-task` | `workflow` | `(none)` | `(none)` | `workflow-only` | no explicit workflow binding in projected skill |
| `as-task-improve-coverage` | `ace-task` | `workflow` | `wfi://task/improve-coverage` | `ace-task/handbook/skills/as-task-improve-coverage/SKILL.md` | `migrated` | canonical file present |
| `as-task-manage-status` | `ace-task` | `workflow` | `wfi://task/manage-status` | `ace-task/handbook/skills/as-task-manage-status/SKILL.md` | `migrated` | canonical file present |
| `as-task-plan` | `ace-task` | `workflow` | `wfi://task/plan` | `ace-task/handbook/skills/as-task-plan/SKILL.md` | `migrated` | canonical file present |
| `as-task-reorganize` | `ace-task` | `workflow` | `wfi://task/reorganize` | `ace-task/handbook/skills/as-task-reorganize/SKILL.md` | `migrated` | canonical file present |
| `as-task-review-questions` | `ace-task` | `workflow` | `wfi://task/review-questions` | `ace-task/handbook/skills/as-task-review-questions/SKILL.md` | `migrated` | canonical file present |
| `as-task-review` | `ace-task` | `workflow` | `wfi://task/review` | `ace-task/handbook/skills/as-task-review/SKILL.md` | `migrated` | canonical file present |
| `as-task-work` | `ace-task` | `workflow` | `wfi://task/work` | `ace-task/handbook/skills/as-task-work/SKILL.md` | `migrated` | canonical file present |
| `as-test-create-cases` | `ace-task` | `workflow` | `wfi://test/create-cases` | `ace-task/handbook/skills/as-test-create-cases/SKILL.md` | `migrated` | canonical file present |
| `as-test-fix` | `ace-task` | `workflow` | `wfi://test/analyze-failures` | `ace-task/handbook/skills/as-test-fix/SKILL.md` | `migrated` | canonical file present |
| `as-test-optimize` | `ace-test` | `workflow` | `wfi://test/optimize` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-test-performance-audit` | `ace-test` | `workflow` | `(none)` | `(none)` | `workflow-only` | no explicit workflow binding in projected skill |
| `as-test-plan` | `ace-test` | `workflow` | `wfi://test/plan` | `(none)` | `pending-migration` | stable source package with workflow binding |
| `as-test-review` | `ace-test` | `workflow` | `(none)` | `(none)` | `workflow-only` | no explicit workflow binding in projected skill |
| `as-test-verify-suite` | `ace-test` | `workflow` | `wfi://test/verify-suite` | `(none)` | `pending-migration` | stable source package with workflow binding |
