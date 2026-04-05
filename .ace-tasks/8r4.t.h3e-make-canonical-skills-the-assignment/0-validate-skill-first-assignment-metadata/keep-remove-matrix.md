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

## Runtime Contract

| Asset class | Current owner | Future owner | Notes |
|---|---|---|---|
| Step execution target | `skill:` / `workflow:` split | `source:` | Legacy fields normalize to `source:` during migration only. |
| Runtime subtree expansion | Workflow frontmatter `assign:` | Workflow frontmatter `assign:` | No change in ownership. |
