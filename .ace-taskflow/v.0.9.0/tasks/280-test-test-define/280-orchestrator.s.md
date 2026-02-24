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

- **280.01** — B36TS E2E Pilot: Validated runner/verifier split with 8 goal-based tests (concrete reference)
- **280.02** — Research and Vision: WHY we need this, principles, industry patterns
- **280.03** — Tag System and CLI Filtering: `tags` field, `--tags`/`--exclude-tags` CLI options
- **280.04** — Test Grouping Strategy: Standard groups, classify all 36 existing scenarios
- **280.05** — Goal-Based Test Case Format: `mode: goal` TC structure with objective + success criteria
- **280.06** — Independent Verifier Agent Pattern: Separate executor/verifier agents for higher confidence

## Dependency Chain

280.01 (pilot) → 280.02 (vision) → 280.03 (tags infra) → 280.04 (classification uses tags) → 280.05 (goal format) → 280.06 (verifier)

## Success Criteria

- Tag-based filtering works for `ace-test-e2e suite` and `ace-test-e2e run`
- All 36 scenarios classified with tags and cost-tier
- At least 3 test cases converted to goal-mode format
- Verifier pattern documented and optionally executable
