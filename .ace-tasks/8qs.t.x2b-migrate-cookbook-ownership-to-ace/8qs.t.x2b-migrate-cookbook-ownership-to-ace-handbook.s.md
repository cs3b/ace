---
id: 8qs.t.x2b
status: pending
priority: medium
created_at: "2026-03-29 22:02:35"
estimate: TBD
dependencies: []
tags: [docs, cookbook, ace-handbook, ace-docs, orchestrator]
bundle:
  presets: [project]
  files: [.ace-tasks/8qs.t.x2b-migrate-cookbook-ownership-to-ace/0-create-handbook-cookbook-standards-and/8qs.t.x2b.0-create-handbook-cookbook-standards-and-workflows.s.md, .ace-tasks/8qs.t.x2b-migrate-cookbook-ownership-to-ace/1-migrate-cookbook-ownership-references-out/8qs.t.x2b.1-migrate-cookbook-ownership-references-out-of-ace.s.md, .ace-tasks/8qs.t.x2b-migrate-cookbook-ownership-to-ace/2-seed-handbook-with-canonical-cookbook/8qs.t.x2b.2-seed-handbook-with-canonical-cookbook-examples.s.md]
  commands: []
needs_review: false
---

# Migrate cookbook ownership to ace-handbook

## Objective

Move cookbook ownership from `ace-docs` to `ace-handbook` so ACE has one canonical home for cookbook standards, authoring workflows, review criteria, discovery, and example content.

## Behavioral Specification

### User Experience

- **Input:** A maintainer wants to author or discover cookbooks as a first-class handbook asset, and a project maintainer wants cookbook learnings to land in project docs and concise agent guidance.
- **Process:** The work is split into three vertical slices: handbook-owned cookbook interfaces and standards, removal of active cookbook ownership from `ace-docs`, and seeding `ace-handbook` with two canonical example cookbooks derived from real project work.
- **Output:** `ace-handbook` becomes the single source of truth for cookbook behavior, `ace-docs` no longer presents cookbook creation as its workflow, and the package ships concrete examples that demonstrate the intended style and propagation model.

### Expected Behavior

1. The parent task is an orchestrator only and does not define implementation details beyond the contract between the three child tasks.
2. Child `8qs.t.x2b.0` defines the handbook-owned cookbook interfaces: standards, template changes, workflows, skills, and `cookbook://` discovery.
3. Child `8qs.t.x2b.1` removes active cookbook ownership references from `ace-docs` while preserving changelog history.
4. Child `8qs.t.x2b.2` seeds `ace-handbook` with the Astro and multi-ruby-gem monorepo cookbook examples and defines how their distilled guidance lands in docs and agent instructions.
5. The overall task is complete only when cookbook ownership is singular, discoverable, and demonstrated with canonical examples.

### Interface Contract

```bash
ace-bundle wfi://handbook/manage-cookbooks
ace-bundle wfi://handbook/review-cookbooks
ace-nav list 'cookbook://*'
ace-nav resolve cookbook://setup-starting-an-astro-project-with-ace
```

### Error Handling

- If any active `ace-docs` docs still imply cookbook ownership after the migration, the task is incomplete.
- If cookbook discovery works but handbook docs do not explain the asset class, the task is incomplete.
- If the example cookbooks read like generic best-practices essays instead of real-work-derived how-to documents, the task is incomplete.

### Edge Cases

- Historical `CHANGELOG.md` entries that mention `create-cookbook` stay intact as release history.
- Agent guidance files must get distilled rules or references, not a full copy of cookbook content.
- Project-local cookbook storage remains `docs/cookbooks/[category]-[descriptive-name].cookbook.md`; the package examples live under handbook-owned cookbook content.

## Success Criteria

1. The task tree has exactly three direct child tasks.
2. `ace-handbook` owns cookbook standards, workflows, skills, examples, and protocol discovery.
3. `ace-docs` no longer has an active `create-cookbook` workflow or active ownership docs.
4. Two canonical handbook cookbooks exist and are discoverable through `cookbook://`.
5. The child specs together define how cookbook knowledge is distilled into package docs and concise agent instruction surfaces.

## Validation Questions

- No blocking questions remain.
- The migration intentionally uses one orchestrator plus three child tasks rather than splitting docs, workflows, and examples into separate parallel parents.

## Vertical Slice Decomposition (Task/Subtask Model)

**Orchestrator with three child tasks**

- **Child `8qs.t.x2b.0`:** define handbook cookbook standards, workflows, skills, template, and discovery
- **Child `8qs.t.x2b.1`:** remove active cookbook ownership from `ace-docs` and preserve only historical mentions
- **Child `8qs.t.x2b.2`:** add two canonical example cookbooks and define their distilled propagation targets
- **Advisory size:** Medium
- **Context dependencies:** `ace-handbook` template and docs, `ace-docs` cookbook workflow, nav protocol sources, current root `CLAUDE.md` and `AGENTS.md`

## Verification Plan

### Unit/Component Validation

- `ace-task show 8qs.t.x2b --tree` reports exactly three direct children.
- `ace-task show 8qs.t.x2b.2` shows dependencies on `8qs.t.x2b.0` and `8qs.t.x2b.1`.

### Integration/E2E Validation

- The three child specs together define a complete migration from `ace-docs` ownership to `ace-handbook` ownership.
- A maintainer implementing from this task tree does not need to infer where cookbook standards, docs cleanup, or examples belong.

### Failure/Invalid Path Validation

- No child preserves two active cookbook homes.
- No child introduces a second cookbook format separate from `.cookbook.md`.

### Verification Commands

- `ace-task show 8qs.t.x2b`
- `ace-task show 8qs.t.x2b.0`
- `ace-task show 8qs.t.x2b.2`

## Scope of Work

### Included

- Handbook cookbook workflow and skill ownership
- Handbook cookbook template and standards
- Cookbook protocol discovery
- `ace-docs` ownership cleanup
- Two canonical example cookbooks
- Distilled propagation guidance for docs and agent instructions

### Out of Scope

- Implementing cookbook behavior in downstream projects
- Creating provider-specific instruction files that do not already exist
- Rewriting historical changelog entries

## Deliverables

### Behavioral Specifications

- Parent orchestrator contract
- Three child vertical-slice specifications
- Draft usage doc for new cookbook-facing handbook interfaces

### Validation Artifacts

- Task tree with unique child IDs
- Explicit child dependencies

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| handbook-owned cookbook standards and interfaces | `8qs.t.x2b.0` | -- | KEPT |
| ace-docs cookbook ownership cleanup | `8qs.t.x2b.1` | -- | KEPT |
| canonical example cookbooks and distilled propagation | `8qs.t.x2b.2` | -- | KEPT |

## References

- `ace-docs/handbook/workflow-instructions/docs/create-cookbook.wf.md`
- `ace-handbook/handbook/templates/cookbooks/cookbook.template.md`
- `ace-handbook/docs/handbook.md`
- `CLAUDE.md`
- `AGENTS.md`
