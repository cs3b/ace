# Tracer Scenarios

## 1. Workflow-Bound Public Skill

- Step target: `source: skill://as-task-work`
- Discovery source: public canonical skill with `user-invocable: true` and `assign.steps`
- Workflow binding source: `skill.execution.workflow`
- Runtime expansion source: workflow frontmatter `assign.sub-steps`
- Expected behavior: compose discovers the step from canonical skill metadata; runtime renders the bound workflow and expands sub-steps from workflow frontmatter

## 2. Direct Capability Skill

- Step target: `source: skill://external-review`
- Discovery source: fallback name/description matching only
- Workflow binding source: none required
- Runtime rendering source: skill body directly
- Expected behavior: capability skill may omit `skill.execution.workflow`; runtime executes the skill body and no workflow-level `assign:` is required
- Validation note: if no current canonical capability skill cleanly fits this path, use this as a contract-only tracer and keep it synthetic until a concrete capability skill is introduced

## 3. Internal Explicit Workflow

- Step target: `source: wfi://assign/split-subtree-root`
- Discovery source: none; explicit authored/internal step only
- Workflow binding source: the `wfi://...` URI itself
- Runtime expansion source: workflow frontmatter if present
- Expected behavior: runtime may execute this step, but public discovery and canonical public `assign.steps` must not surface `wfi://...` as public inventory

## Migration Contract for Legacy Fields

- Legacy step payloads using `skill:` and/or `workflow:` remain parser-compatible only during migration.
- Runtime normalization target is `source:`.
- `skill: as-task-work` -> `source: skill://as-task-work`.
- `workflow: wfi://task/update` -> `source: wfi://task/update`.
