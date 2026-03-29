---
id: 8qs.t.j24.2
status: draft
priority: high
created_at: "2026-03-29 12:42:28"
estimate: TBD
dependencies: []
tags: [ace-handbook, skills, workflow, docs, dx]
parent: 8qs.t.j24
bundle:
  presets: [project]
  files:
    - ace-handbook/lib/ace/handbook/organisms/provider_syncer.rb
    - ace-handbook/README.md
    - ace-handbook/docs/getting-started.md
    - ace-handbook/docs/usage.md
    - ace-handbook/docs/handbook.md
  commands: []
---

# Clarify ace-handbook sync completeness and project handbook extension

## Objective

Make `ace-handbook sync` understandable for first-time users and document how project-specific handbook assets are added and discovered outside the ACE monorepo.

## Behavioral Specification

### User Experience

- **Input:** A user installs ACE in a normal project, runs `ace-handbook sync`, and wants to understand what was projected and how to add project-specific skills, workflows, guides, and templates.
- **Process:** ACE documents the expected project layout, protocol usage, and sync completeness story. Sync output and docs explain when only built-in skills are available and when a rerun is expected after full install.
- **Output:** Users understand where custom handbook assets live, how protocols resolve in project context, and why sync counts may change after full gem installation.

### Expected Behavior

1. Docs explain where project-specific handbook assets live outside the ACE monorepo.
2. Docs explain how `wfi://`, `guide://`, `tmpl://`, and `skill://` are meant to work in ordinary projects.
3. `ace-handbook sync` no longer leaves partial skill projection as unexplained behavior.
4. The onboarding story explicitly covers install/init/sync ordering when it affects projected inventory.
5. Users can add one project-specific workflow or skill without repo archaeology.

### Interface Contract

```bash
ace-handbook sync
ace-nav list 'wfi://handbook/*'
ace-nav resolve wfi://handbook/manage-guides
```

```text
synced <provider> -> <dir> (...)
# plus clear guidance when projected inventory is partial or when rerun-after-install is expected
```

### Error Handling

- If docs still imply ACE-monorepo-only handbook paths, the task is incomplete.
- If sync output remains silent about obviously partial projection states, the task is incomplete.

### Edge Cases

- Projects with only one agent integration installed
- Projects defining custom workflows without custom skills yet
- Projects that run sync before the full ACE stack is installed

## Success Criteria

1. A user can follow docs to add a project-specific workflow or skill in the right place.
2. The sync completeness story is explicit rather than accidental.
3. Protocol documentation covers non-monorepo usage.
4. This child provides accurate input to the final onboarding docs child.

## Validation Questions

- No blocking questions remain.
- The slice includes both docs and sync-completeness behavior, not docs alone.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** handbook sync explanation, project asset locations, protocol guidance
- **Advisory size:** Medium
- **Context dependencies:** handbook syncer, handbook docs, protocol discovery story

## Verification Plan

### Unit/Component Validation

- Sync output contract is explicit enough to distinguish a partial projection story.
- Docs name concrete project-level asset locations.

### Integration/E2E Validation

- A normal project can add and reason about custom handbook content.
- Sync rerun guidance is understandable after install order changes.

### Failure/Invalid Path Validation

- Hidden monorepo assumptions are failure.
- Silent partial projection is failure.

### Verification Commands

- `ace-handbook sync`
- `ace-nav list 'wfi://handbook/*'`
- `ace-nav resolve wfi://handbook/manage-guides`

## Scope of Work

### Included

- Project handbook asset location guidance
- Protocol usage guidance for normal projects
- Sync completeness explanation

### Out of Scope

- Replacing the provider sync model entirely
- Redesigning protocol resolution beyond what is needed for clarity and consistency

## Deliverables

### Behavioral Specifications

- Handbook sync completeness contract
- Project extension contract for skills/workflows/guides/templates

### Validation Artifacts

- Project-level handbook extension scenario
- Sync ordering scenario

## References

- Usage doc: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/2-clarify-ace-handbook-sync-completeness/ux-usage.md`
- Parent task: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/8qs.t.j24-new-project-onboarding-hardening-rollout.s.md`
