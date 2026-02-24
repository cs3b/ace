---
id: v.0.9.0+task.280
status: in-progress
priority: medium
estimate: TBD
worktree:
  branch: 280-define-e2e-test-levels-grouping-and-goal-based-execution
  path: "../ace-task.280"
  created_at: '2026-02-24 02:21:57'
  updated_at: '2026-02-24 02:21:57'
  target_branch: main
---

# Define E2E Test Levels, Grouping, and Goal-Based Execution

## Overview

Evolve the E2E test runner from flat scenario execution to a structured, filterable, goal-aware testing system. Currently all 36 scenarios are treated equally — no grouping, no tag-based filtering, and test cases are purely procedural (step-by-step commands). This task introduces four capabilities:

1. **Tag system and CLI filtering** — Attach metadata tags to scenarios and TCs, filter at discovery time
2. **Grouping strategy** — Classify scenarios into standard groups (smoke, happy-path, use-case, deep)
3. **Goal-based test cases** — TC format where agents plan their own approach against success criteria
4. **Independent verifier** — Separate agent validates test outcomes without seeing executor context

## Subtasks

- **280.01** — Reference Migration: Migrate live `ace-b36ts/test/e2e/` to goal-mode TC structure (`TS-B36TS-001-pilot`)
- **280.02** — Research and Vision: WHY we need this, principles, group hierarchy, runner config per tier
- **280.03** — Tag System and CLI Filtering: `tags` field, `--tags`/`--exclude-tags` CLI options, goal-mode discovery
- **280.04** — Test Grouping Strategy: Standard groups, classify all ~33 existing scenarios
- **280.05** — Goal-Based Test Case Format: Two formats — inline `mode: goal` TCs and standalone `TC-*.runner.md`/`TC-*.verify.md`
- **280.06** — Independent Verifier Agent Pattern: Sandbox-aware verifier with filesystem access for higher confidence
- **280.07** — Handbook/Workflow/Template Migration: Update all `ace-test-runner-e2e` guides, workflows, and templates to the new canonical format

## Dependency Chain

280.01 (live b36ts migration) → 280.02 (vision) → 280.03 (tags infra) → 280.04 (classification uses tags) → 280.05 (goal format) → 280.06 (verifier) → 280.07 (handbook/workflow/template alignment)

## Success Criteria

- Live `ace-b36ts/test/e2e/` migrated to `TS-B36TS-001-pilot` goal-mode TC structure
- Tag-based filtering works for `ace-test-e2e-suite` and `ace-test-e2e run`
- All ~33 scenarios classified with scenario-level tags
- Two goal-mode formats supported: inline TC (`mode: goal`) and standalone (`TC-*.runner.md` + `TC-*.verify.md`)
- Verifier pattern implemented with sandbox-aware architecture (filesystem access to artifacts)
- Report format uses TC-first schema (`tcs-passed`/`tcs-failed`/`tcs-total`, `failed[].tc`, `score`, `verdict`)
- `ace-test-runner-e2e` handbook/workflow/template files fully aligned with the new format (single owner: 280.07)
