---
id: 8qs.t.x2b.1
status: done
priority: medium
created_at: "2026-03-29 22:02:43"
estimate: TBD
dependencies: []
tags: [docs, cookbook, ace-docs, migration]
parent: 8qs.t.x2b
bundle:
  presets: [project]
  files: [ace-docs/handbook/workflow-instructions/docs/create-cookbook.wf.md, ace-docs/docs/handbook.md, ace-docs/CHANGELOG.md]
  commands: []
needs_review: false
---

# Migrate cookbook ownership references out of ace-docs

## Objective

Remove active cookbook ownership from `ace-docs` so there is one canonical home for cookbook behavior, while keeping historical changelog entries intact as release history.

## Behavioral Specification

### User Experience

- **Input:** A maintainer or reader looks at `ace-docs` to understand what that package owns.
- **Process:** Active cookbook workflow ownership is removed from `ace-docs`, and any surviving mentions are clearly historical rather than operational.
- **Output:** Users no longer encounter conflicting cookbook ownership when reading `ace-docs`, and there is no active `ace-docs` cookbook workflow to choose by mistake.

### Expected Behavior

1. The active `create-cookbook` workflow file is removed from `ace-docs`.
2. Active docs in `ace-docs` no longer list cookbook creation as a package-owned workflow.
3. Historical changelog entries remain untouched.
4. Current-release changelog messaging may note the ownership move, but history is not rewritten.
5. After migration, a reader of `ace-docs` will not reasonably conclude that cookbook authoring still belongs there.

### Interface Contract

```bash
ace-bundle wfi://docs/update
ace-bundle wfi://handbook/manage-cookbooks
```

### Error Handling

- If `ace-docs` still contains active cookbook docs after the migration, the task is incomplete.
- If historical changelog lines are deleted or rewritten, the task is incorrect.
- If cookbook ownership is removed from `ace-docs` without a handbook-owned replacement already specified by child `8qs.t.x2b.0`, the migration is incomplete.

### Edge Cases

- Changelog references are historical and should remain.
- Package docs should distinguish active ownership references from release history.

## Success Criteria

1. `ace-docs/handbook/workflow-instructions/docs/create-cookbook.wf.md` is no longer an active owned workflow artifact.
2. `ace-docs/docs/handbook.md` no longer lists `create-cookbook.wf.md`.
3. Remaining cookbook mentions in `ace-docs` are historical changelog entries only, or current-release migration notes.
4. No `ace-docs` docs surface tells users to use `ace-docs` for cookbook creation.

## Validation Questions

- No blocking questions remain.
- The task intentionally preserves changelog history instead of “cleaning all mentions,” because those entries document shipped behavior at the time.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type:** Standalone subtask
- **Slice outcome:** `ace-docs` no longer claims active cookbook ownership
- **Advisory size:** Small
- **Context dependencies:** current cookbook workflow file, handbook catalog doc, changelog history

## Verification Plan

### Unit/Component Validation

- `rg -n "create-cookbook\\.wf\\.md|wfi://docs/create-cookbook|as-docs-create-cookbook" ace-docs` returns only historical references that are intentionally preserved.

### Integration/E2E Validation

- A reader navigating `ace-docs/docs/handbook.md` no longer sees cookbook authoring in the active workflow catalog.

### Failure/Invalid Path Validation

- No historical changelog entry is rewritten to erase released behavior.
- No dead handbook reference is left behind in `ace-docs`.

### Verification Commands

- `rg -n "create-cookbook\\.wf\\.md|wfi://docs/create-cookbook|as-docs-create-cookbook" ace-docs`

## Scope of Work

### Included

- Active workflow removal
- Active handbook catalog cleanup
- Current-release migration note if needed

### Out of Scope

- Designing the new handbook cookbook surface
- Writing canonical example cookbooks

## Deliverables

### Behavioral Specifications

- Clear `ace-docs` package-ownership boundary after migration

### Validation Artifacts

- Search result showing only intentional historical mentions remain

## References

- `ace-docs/handbook/workflow-instructions/docs/create-cookbook.wf.md`
- `ace-docs/docs/handbook.md`
- `ace-docs/CHANGELOG.md`
