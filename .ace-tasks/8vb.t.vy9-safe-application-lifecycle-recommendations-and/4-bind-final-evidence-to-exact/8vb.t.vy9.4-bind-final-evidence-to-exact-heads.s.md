---
id: 8vb.t.vy9.4
status: draft
priority: high
created_at: "2026-08-12 21:18:26"
estimate: TBD
dependencies: [8vb.t.vy9.3]
tags: [review, delivery, receipts, merge]
parent: 8vb.t.vy9
bundle:
  presets: [project]
  files: [ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/.ace-defaults/assign/catalog/steps/review-pr.step.yml, ace-assign/.ace-defaults/assign/catalog/steps/rebase-with-main.step.yml, ace-assign/.ace-defaults/assign/catalog/steps/update-pr-desc.step.yml, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-git/handbook/workflow-instructions/github/pr/create.wf.md, ace-git/handbook/workflow-instructions/github/pr/update.wf.md, ace-review/lib/ace/review/organisms/review_manager.rb]
  commands: [ace-bundle wfi://assign/drive, ace-bundle wfi://github/pr/update, ace-git pr --format json]
---

# Bind final evidence to exact heads

## Behavioral Specification

### User Experience

- **Input:** A task assignment reaches its final review, release-readiness, or guarded-merge gate.
- **Process:** ACE records evidence against the exact PR and repository state, invalidates it after relevant mutation, and reconstructs the final decision before authorization.
- **Output:** The user receives a report-only merge decision and canonical digest that clearly identifies current evidence, stale evidence, and the permitted next action.

### Expected Behavior

- Review and release receipts bind the PR identity, head commit and tree, changed-file scope or digest, successful artifacts and gates, and terminal feedback state.
- Any feedback edit, rebase, task-status commit, retrospective commit, generated-artifact mutation, or other head/tree/scope change invalidates prior receipts.
- Final delivery reacquires required evidence after its last mutation rather than treating an earlier successful check as transferable.
- Guarded merge is report-only by default and emits a deterministic canonical digest for the complete decision and evidence set.
- Auto-merge preset selection is advance authorization only while evidence remains exact, complete, non-flaky, and unambiguous; otherwise ACE downgrades to merge approval.

### Interface Contract

The assignment report exposes at least:

```text
pr: <number>
head: <commit-sha>
tree: <tree-sha>
changed_scope_digest: <sha256>
review_receipt: current|stale|missing
release_receipt: current|stale|missing
feedback_state: terminal|open|unknown
merge_decision: report-only|approval-required|authorized
decision_digest: <sha256>
```

Error Handling:

- Missing, stale, expanded, flaky, provider-unavailable, or uncertain evidence never authorizes merge.
- A digest mismatch or reconstructed-decision mismatch stops before mutation and reports the fields that changed.
- A provider response that cannot prove terminal feedback is treated as unknown, not success.

Edge Cases:

- A task-status or retrospective-only commit changes the bound head even when implementation files are unchanged.
- A rebase with an equivalent patch still invalidates receipts because the exact commit/tree binding changed.
- This slice does not introduce an independent public merge command; the contract is surfaced by assignment delivery.

## Success Criteria

- Every receipt includes PR, exact head/tree, changed scope, successful artifacts, and feedback state.
- Each enumerated mutation invalidates prior receipts and prevents reuse.
- Identical complete evidence produces the same canonical decision digest.
- Report-only remains the default and performs no merge.
- Auto-merge authorization reliably downgrades to explicit approval for every stale, incomplete, expanded, flaky, or uncertain state.
- Failure reports identify the invalidated receipt and exact evidence delta without claiming completion.

## Validation Questions

- None open. Exact-head binding, mutation invalidation, report-only default, and conservative authorization are fixed by issue #311.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Final delivery decisions are reproducible and cannot outlive the repository state they reviewed
- **Advisory size:** Large
- **Context dependencies:** Outcome presets, assignment drive, PR workflows, review execution, feedback handling

## Verification Plan

### Unit/Component Validation

- Verify receipt serialization, canonical digest stability, mutation invalidation, and downgrade classification.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise review through feedback edits, rebase, status/retrospective commits, final report, approval, and authorized auto-merge paths.

### Failure/Invalid Path Validation

- Simulate missing artifacts, expanded scope, flaky gates, provider uncertainty, and digest drift; each must block mutation and retain recoverable evidence.

### Verification Commands

- `ace-test ace-assign all`
- `ace-test ace-review all`
- `ace-test ace-git all`
- `ace-test-suite --target fast`

## Objective

Make final review, release, and guarded-merge evidence valid only for the exact state it proves.

## Scope of Work

- Exact PR/head/tree/scope receipt schema
- Receipt invalidation after repository or artifact mutation
- Canonical report-only merge decision digest
- Conservative auto-merge authorization downgrade

## Deliverables

### Behavioral Specifications

- Receipt lifecycle, invalidation events, and merge-decision contract

### Validation Artifacts

- Exact-head, mutation, digest, provider-failure, and authorization scenarios

## Out of Scope

- Outcome preset definitions (`8vb.t.vy9.3`)
- Squash-aware worktree cleanup (`8vb.t.vyq`)
- Bootstrap readiness (`8vb.t.vyz`)

## References

- https://github.com/cs3b/ace/issues/311
- https://github.com/cs3b/ace/issues/311#issuecomment-5272561943
- Parent `8vb.t.vy9`
- Dependency `8vb.t.vy9.3`
- `../ux-usage.md`
