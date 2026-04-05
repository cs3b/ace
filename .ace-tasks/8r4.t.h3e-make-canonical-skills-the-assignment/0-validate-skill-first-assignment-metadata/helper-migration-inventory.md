# Helper Migration Inventory

## Discovery Boundary

- Public assignment discovery is limited to canonical skills with `user-invocable: true` that expose public `assign.steps`.
- Internal helper skills use `user-invocable: false` and are excluded from public discovery, but they may still be referenced explicitly by runtime assets, recipes, or authored assignments through `skill://...`.
- Explicit `wfi://...` steps are valid only for internal helpers and authored assignment steps; they must never appear as discoverable public step metadata.

## Helper Classification

| Step | Current state | Target state | Notes |
|---|---|---|---|
| `task-load` | `skill: null` YAML | Internal workflow skill | Keep task-specific loading instructions; `user-invocable: false`. |
| `mark-task-done` | `skill: null` + `workflow: wfi://task/update` | Internal workflow skill or explicit internal `wfi://...` | Preserve post-run verification guidance. |
| `pre-commit-review` | `skill: null` + nested `steps:` | Transitional exception first, then internal orchestration skill | Needs instruction and nested-step preservation. |
| `verify-test` | `skill: null` + nested `steps:` | Transitional exception first, then internal orchestration skill | Distinct from public `verify-test-suite`. |
| `reflect-and-refactor` | `skill: null` + nested `steps:` | Internal orchestration skill | Preserve multi-step review/refactor flow. |
| `create-retro` | `skill: null` YAML | Internal helper skill | Likely direct helper with no public discovery. |
| `split-subtree-root` | Explicit orchestration entry | Explicit internal `wfi://...` | Keep workflow-style runtime contract. |

## Transitional Exceptions

- Any helper retaining YAML past this spike must be listed in the implementation PR/task notes with:
  - the exact YAML file kept
  - the migration blocker
  - the intended target home
  - the follow-up task or direct completion condition
