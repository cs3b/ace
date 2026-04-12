---
id: 8rb.t.i73.0
status: draft
priority: high
created_at: "2026-04-12 12:08:03"
estimate: TBD
dependencies: []
tags: [retros, safety, ace-task, ace-idea, ace-retro]
parent: 8rb.t.i73
bundle:
  presets: [project]
  files:
    - ace-task/lib/ace/task/molecules/task_creator.rb
    - ace-task/lib/ace/task/molecules/task_reparenter.rb
    - ace-idea/lib/ace/idea/molecules/idea_creator.rb
    - ace-retro/lib/ace/retro/molecules/retro_creator.rb
    - ace-support-markdown/README.md
    - ace-task/handbook/workflow-instructions/task/work.wf.md
  commands:
    - ace-task show 8rb.t.i73.0 --content
needs_review: false
---

# Adopt safe write primitives in task, idea, and retro flows

## Objective

Close the remaining production write-safety gap in domain-managed task, idea, and retro flows by aligning live create/update paths with the safe editing guarantees already documented elsewhere in the repo.

## Behavioral Specification

### User Experience

- A maintainer using `ace-task`, `ace-idea`, or `ace-retro` can trust domain-managed create and update flows to use the same safety standard the repo already recommends for structured markdown mutation.
- Safety-focused follow-up work is limited to still-live production codepaths and does not spend effort re-documenting rules the repo already states clearly.

### Expected Behavior

1. This task covers production codepaths that still use direct file write/update patterns in domain-managed flows.
2. The task explicitly recognizes current coverage already present:
   - repo guidance prefers domain tools over manual frontmatter editing
   - `ace-support-markdown` already defines safe document-editing primitives
3. The remaining gap is the mismatch between that guidance and live production code in task, idea, and retro create/update flows.
4. The implementation contract must preserve existing CLI entrypoints and user-visible behavior while upgrading write safety under the hood.
5. Test-only helper code and non-domain artifact caches are out of scope unless they directly block safe behavior in domain-managed flows.

### Interface Contract

- **Existing public surfaces**
  ```bash
  ace-task create "Title"
  ace-task update <ref> --set status=done
  ace-idea create "Idea"
  ace-retro create "retro-title"
  ```
- **Behavioral contract**
  - No new command names are introduced.
  - Existing create/update flows retain current user-visible semantics.
  - The task changes internal persistence behavior so domain-managed markdown writes become safer and more consistent with repo standards.

### Success Criteria

- [ ] The spec explicitly lists current partial coverage already present in docs/workflows.
- [ ] The spec identifies the remaining live production write paths that still need safer handling.
- [ ] The spec states that public CLI surfaces stay unchanged.
- [ ] The verification plan includes one failure-path scenario around interrupted or malformed structured writes.

## Validation Questions

- This task should not expand into “replace every `File.write` in the monorepo”; focus stays on domain-managed task, idea, and retro flows plus directly related structured updates.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: standalone task
- **Slice outcome**: remaining write-safety gap for domain-managed task, idea, and retro flows is specified for implementation
- **Advisory size**: medium
- **Context dependencies**: task/idea/retro creators and structured update paths, `ace-support-markdown` safety primitives

## Verification Plan

### Unit / Component Validation

- Confirm the spec names the still-live production codepaths that currently use direct write/update behavior.

### Integration / E2E Validation

- Confirm the task preserves current CLI surfaces for `ace-task`, `ace-idea`, and `ace-retro`.

### Failure / Invalid-Path Validation

- Specify an interrupted or malformed-write scenario showing how safe persistence should avoid partial corruption of domain-managed markdown files.

### Verification Commands

- `ace-task show 8rb.t.i73.0 --content`

## Current Coverage Already Present

- Task workflow guidance already tells maintainers not to edit task frontmatter directly and to use domain tools.
- `ace-support-markdown` already documents atomic, frontmatter-aware editing primitives for structured markdown content.

## Remaining Gap

- Production codepaths in task, idea, and retro create/update flows still use direct write/update patterns instead of the shared safe primitives.

## Out of Scope / Already Addressed

- Re-documenting why safe editing matters
- Broad replacement of every raw file-write in unrelated packages
- Introducing new end-user CLI commands for this concern

## Scope of Work

- Specify the remaining task/idea/retro write-safety upgrade work
- Bind the task to concrete production codepaths
- Preserve current CLI behavior while changing safety guarantees underneath

## Deliverables

### Behavioral Specifications

- safe persistence contract for task/idea/retro domain-managed flows

### Validation Artifacts

- verification scenarios for healthy-path and interrupted-write behavior

## References

- `ace-support-markdown/README.md`
- `ace-task/lib/ace/task/molecules/task_creator.rb`
- `ace-task/lib/ace/task/molecules/task_reparenter.rb`
- `ace-idea/lib/ace/idea/molecules/idea_creator.rb`
- `ace-retro/lib/ace/retro/molecules/retro_creator.rb`
