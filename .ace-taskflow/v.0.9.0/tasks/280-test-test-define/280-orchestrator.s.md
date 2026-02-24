---
id: v.0.9.0+task.280
status: draft
priority: medium
estimate: TBD
---

# Define E2E Test Levels, Grouping, and Goal-Based Execution

## Overview

Evolve the E2E test runner from flat scenario execution to a structured, filterable, goal-aware testing system. Currently all 36 scenarios are treated equally — no grouping, no tag-based filtering, and test cases are purely procedural (step-by-step commands). This task introduces four capabilities:

1. **Tag system and CLI filtering** — Attach metadata tags to scenarios and TCs, filter at discovery time
2. **Grouping strategy** — Classify scenarios into standard groups (smoke, happy-path, use-case, deep)
3. **Goal-based test cases** — TC format where agents plan their own approach against success criteria
4. **Independent verifier** — Separate agent validates test outcomes without seeing executor context

## Subtasks

- **280.01** — B36TS E2E Pilot: Validated runner/verifier split with 8 goal-based tests (DONE — 6/8 goals passed)
- **280.02** — Research and Vision: WHY we need this, principles, group hierarchy, runner config per tier
- **280.03** — Tag System and CLI Filtering: `tags` field, `--tags`/`--exclude-tags` CLI options, goal-mode discovery
- **280.04** — Test Grouping Strategy: Standard groups, classify all ~33 existing scenarios
- **280.05** — Goal-Based Test Case Format: Two formats — inline `mode: goal` TCs and standalone `goal-*.runner.md`/`verify.md`
- **280.06** — Independent Verifier Agent Pattern: Sandbox-aware verifier with filesystem access for higher confidence

## Dependency Chain

280.01 (pilot) → 280.02 (vision) → 280.03 (tags infra) → 280.04 (classification uses tags) → 280.05 (goal format) → 280.06 (verifier)

## Success Criteria

- Tag-based filtering works for `ace-test-e2e suite` and `ace-test-e2e run`
- All ~33 scenarios classified with tags and cost-tier
- Two goal formats supported: inline TC (`mode: goal`) and standalone (`goal-*.runner.md` + `goal-*.verify.md`)
- Verifier pattern documented with sandbox-aware architecture (filesystem access to artifacts)
- Report format: YAML frontmatter with `passed`/`failed` arrays, `score`, `verdict` (pilot-validated)
