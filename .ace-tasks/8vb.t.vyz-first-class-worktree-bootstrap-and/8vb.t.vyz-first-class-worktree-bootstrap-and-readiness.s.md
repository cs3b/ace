---
id: 8vb.t.vyz
status: done
priority: high
created_at: "2026-08-12 21:18:52"
estimate: TBD
dependencies: []
tags: [worktree, bootstrap, readiness, orchestrator]
github_issue: 313
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/cli.rb, ace-git-worktree/lib/ace/git/worktree/configuration.rb, ace-git-worktree/lib/ace/git/worktree/commands/config_command.rb, ace-git-worktree/lib/ace/git/worktree/molecules/config_loader.rb, ace-git-worktree/lib/ace/git/worktree/molecules/hook_executor.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_creator.rb, ace-git-worktree/lib/ace/git/worktree/organisms/task_worktree_orchestrator.rb, ace-git-worktree/handbook/workflow-instructions/git/worktree-create.wf.md, ace-git-worktree/handbook/skills/as-git-worktree-create/SKILL.md, ace-git-worktree/test/fast/molecules/worktree_creator_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb, ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-002-create-task-worktree.runner.md]
  commands: [ace-git-worktree config show --json, ace-git-worktree create --help, ace-bundle wfi://git/worktree-create, ace-test ace-git-worktree all]
needs_review: false
---

# First-class worktree bootstrap and readiness

## Behavioral Specification

### User Experience

- **Input:** A maintainer configures project setup policy or creates/retries an ACE worktree.
- **Process:** ACE resolves configuration with provenance, verifies tracked mise trust, runs only the explicitly configured bootstrap phases, and preserves a failed worktree for diagnosis and retry.
- **Output:** The command reports phase-by-phase readiness as `ready`, `ready-with-warning`, or `not-ready`, including an exact retry command when required setup fails.

### Expected Behavior

- Tracked `.mise.toml` trust is a visible preparation phase and fails readiness by default when trust cannot be established; advisory trust must be explicitly configured.
- Project bootstrap configuration supports command, working directory, timeout, environment, and required/advisory policy, with validation and cascade provenance.
- Creation dry-run resolves and displays trust/bootstrap phases but runs none of them.
- Creation runs only configured setup, exposes explicit `--no-bootstrap`, and never infers package managers, dependencies, secrets, services, migrations, or seed commands.
- Required setup failure preserves the created branch and worktree, returns nonzero, marks readiness failed, and prints the exact `ace-git-worktree bootstrap <identifier>` retry command.

### Interface Contract

```text
ace-git-worktree config init
ace-git-worktree config set-bootstrap --command <command> [--working-dir <path>] [--timeout <seconds>] [--required|--advisory] [--env KEY=VALUE]
ace-git-worktree config show --json
ace-git-worktree config validate --bootstrap [--json]
ace-git-worktree create <identifier> [--dry-run] [--no-bootstrap]
ace-git-worktree bootstrap <identifier> [--json]
```

Phase output identifies `worktree_created`, `toolchain_trust`, and `bootstrap` as pending, running, succeeded, skipped, advisory-failed, or required-failed, with resolved source and readiness result.

Error Handling:

- Invalid or contradictory setup configuration fails validation before creation.
- Required trust/bootstrap failure returns nonzero without deleting the branch/worktree; advisory failure returns ready-with-warning.
- Retry resolves the owning worktree and current configuration, reports changes since the failed attempt, and never recreates or silently moves the branch.

Edge Cases:

- No bootstrap configuration is reported as `not_configured`; it triggers no guessed command and does not itself block readiness.
- `--no-bootstrap` is a visible explicit skip, not a successful execution receipt.
- Paths and phase behavior are equivalent from repository root, nested directories, and linked worktrees.

## Success Criteria

- Tracked `.mise.toml` trust cannot falsely succeed because a shell glob produced no path.
- Config init/set/show/validate expose the minimal project override and exact provenance.
- Dry-run displays resolved phases without creating or executing anything.
- Required failures preserve worktree/branch and return an exact retry command; successful retry updates readiness.
- No package manager, secret, service, migration, or seed behavior is inferred.
- Help, worktree-create workflow, thin skill, and ignored-state E2E fixture describe and prove the same contract.

## Validation Questions

- None open. Required-by-default trust, explicit configuration, no inference, preserved failure state, and retry surface are fixed by issue #313.

## Vertical Slice Decomposition Task/Subtask Model

| Slice | Outcome | Size | Depends on |
| --- | --- | --- | --- |
| `8vb.t.vyz.0` | Tracked mise trust is explicit and fail-closed | Medium | — |
| `8vb.t.vyz.1` | Project bootstrap policy is configurable and attributable | Large | — |
| `8vb.t.vyz.2` | Creation/retry executes recoverable preparation phases | Large | `8vb.t.vyz.0`, `8vb.t.vyz.1` |

## Concept Inventory

| Concept | Inputs | Outputs | Owner layer |
| --- | --- | --- | --- |
| Toolchain trust | tracked `.mise.toml`, policy | explicit trust phase | worktree preparation |
| Bootstrap policy | project/user/package configuration | validated resolved policy and provenance | config CLI/loader |
| Preparation runner | created worktree and resolved phases | readiness and retry evidence | creation/bootstrap orchestration |
| Readiness | phase outcomes | ready/warning/not-ready | CLI and structured reporting |

## Verification Plan

### Unit/Component Validation

- Validate tracked-config discovery, policy cascade/provenance, phase state machine, timeout/env/working-dir handling, skip and retry output.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Cover create/dry-run/retry with successful, required-failed, advisory-failed, skipped, and not-configured states from all entry points.

### Failure/Invalid Path Validation

- Untrusted mise config, invalid policy, timeout, missing command, and failed retry retain the exact worktree/branch and provide actionable evidence.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`
- `ace-e2e run ace-git-worktree`

## Objective

Make every new worktree explicitly ready for development, or visibly recoverable when required preparation fails.

## Scope of Work

- Fail-closed tracked mise trust
- Bootstrap configuration commands and provenance
- Creation/dry-run/retry phase execution and readiness
- Workflow/help/skill updates and ignored-state E2E fixture

## Deliverables

### Behavioral Specifications

- Three vertical slices and this readiness contract

### Usage Documentation

- `ux-usage.md` covering configuration, failure, retry, skip, and advisory behavior

### Validation Artifacts

- Fast, feature, and E2E readiness scenarios

## Out of Scope

- Inferring project setup commands or managing secrets/services/migrations/seeds
- Application lifecycle defaults in issue #311

## References

- https://github.com/cs3b/ace/issues/313
- `ux-usage.md`
- Subtasks `8vb.t.vyz.0`, `8vb.t.vyz.1`, `8vb.t.vyz.2`
