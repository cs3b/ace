---
id: 8rb.t.i73.4
status: draft
priority: medium
created_at: "2026-04-12 12:08:03"
estimate: TBD
dependencies: []
tags: [retros, git, workflow]
parent: 8rb.t.i73
bundle:
  presets: [project]
  files:
    - ace-git/handbook/workflow-instructions/git/rebase.wf.md
    - ace-git/handbook/workflow-instructions/git/reorganize-commits.wf.md
    - ace-git/handbook/workflow-instructions/github/pr/create.wf.md
    - ace-git/handbook/workflow-instructions/github/pr/update.wf.md
    - ace-docs/handbook/workflow-instructions/docs/squash-changelog.wf.md
  commands:
    - ace-task show 8rb.t.i73.4 --content
    - ace-git status
needs_review: false
---

# Finish PR base-branch safety across git workflows

## Objective

Finish the remaining PR base-branch safety work across git workflows by extending actual-base-branch resolution beyond the flows that already have it, while explicitly excluding review-finding verification from this task because that area is already largely covered.

## Behavioral Specification

### User Experience

- A maintainer using git workflows that depend on PR scope or target branch no longer has to rely on `origin/main` as an implicit default when a more accurate PR base is available.
- Workflow guidance becomes consistent across create/update/rebase/reorganize-style flows for target-branch resolution.

### Expected Behavior

1. This task starts from current partial coverage already present:
   - PR update workflow already verifies target branch/base
   - docs squash-changelog workflow already resolves `baseRefName`
   - review-finding verification is already handled elsewhere and is not the target of this task
2. The remaining gap is that some git workflows still default to `origin/main` or equivalent broad assumptions even when PR base context should drive behavior.
3. The intended result is consistency of target/base-branch safety across git workflows that make destructive or scope-defining decisions.
4. This task must not reopen the broader “verify review findings” workstream except where a git workflow directly depends on correct base-branch resolution.

### Interface Contract

- **Workflow surfaces**
  ```bash
  ace-bundle wfi://github/pr/create
  ace-bundle wfi://github/pr/update
  ace-bundle wfi://git/rebase
  ace-bundle wfi://git/reorganize-commits
  ```
- **Behavioral contract**
  - Existing workflow names remain in place.
  - The task improves branch-target resolution behavior and guidance.
  - Review-feedback verification remains out of scope unless needed only as supporting context.

### Success Criteria

- [ ] The spec clearly distinguishes workflows already using actual base-branch resolution from workflows that still rely on `main` defaults.
- [ ] The spec names the remaining git workflows that need consistent base-branch handling.
- [ ] The spec explicitly states that review-finding verification is already addressed and is out of scope here.
- [ ] The verification plan includes one incorrect-base-branch failure scenario.

## Validation Questions

- Some workflows may still keep `main` as a fallback, but the spec should require actual PR/task/worktree context to be preferred when available.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: standalone task
- **Slice outcome**: remaining base-branch safety gaps across git workflows are specified for implementation
- **Advisory size**: medium
- **Context dependencies**: git workflows, PR workflows, task/worktree branch context, `ace-git status`

## Verification Plan

### Unit / Component Validation

- Confirm the spec identifies both the already-covered workflows and the remaining inconsistent ones.

### Integration / E2E Validation

- Confirm a subtask/feature-branch PR scenario can be described without assuming `origin/main` as the base for all git operations.

### Failure / Invalid-Path Validation

- Include a case where a workflow would choose the wrong base branch and describe the expected safety behavior and fallback.

### Verification Commands

- `ace-task show 8rb.t.i73.4 --content`
- `ace-git status`

## Current Coverage Already Present

- PR update already verifies target branch/base.
- docs squash-changelog already resolves `baseRefName`.
- review feedback verification already has dedicated workflows and is not the missing piece here.

## Remaining Gap

- Some git workflows still default to `origin/main` or equivalent assumptions rather than preferring actual PR/task/worktree base information.

## Out of Scope / Already Addressed

- Reworking review-feedback verification as a standalone concern
- Building a new git workflow family from scratch
- Non-git workflow safety work not related to base-branch resolution

## Scope of Work

- specify consistent base-branch resolution across remaining git workflows
- preserve already-correct workflows
- explicitly exclude broader review-verification work

## Deliverables

### Behavioral Specifications

- base-branch safety contract for remaining git workflows

### Validation Artifacts

- usage scenarios for branch resolution in PR-linked workflows

## References

- `ace-git/handbook/workflow-instructions/git/rebase.wf.md`
- `ace-git/handbook/workflow-instructions/git/reorganize-commits.wf.md`
- `ace-git/handbook/workflow-instructions/github/pr/create.wf.md`
- `ace-git/handbook/workflow-instructions/github/pr/update.wf.md`
- `ace-docs/handbook/workflow-instructions/docs/squash-changelog.wf.md`
