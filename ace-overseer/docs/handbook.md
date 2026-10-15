---
doc-type: user
title: ace-overseer Handbook Reference
purpose: Catalog of package-owned agent skills and workflows in ace-overseer.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Handbook Reference

## Skills

### `as-overseer`

- Path: `handbook/skills/as-overseer/SKILL.md`
- Purpose: orchestrate task worktrees through `work-on`, `status`, and `prune`
- Execution model: workflow-backed skill invoking `wfi://overseer`

### `as-overseer-configure-project`

- Path: `handbook/skills/as-overseer-configure-project/SKILL.md`
- Purpose: adapt delivery supervision to project-owned presets, workflows, and decision policy without destructive overwrite
- Execution model: workflow-backed skill invoking `wfi://overseer/configure-project`

## Workflows

### `wfi://overseer`

- Path: `handbook/workflow-instructions/overseer.wf.md`
- Purpose: canonical workflow for working on tasks, checking active worktrees, and safe cleanup
- Core sequence: 1) run `ace-overseer work-on --task ...`; 2) inspect state with `ace-overseer status`; 3) preview cleanup with `ace-overseer prune --dry-run`, then confirm with `--yes`.

### `wfi://overseer/configure-project`

- Path: `handbook/workflow-instructions/overseer/configure-project.wf.md`
- Purpose: resolve and review effective delivery presets, workflows, and decision guides, then apply repeatable project-local adaptation while preserving customization
- Output: per-asset `CREATED`, `UPDATED`, `KEPT`, or `BLOCKED` evidence plus a repeat-run zero-write check

## Related Documentation

- [Getting Started](getting-started.md)
- [Usage Guide](usage.md)
