# Keep/Remove Matrix

## Policy Assets Retained In `ace-assign`

| Asset | Current path pattern | Decision | Notes |
|---|---|---|---|
| Recipes | `ace-assign/.ace-defaults/assign/catalog/recipes/*.yml` | KEEP | Orchestrator policy stays in `ace-assign`. |
| Composition rules | `ace-assign/.ace-defaults/assign/catalog/composition-rules.yml` | KEEP | Ordering and selection policy remain local to `ace-assign`. |

## Public Step Metadata

| Asset class | Current owner | Future owner | Migration state |
|---|---|---|---|
| Public skill-backed steps | `ace-assign/.ace-defaults/assign/catalog/steps/*.step.yml` | Canonical `assign.steps` on public skills | REMOVE after compatibility window |
| Public workflow binding | `assign.source` on canonical skills | `skill.execution.workflow` | REMOVE duplicated binding |

## Helper/Internal Steps

| Asset class | Current owner | Future owner | Migration state |
|---|---|---|---|
| Internal helper with canonical skill/workflow home | `skill: null` helper YAML | Internal canonical skill and/or explicit internal `wfi://...` | REMOVE YAML after migration |
| Internal helper needing temporary bridge | `skill: null` helper YAML | Transitional YAML plus documented exception | KEEP TEMPORARILY with explicit reason |
| Explicit orchestration-only workflow step | `workflow:` or explicit authored step | `source: wfi://...` | KEEP as explicit internal/runtime contract |

### Current Migration Snapshot (8r4.t.h3e.1)

- Migrated to internal canonical helpers (`user-invocable: false`):
  - `task-load` -> `as-task-load-internal` + `wfi://assign/task-load-internal`
  - `mark-task-done` -> `as-mark-task-done-internal` + `wfi://assign/mark-task-done-internal`
  - `reflect-and-refactor` -> `as-reflect-and-refactor-internal` + `wfi://assign/reflect-and-refactor-internal`
  - `create-retro` -> `as-create-retro-internal` + `wfi://assign/create-retro-internal`
- Transitional exceptions retained in YAML with explicit migration metadata:
  - `pre-commit-review`
  - `verify-test`

## Runtime Contract

| Asset class | Current owner | Future owner | Notes |
|---|---|---|---|
| Step execution target | `skill:` / `workflow:` split | `source:` | Legacy fields normalize to `source:` during migration only. |
| Runtime subtree expansion | Workflow frontmatter `assign:` | Workflow frontmatter `assign:` | No change in ownership. |

## Step Target Contract

| Contract case | Canonical target | Discovery eligibility | Notes |
|---|---|---|---|
| Public skill-backed step | `source: skill://<skill-name>` | Yes (public canonical skills only) | `assign.steps` is the discoverable source. |
| Internal helper capability | `source: skill://<internal-skill-name>` | No | Internal skills are `user-invocable: false`. |
| Explicit internal/authored workflow step | `source: wfi://<namespace/action>` | No | Runtime-valid, but not public inventory. |
| Legacy compatibility | `skill:` + `workflow:` | N/A | Transitional parsing only; normalize to `source:` before runtime resolution. |

## Superseded Direction

- The earlier cleanup draft tracked as `8r0.t.ye8` is superseded by this contract.
- Reason: it did not preserve the public-vs-internal discovery boundary and lacked a unified `source:` migration contract.
