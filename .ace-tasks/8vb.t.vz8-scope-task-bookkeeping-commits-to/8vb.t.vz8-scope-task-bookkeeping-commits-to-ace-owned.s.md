---
id: 8vb.t.vz8
status: draft
priority: critical
created_at: "2026-08-12 21:19:09"
estimate: TBD
dependencies: []
tags: [worktree, git, safety, bug]
github_issue: 314
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb, ace-git-worktree/lib/ace/git/worktree/molecules/task_committer.rb, ace-git-worktree/lib/ace/git/worktree/molecules/task_status_updater.rb, ace-git-worktree/lib/ace/git/worktree/molecules/hook_executor.rb, ace-git-worktree/lib/ace/git/worktree/configuration.rb, ace-git-worktree/.ace-defaults/git/worktree.yml, ace-git-worktree/test/fast/molecules/task_pusher_test.rb, ace-git-worktree/test/fast/organisms/task_worktree_orchestrator_test.rb, ace-git-worktree/test/feat/subtask_workflow_test.rb, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-002-create-task-worktree.runner.md]
  commands: [ace-git-worktree create --task 8vb.t.vz8 --dry-run, ace-test ace-git-worktree all, ace-test-suite --target fast]
---

# Scope task bookkeeping commits to ACE-owned paths

## Behavioral Specification

### User Experience

- **Input:** A user explicitly enables task bookkeeping commit/push behavior while creating a task-aware worktree in a checkout that may contain unrelated staged, unstaged, or untracked work.
- **Process:** ACE snapshots the complete dirty state and index, proves the exact task paths it owns, mutates and commits only those paths, then verifies the resulting commit before any worktree creation or push.
- **Output:** The user's index and unrelated work remain exactly intact, or ACE stops with recoverable-state evidence before anything is published.

### Expected Behavior

- Before any task lifecycle mutation, ACE snapshots staged, unstaged, and untracked paths plus the exact index representation needed to prove preservation.
- ACE resolves the finite set of target task artifacts it owns, including all intended parent/subtask paths when an operation legitimately spans multiple task files.
- If any target task path has pre-existing staged, unstaged, or untracked edits, ACE fails before lifecycle mutation or commit and identifies the conflict.
- The bookkeeping commit is constructed path-scoped without consuming, unstaging, stashing, cleaning, resetting, or otherwise rewriting the user's index or working tree.
- Before worktree creation or push, ACE verifies the resulting commit's complete changed-path set equals the proven ACE-owned set.

### Interface Contract

The existing explicitly enabled task-aware flow remains the public surface:

```text
ace-git-worktree create --task <task-ref> [configured bookkeeping commit/push enabled]
```

Its result/evidence identifies:

```text
preexisting_dirty: {staged: [...], unstaged: [...], untracked: [...]}
owned_task_paths: [...]
bookkeeping_commit: <sha or null>
committed_paths: [...]
index_preserved: true|false
path_set_verified: true|false
publication: not_attempted|pushed
recovery: <commands/state description when stopped>
```

Error Handling:

- Pre-existing target edits stop before mutation and commit.
- Hook-created files, broad staged state, or any post-commit changed-path mismatch stop before worktree creation and push.
- If preservation cannot be proven, ACE fails closed and reports the current index/working-tree/commit state without destructive recovery.

Edge Cases:

- Invocation from repository root or a linked worktree uses the correct common repository and preserves that checkout's index semantics.
- User dirty state may include all three classes simultaneously and may overlap directories containing—but not equal to—the owned task paths.
- Hooks may modify, stage, or create paths during commit; the post-commit audit detects them even when Git reports commit success.
- The regression shape at commit `23010d8`, where broad staging captured unrelated files during task bookkeeping, must remain covered.

## Success Criteria

- Staged, unstaged, and untracked state is snapshotted before any lifecycle mutation.
- The user index and unrelated working-tree content are byte/entry-equivalent after a successful scoped bookkeeping commit.
- Any pre-existing edit at a target task path blocks before mutation and creates no commit.
- A successful bookkeeping commit contains exactly the proven ACE-owned task paths, including valid multi-task-path operations, and no unrelated path.
- Hook-created or otherwise unexpected commit paths cause a recoverable stop before worktree creation or push.
- No mismatch, uncertainty, or failed verification can publish the commit.
- Root and linked-worktree tests cover every dirty class and the `23010d8` regression shape.

## Validation Questions

- None open. Existing bookkeeping behavior is hardened only when explicitly enabled; exact path ownership, user-index preservation, and pre-push verification are fixed by issue #314.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Flat focused bug task
- **Slice outcome:** Task bookkeeping cannot commit or publish unrelated user changes
- **Advisory size:** Medium
- **Context dependencies:** Task worktree orchestration, task status mutation, commit/hook behavior, config defaults, root/linked Git index semantics

## Verification Plan

### Unit/Component Validation

- Verify dirty-state snapshot, owned-path resolution, target-conflict detection, alternate/scoped index behavior, commit-path audit, and recovery evidence.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Cover root and linked-worktree execution with staged-only, unstaged-only, untracked-only, combined dirty state, multiple task paths, and explicitly enabled push behavior.

### Failure/Invalid Path Validation

- Pre-existing target edits, hook-created files, simulated broad commit scope, post-commit mismatch, and unverifiable index preservation must stop before create/push and leave recoverable evidence.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`
- `ace-e2e run ace-git-worktree`

## Objective

Prevent explicitly enabled task bookkeeping commits from capturing or publishing changes that ACE does not own.

## Scope of Work

- Pre-mutation dirty/index snapshot
- Exact ACE-owned task-path proof and conflict detection
- User-index-preserving scoped commit construction
- Post-commit path-set audit before worktree creation or push
- Root/linked fast, feature, and E2E regression coverage

## Deliverables

### Behavioral Specifications

- Exact ownership, preservation, commit verification, and recovery contract

### Usage Documentation

- `ux-usage.md` covering clean scoped success, target conflict, and hook/mismatch failure

### Validation Artifacts

- Dirty-state matrix, multiple task paths, hook-created files, linked worktrees, and `23010d8` regression fixture

## Out of Scope

- Enabling bookkeeping commit/push by default
- Implementation of issue #311 conservative checkout-only defaults
- Stashing, resetting, cleaning, or automatically rewriting unrelated user state

## References

- https://github.com/cs3b/ace/issues/314
- https://github.com/cs3b/ace/issues/314#issuecomment-5272594802
- Regression shape: commit `23010d8`
- `ux-usage.md`
