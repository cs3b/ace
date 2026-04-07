# Public Step Ownership Map

## Canonical Ownership Rules

- Public step discovery metadata lives in canonical skill frontmatter under `assign.steps`.
- Workflow binding for public skills lives only in `skill.execution.workflow`.
- Runtime subtree expansion stays in workflow frontmatter `assign:`.
- `ace-assign` keeps recipes and composition rules only; it does not keep long-term public step metadata.

## Final Ownership Table

| Responsibility | Final owner | Why |
|---|---|---|
| Public step discovery/composition metadata | Canonical skills (`assign.steps`) | Keeps public inventory near skill intent metadata and avoids duplicated YAML catalogs. |
| Workflow rendering and subtree expansion | Workflow frontmatter (`assign:`) | Runtime expansion belongs to executable workflow definitions. |
| Ordering, pairing, and recipe policy | `ace-assign` policy files (`composition-rules.yml`, recipes) | Composition policy remains orchestrator-specific. |
| Transitional legacy compatibility | `ace-assign` runtime parser/resolver | Supports migration while normalizing to `source:`. |

## Public Step Coverage

| Public step | Canonical skill owner | Workflow binding owner | Notes |
|---|---|---|---|
| `onboard` | `as-onboard` | `skill.execution.workflow` | Public context-loading step. |
| `plan-task` | `as-task-plan` | `skill.execution.workflow` | Public planning step. |
| `work-on-task` | `as-task-work` | `skill.execution.workflow` | Primary workflow-bound tracer. |
| `review-pr` | `as-review-pr` | `skill.execution.workflow` | Public review step. |
| `create-pr` | `as-github-pr-create` | `skill.execution.workflow` | Public publishing step. |
| `verify-test-suite` | `as-test-verify-suite` | `skill.execution.workflow` | Public verification step. |

## Metadata Moving Into Skills

- `description`
- `intent.phrases`
- `prerequisites`
- `produces`
- `consumes`
- `context`
- `instructions` (for helper-style internal skills)
- `when_to_skip`
- `effort`
- `tags`

## Data That Stays Out Of Skills

- recipe ordering and composition policy
- compatibility-only YAML retained during migration
- runtime subtree expansion metadata owned by workflows
