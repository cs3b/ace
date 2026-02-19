---
id: v.0.9.0+task.272
status: in-progress
priority: medium
estimate: 22h
dependencies:
- v.0.9.0+task.271
worktree:
  branch: 272-rename-ace-taskflow-to-ace-specflow
  path: "../ace-task.272"
  created_at: '2026-02-19 09:02:12'
  updated_at: '2026-02-19 09:02:12'
  target_branch: main
---

# Rename ace-taskflow to ace-specflow

## Overview

Full rename of the ace-taskflow gem and all associated concepts from "taskflow/task" to "specflow/spec". This is a massive cross-cutting rename affecting ~220 files across the monorepo. The rename reflects that the system manages behavioral specifications, not generic tasks.

## Dependencies

- **Task 271** (remove .00 orchestrator suffix) must land first — avoids double-touching orchestrator files during the rename.

## Subtasks

| # | Task | Scope | Est | Status |
|---|------|-------|-----|--------|
| **01** | Rename gem core | Module, classes, executable, CLI subcommands | 4h | draft |
| **02** | Rename data directory and configuration | .ace-taskflow/ → .ace-specflow/, config files | 3h | draft |
| **03** | Rename cross-gem Ruby dependencies | Gemspecs, requires, class refs, subprocess calls | 4h | draft |
| **04** | Rename nav protocols and Claude skills | Protocol files, skill definitions, workflow instructions | 4h | draft |
| **05** | Rename docs, CI, and miscellaneous | Gemfile, CI, docs, README, ADRs, fixtures | 3h | draft |
| **06** | Final verification sweep | Exhaustive grep for stale references, test suite validation | 2h | draft |

## Dependency Graph

```
272.01 (Gem core) ──► 272.03 (Cross-gem deps)
272.02 (Data dir)  ──► 272.03 (Cross-gem deps)
272.01 + 272.02 ──► 272.04 (Nav/Skills)
272.01 + 272.02 ──► 272.05 (Docs/CI)
272.03 + 272.04 + 272.05 ──► 272.06 (Verification sweep)
```

Subtasks 01 and 02 can run in parallel. Subtask 03 depends on both. Subtasks 04 and 05 depend on 01+02 but can run in parallel with each other. Subtask 06 runs last after all others complete.

## Design Decisions

- **Canonical IDs**: Keep `+task.NNN` format for now. Changing to `+spec.NNN` touches too many files and cross-references — defer to a follow-on task.
- **CLI aliases**: Retain `task`/`tasks` as deprecated aliases for one release cycle alongside new `spec`/`specs` subcommands. Print deprecation warning on use.
- **Data subdirectories**: `tasks/` → `specs/` inside release directories. `retros/`, `ideas/`, `docs/` subdirectories unchanged.
- **Spec file extension**: `.s.md` unchanged (already means "spec markdown").

## Success Criteria

- [ ] `ace-specflow` gem builds, installs, and passes all tests
- [ ] `ace-specflow spec 121` works (new name)
- [ ] `ace-specflow task 121` works with deprecation warning (alias)
- [ ] `.ace-specflow/` data directory used by default
- [ ] All cross-gem references updated (ace-git-worktree, ace-review, ace-prompt-prep)
- [ ] Nav protocols resolve correctly (`ace-nav spec://121`)
- [ ] All Claude skills reference ace-specflow
- [ ] CI pipeline passes with renamed gem
- [ ] Documentation updated throughout

## Implementation Notes

### Sequencing Strategy

This rename is best done as a series of focused commits rather than one massive commit. Each subtask produces a self-contained set of changes that can be reviewed independently, though they should land as a single PR.

### Risk Mitigation

- Run full test suite (`ace-test-suite`) after each subtask
- Keep deprecated aliases for one release to give external scripts time to update
- Migration script for `.ace-taskflow/` → `.ace-specflow/` rename should be idempotent