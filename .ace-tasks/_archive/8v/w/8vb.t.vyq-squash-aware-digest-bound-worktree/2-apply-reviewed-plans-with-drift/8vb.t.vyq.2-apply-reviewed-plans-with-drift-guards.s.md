---
id: 8vb.t.vyq.2
status: done
priority: medium
created_at: "2026-08-12 21:18:48"
estimate: TBD
dependencies: [8vb.t.vyq.1]
tags: [worktree, cleanup, apply, safety]
parent: 8vb.t.vyq
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/cli.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_remover.rb, ace-git-worktree/lib/ace/git/worktree/organisms/worktree_manager.rb, ace-git-worktree/handbook/workflow-instructions/git/worktree-manage.wf.md, ace-git-worktree/handbook/skills/as-git-worktree-manage/SKILL.md, ace-git-worktree/docs/usage.md, ace-git-worktree/test/fast/molecules/worktree_remover_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-007-remove-and-cleanup.runner.md, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-007-remove-and-cleanup.verify.md]
  commands: [ace-bundle wfi://git/worktree-manage, ace-git-worktree prune --dry-run, ace-test ace-git-worktree all]
needs_review: false
---

# Apply reviewed plans with drift guards

## Behavioral Specification

### User Experience

- **Input:** A maintainer reruns cleanup with `--apply` and the SHA-256 digest from a reviewed report.
- **Process:** ACE refreshes apply-time evidence, reconstructs the complete plan, requires an exact digest match, then executes guarded operations in a fixed order and strictly rescans.
- **Output:** The maintainer receives a precise record of removed, retained, failed, and untouched state; approval can never be reused after drift.

### Expected Behavior

- Apply is accepted only with both `--apply` and `--approved-digest <sha256>`; report mode remains the default.
- Before mutation, ACE performs the final fetch/prune required by the configured remote, reconstructs the full inventory/proof/action plan, and compares its canonical digest to approval.
- Operations remove clean non-primary worktrees first, local refs second with expected-SHA checks, and remote refs last with exact force-with-lease semantics.
- Each destructive operation revalidates its relevant dirty/protection/ref evidence immediately before execution.
- Apply stops deterministically after a failure, does not replay completed actions, and finishes with a strict rescan even when partial work succeeded.

### Interface Contract

```text
ace-git-worktree cleanup --target <ref> --remote <name> --apply --approved-digest <sha256> [--require-only-target] [--format json]
```

Structured output includes the approved and reconstructed digest, preflight result, ordered operation ledger, expected/observed SHAs, lease outcomes, partial-failure boundary, final inventory, retained blockers, and strict exit status.

The package ships `wfi://git/worktree-cleanup`, a thin projected skill that delegates to it, user-facing help/usage documentation, and E2E scenarios for the complete report/review/apply loop.

Error Handling:

- Missing, malformed, unknown, or mismatched approval aborts before mutation.
- Ref advancement, new dirty state, changed protection, or different proof/action ordering invalidates the digest and aborts.
- A failed operation stops later operations; the ledger makes a subsequent report and apply safe rather than blindly retrying stale commands.

Edge Cases:

- Any Trash adapter is validated against the exact candidate worktree and rejects repository root, primary checkout, home, broad parents, symlink escapes, and unavailable adapters.
- Remote deletion uses an exact lease and never retries against a newly advanced ref.
- `--require-only-target` fails if the final rescan contains any retained non-target state, while still preserving that state.

## Success Criteria

- Apply cannot begin without an exact approved digest of the current complete plan.
- Any inventory, proof, SHA, dirty/protection, target, remote, or operation-order drift aborts before deletion.
- Clean worktrees, expected-SHA local refs, and exact-lease remote refs are processed in that order.
- Dirty, protected, primary, unresolved, or newly changed items are never removed.
- Partial failure produces a deterministic ledger and strict final rescan without concealing remaining state.
- Workflow instruction, thin skill, help/usage docs, and E2E coverage expose the same safety contract.

## Validation Questions

- None open. Digest approval, operation ordering, exact SHA/lease guards, and strict rescan are fixed by issue #312.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** A reviewed cleanup plan can be applied once, only while the repository still matches it
- **Advisory size:** Large
- **Context dependencies:** Complete inventory, bounded merge proof, worktree/ref removers, remote operations, WFI/skill projection

## Verification Plan

### Unit/Component Validation

- Verify canonical preflight comparison, action ordering, immediate guards, Trash validation, exact leases, operation ledger, and final rescan.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Run report/review/apply from root and linked worktrees with successful, drifted, strict, and partial-failure repositories.

### Failure/Invalid Path Validation

- Mismatched digest, newly dirty path, advanced local/remote ref, unsafe Trash path, and mid-apply remote failure must preserve unapproved state and report recovery evidence.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test ace-git all`
- `ace-test-suite --target fast`
- `ace-e2e run ace-git-worktree`

## Objective

Apply cleanup plans only under exact, current approval with deterministic recovery from partial failure.

## Scope of Work

- Apply flags and canonical plan reconstruction
- Preflight and immediate drift guards
- Ordered worktree/local/remote deletion with exact semantics
- Strict rescan, workflow instruction, skill, docs, and E2E coverage

## Deliverables

### Behavioral Specifications

- Approval, mutation ordering, adapter, failure, and rescan contract

### Usage Documentation

- Cleanup WFI, thin skill, package help, and usage examples

### Validation Artifacts

- Digest drift, exact-ref, partial-failure, unsafe-path, and strict-result scenarios

## Out of Scope

- Deleting any retained or unproven state
- Automatic application or implicit approval

## References

- https://github.com/cs3b/ace/issues/312
- Parent `8vb.t.vyq`
- Dependency `8vb.t.vyq.1`
- `../ux-usage.md`
