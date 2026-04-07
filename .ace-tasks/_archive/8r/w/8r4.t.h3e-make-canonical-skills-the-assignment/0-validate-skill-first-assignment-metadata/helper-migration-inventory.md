# Helper Migration Inventory

## Discovery Boundary

- Public assignment discovery is limited to canonical skills with `user-invocable: true` that expose public `assign.steps`.
- Internal helper skills use `user-invocable: false` and are excluded from public discovery, but they may still be referenced explicitly by runtime assets, recipes, or authored assignments through `skill://...`.
- Explicit `wfi://...` steps are valid only for internal helpers and authored assignment steps; they must never appear as discoverable public step metadata.

## Helper Classification

| Step | Current state | Target state | Classification | Notes |
|---|---|---|---|---|
| `task-load` | `skill: as-task-load-internal` + `workflow: wfi://assign/task-load-internal` | Internal workflow skill | migrated | Canonical internal skill is `user-invocable: false`; helper YAML remains compatibility shim. |
| `mark-task-done` | `skill: as-mark-task-done-internal` + `workflow: wfi://assign/mark-task-done-internal` | Internal workflow skill or explicit internal `wfi://...` | migrated | Post-run verification guidance moved into internal workflow contract. |
| `pre-commit-review` | `skill: null` + nested `steps:` | Transitional exception first, then internal orchestration skill | retain temporarily during migration | Needs instruction and nested-step preservation; now marked with explicit `migration_state`. |
| `verify-test` | `skill: null` + nested `steps:` | Transitional exception first, then internal orchestration skill | retain temporarily during migration | Distinct from public `verify-test-suite`; now marked with explicit `migration_state`. |
| `reflect-and-refactor` | `skill: as-reflect-and-refactor-internal` + `workflow: wfi://assign/reflect-and-refactor-internal` | Internal orchestration skill | migrated | Step-template behavior preserved while ownership moved to internal canonical skill/workflow. |
| `create-retro` | `skill: as-create-retro-internal` + `workflow: wfi://assign/create-retro-internal` | Internal helper skill | migrated | Internal helper remains non-discoverable (`user-invocable: false`). |
| `split-subtree-root` | Explicit orchestration entry | Explicit internal `wfi://...` | merge into explicit workflow contract | Keep workflow-style runtime contract. |

## Transitional Exceptions

- `ace-assign/.ace-defaults/assign/catalog/steps/pre-commit-review.step.yml`
  - blocker: nested review-mode/client-detection logic is still template-driven in YAML
  - target home: internal orchestration skill/workflow with equivalent runtime overlays
  - completion condition: move nested `steps:` behavior into canonical internal workflow contract
- `ace-assign/.ace-defaults/assign/catalog/steps/verify-test.step.yml`
  - blocker: per-package profiling and performance budget checks are still encoded as YAML step templates
  - target home: internal orchestration skill/workflow with preserved budget semantics
  - completion condition: migrate nested test template behavior without changing subtree verification policy

- Any helper that moves into canonical skills must carry its agent-facing `instructions` into the internal skill metadata so execution behavior remains explicit.
