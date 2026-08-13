---
id: 8vb.t.vyq
status: done
priority: medium
created_at: "2026-08-12 21:18:35"
estimate: TBD
dependencies: []
tags: [worktree, cleanup, safety, orchestrator]
github_issue: 312
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/cli.rb, ace-git-worktree/lib/ace/git/worktree/configuration.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_lister.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_remover.rb, ace-git-worktree/lib/ace/git/worktree/models/worktree_info.rb, ace-git/lib/ace/git/molecules/pr_metadata_fetcher.rb, ace-git/lib/ace/git/molecules/gh_cli_executor.rb, ace-git-worktree/handbook/workflow-instructions/git/worktree-manage.wf.md, ace-git-worktree/docs/usage.md, ace-git-worktree/test/fast/molecules/worktree_lister_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-007-remove-and-cleanup.runner.md]
  commands: [ace-git-worktree list --format json, ace-git-worktree prune --dry-run, ace-test ace-git-worktree all]
---

# Squash-aware digest-bound worktree cleanup

## Behavioral Specification

### User Experience

- **Input:** A maintainer selects a target branch and remote for repository cleanup, optionally requesting offline reporting or applying a previously reviewed plan.
- **Process:** ACE inventories all relevant state, proves which refs are safely represented by the target, emits a canonical plan, and mutates only after exact digest approval and drift revalidation.
- **Output:** The maintainer receives either a report-only cleanup plan or a strict apply result that retains every dirty, protected, unresolved, or changed item.

### Expected Behavior

- Reporting inventories linked worktrees, local refs, and remote refs independently and is safe from repository root, nested directories, and linked worktrees.
- Ancestry is the baseline proof; exact merged-PR-head and bounded stable patch-equivalence evidence may additionally prove squash-merged refs.
- Remote evidence refresh during reporting may fetch objects but does not modify local refs or remote-tracking refs. Final fetch/prune occurs only during apply.
- The default is report-only. Apply requires `--apply --approved-digest <sha256>` and reconstructs the complete plan before any mutation.
- Clean worktrees are removed first, local refs use expected-SHA semantics, remote refs use exact leases, and a strict rescan reports the final state.

### Interface Contract

```text
ace-git-worktree cleanup --target <ref> --remote <name> [--offline] [--format json]
ace-git-worktree cleanup --target <ref> --remote <name> --apply --approved-digest <sha256> [--require-only-target] [--format json]
```

The report identifies repository/common-dir, target and remote evidence, every inventory item, protection and dirty state, proof type, proposed action or retention reason, ordered operations, blockers, and canonical plan digest.

Error Handling:

- Missing target/remote evidence, provider failure, ambiguous association, or unsupported repository state degrades to retention, never deletion.
- Digest or reconstructed-plan drift aborts before mutation.
- Partial apply failure stops deterministically and reports completed, failed, and untouched operations for safe rerun.

Edge Cases:

- Squash merges are eligible only through bounded proof tied to the exact branch/PR relationship; unrelated PRs are never scanned for coincidental patches.
- Dirty worktrees, protected refs, primary checkout, and unresolved refs are always retained.
- `--require-only-target` turns retained non-target state into a nonzero strict result without expanding deletion authority.

## Success Criteria

- Report mode cannot delete a worktree/ref or update local/remote-tracking refs.
- Inventory and digest are equivalent from root, nested, and linked-worktree invocation.
- Only ancestry, exact merged-head, or bounded stable patch-equivalence can prove cleanup eligibility.
- Apply without the exact current digest performs no mutation.
- Apply uses ordered, SHA/lease-guarded operations and finishes with a strict rescan.
- Dirty, protected, ambiguous, provider-unavailable, and drifted state remains intact with an explicit retention reason.

## Validation Questions

- None open. Report-first operation, bounded squash proof, exact digest approval, and fail-closed retention are fixed by issue #312.

## Vertical Slice Decomposition Task/Subtask Model

| Slice | Outcome | Size | Depends on |
| --- | --- | --- | --- |
| `8vb.t.vyq.0` | Complete report-only inventory with ancestry proof | Large | — |
| `8vb.t.vyq.1` | Squash-merged refs classified through bounded GitHub evidence | Large | `8vb.t.vyq.0` |
| `8vb.t.vyq.2` | Reviewed plans applied with digest and drift guards | Large | `8vb.t.vyq.1` |

## Concept Inventory

| Concept | Inputs | Outputs | Owner layer |
| --- | --- | --- | --- |
| Cleanup inventory | repository, target, remote, mode | normalized worktrees and refs | `ace-git-worktree` listing/reporting |
| Merge proof | ref tips, target, bounded PR metadata | proof or retention reason | `ace-git` GitHub integration |
| Cleanup plan | inventory and proofs | ordered actions and digest | worktree cleanup orchestration |
| Guarded apply | approved digest and current state | strict mutation/rescan result | remover/ref operations |

## Verification Plan

### Unit/Component Validation

- Validate inventory normalization, proof classifiers, canonical digest, mutation ordering, SHA/lease guards, and strict rescan.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Cover ancestry merges, squash merges, dirty/protected/unresolved refs, provider loss, root/nested/linked entry points, and report-to-apply drift.

### Failure/Invalid Path Validation

- Digest mismatch, ref advancement, unsafe Trash path, partial remote failure, and ambiguous evidence must preserve unapproved state and produce a recoverable report.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test ace-git all`
- `ace-test-suite --target fast`
- `ace-e2e run ace-git-worktree`

## Objective

Replace ad hoc worktree cleanup with a conservative, reviewable plan that understands squash merges and cannot act on stale approval.

## Scope of Work

- Report-only cleanup command and normalized inventory
- Ancestry and bounded GitHub squash proof
- Canonical plan digest and guarded apply
- Workflow instruction, thin skill, usage documentation, and E2E coverage

## Deliverables

### Behavioral Specifications

- Three linear vertical-slice tasks and this orchestrator contract

### Usage Documentation

- `ux-usage.md` covering report, fallback, drift, and strict apply states

### Validation Artifacts

- Fast, feature, and E2E coverage of proof and mutation boundaries

## Out of Scope

- Scanning unrelated PR history for similar patches
- Deleting dirty, protected, ambiguous, or unproven state
- Automatic cleanup without a reviewed digest

## References

- https://github.com/cs3b/ace/issues/312
- `ux-usage.md`
- Subtasks `8vb.t.vyq.0`, `8vb.t.vyq.1`, `8vb.t.vyq.2`
