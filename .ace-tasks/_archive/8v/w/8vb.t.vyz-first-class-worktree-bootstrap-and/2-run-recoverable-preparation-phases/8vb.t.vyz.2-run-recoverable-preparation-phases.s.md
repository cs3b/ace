---
id: 8vb.t.vyz.2
status: done
priority: high
created_at: "2026-08-12 21:19:05"
estimate: TBD
dependencies: [8vb.t.vyz.0, 8vb.t.vyz.1]
tags: [worktree, bootstrap, readiness, recovery]
parent: 8vb.t.vyz
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/cli/commands/create.rb, ace-git-worktree/lib/ace/git/worktree/molecules/hook_executor.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_creator.rb, ace-git-worktree/lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb, ace-git-worktree/handbook/workflow-instructions/git/worktree-create.wf.md, ace-git-worktree/handbook/skills/as-git-worktree-create/SKILL.md, ace-git-worktree/docs/usage.md, ace-git-worktree/test/fast/organisms/task_worktree_orchestrator_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-002-create-task-worktree.runner.md, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-002-create-task-worktree.verify.md]
  commands: [ace-git-worktree create --help, ace-bundle wfi://git/worktree-create, ace-test ace-git-worktree all]
needs_review: false
---

# Run recoverable preparation phases

## Behavioral Specification

### User Experience

- **Input:** A user creates a worktree, previews creation with dry-run, explicitly skips bootstrap, or retries preparation for an existing identifier.
- **Process:** ACE resolves the configured phases, creates the branch/worktree once, executes trust and bootstrap with visible boundaries, and persists enough evidence to retry failures safely.
- **Output:** The user sees exact phase status, readiness, worktree path, failed command evidence, and a copyable retry command.

### Expected Behavior

- Dry-run shows resolved `worktree_created`, `toolchain_trust`, and `bootstrap` phases plus policy/provenance without creating a branch/worktree or executing commands.
- Normal creation runs required trust and the configured bootstrap command from its resolved working directory with the declared environment and timeout.
- `--no-bootstrap` records an explicit skip; absence of configuration records `not_configured`. Neither state is misreported as executed success.
- Required phase failure preserves the created branch and worktree, returns nonzero, reports the exact path/phase/command/exit or timeout, and prints `ace-git-worktree bootstrap <identifier>`.
- `bootstrap <identifier>` resolves the existing owning worktree and reruns only preparation, never recreating the branch/worktree.

### Interface Contract

```text
ace-git-worktree create <identifier> [--dry-run] [--no-bootstrap] [--json]
ace-git-worktree bootstrap <identifier> [--json]
```

Output includes the resolved identifier and path, current branch/head, config provenance, ordered phase ledger, timestamps/durations, redacted environment keys, readiness (`ready`, `ready_with_warning`, `not_ready`), and exact retry command when not ready.

Error Handling:

- Required trust/bootstrap failure and timeout return nonzero but do not invoke cleanup or delete the new branch/worktree.
- Advisory failure returns success with ready-with-warning and full evidence.
- Retry rejects missing, ambiguous, moved, or wrong-repository identifiers without creating new state.

Edge Cases:

- Interrupted execution leaves a non-success terminal phase that retry can supersede with a new attempt while retaining history.
- Configuration changed between create and retry is shown with previous/current provenance before execution.
- ACE never infers dependency installation, secret acquisition, services, migrations, or seeds from repository files.

## Success Criteria

- Dry-run resolves every phase and source while performing no creation or execution.
- Successful creation reports ready only after all required configured phases succeed or are explicitly/not-applicably absent.
- Required failure leaves the exact branch and worktree present and gives a valid retry command.
- Retry operates on the existing owning worktree and can transition not-ready to ready without recreation.
- Advisory failure produces ready-with-warning; explicit skip and not-configured remain distinguishable.
- Workflow/help/skill and an ignored-state E2E fixture cover create, preserved failure, and retry.

## Validation Questions

- None open. Phase order, preserved failure state, exact retry surface, and no inference are fixed by issue #313.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Worktree preparation succeeds visibly or remains diagnosable and retryable in place
- **Advisory size:** Large
- **Context dependencies:** Fail-closed trust, validated bootstrap policy, creation orchestration, help/WFI/skill, E2E fixtures

## Verification Plan

### Unit/Component Validation

- Verify phase resolution/state transitions, dry-run boundary, timeout/env/working-dir execution, skip/not-configured distinction, evidence persistence, and retry resolution.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Use an ignored-state fixture to create, fail required setup, inspect the preserved worktree, repair prerequisites, retry, and reach ready; also cover advisory and explicit skip.

### Failure/Invalid Path Validation

- Interruption, timeout, failed command, ambiguous identifier, moved worktree, and changed config must never delete state or claim readiness falsely.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`
- `ace-e2e run ace-git-worktree`

## Objective

Integrate explicit preparation into worktree creation with truthful readiness and a safe in-place retry path.

## Scope of Work

- Create dry-run and resolved phase reporting
- Trust/bootstrap execution with timeout/env/working-dir
- Explicit skip, not-configured, required/advisory readiness
- Preserved failure state and bootstrap retry command
- Help/WFI/skill and ignored-state E2E coverage

## Deliverables

### Behavioral Specifications

- Preparation state machine, output, recovery, and readiness contract

### Usage Documentation

- Creation and retry help/workflow/skill guidance

### Validation Artifacts

- Successful, failed, interrupted, advisory, skipped, and retry scenarios

## Out of Scope

- Guessing or generating setup commands
- Cleanup of failed worktrees

## References

- https://github.com/cs3b/ace/issues/313
- Parent `8vb.t.vyz`
- Dependencies `8vb.t.vyz.0`, `8vb.t.vyz.1`
- `../ux-usage.md`
