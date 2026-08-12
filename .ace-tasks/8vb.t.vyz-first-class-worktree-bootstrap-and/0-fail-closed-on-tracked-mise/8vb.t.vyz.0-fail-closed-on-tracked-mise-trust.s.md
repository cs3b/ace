---
id: 8vb.t.vyz.0
status: draft
priority: high
created_at: "2026-08-12 21:18:59"
estimate: TBD
dependencies: []
tags: [worktree, bootstrap, mise, safety]
parent: 8vb.t.vyz
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/molecules/hook_executor.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_creator.rb, ace-git-worktree/lib/ace/git/worktree/organisms/worktree_manager.rb, ace-git-worktree/test/fast/molecules/worktree_creator_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb]
  commands: [ace-git-worktree create --help, ace-test ace-git-worktree all]
---

# Fail closed on tracked mise trust

## Behavioral Specification

### User Experience

- **Input:** Worktree preparation encounters one or more tracked mise configuration files, including root `.mise.toml`.
- **Process:** ACE discovers exact tracked paths, reports the trust phase, and verifies trust without treating empty shell-glob output as success.
- **Output:** Readiness succeeds only when required tracked configuration is trusted, or returns explicit advisory/required failure evidence.

### Expected Behavior

- Discovery is path-aware and recognizes root `.mise.toml` plus other tracked mise configuration paths supported by the project contract.
- Only tracked project configuration participates; ignored or untracked files cannot silently expand trusted execution.
- The trust command receives exact resolved files or a safe repository-aware operation and verifies its result for each required file.
- No-match discovery is represented as not-applicable, never inferred from a shell glob's exit status.
- Trust failure is required/fail-closed by default; advisory behavior must be explicitly selected in configuration.

### Interface Contract

Preparation output includes:

```text
phase: toolchain_trust
policy: required|advisory
tracked_files: [<repository-relative path>]
status: not_applicable|succeeded|advisory_failed|required_failed
evidence: <per-file result or error>
```

Error Handling:

- Missing mise, command failure, unverified trust state, unreadable tracked file, or inconsistent per-file results fail a required phase.
- Advisory policy exposes the same evidence but permits readiness-with-warning.
- Trust operations never execute arbitrary project setup commands.

Edge Cases:

- Root `.mise.toml`, filenames with spaces, multiple tracked configs, linked worktrees, and a repository with no tracked mise config are handled without shell expansion.
- A tracked config removed between discovery and trust invalidates the phase and is rescanned.
- Untracked `.mise.toml` is reported separately if useful but is not automatically trusted.

## Success Criteria

- Root `.mise.toml` is always discovered when tracked.
- Empty or unmatched glob behavior cannot yield a successful trust phase.
- Every tracked config has explicit trust evidence or causes required failure.
- Required is the default; advisory behavior occurs only through an explicit resolved policy.
- Output clearly distinguishes not-applicable, succeeded, advisory-failed, and required-failed.
- Root, nested, and linked-worktree execution resolves the same tracked files.

## Validation Questions

- None open. Tracked-path discovery and required-by-default trust are fixed by issue #313.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Toolchain trust is a truthful, visible readiness prerequisite
- **Advisory size:** Medium
- **Context dependencies:** Git tracked-file discovery, mise trust behavior, worktree preparation reporting

## Verification Plan

### Unit/Component Validation

- Verify tracked path enumeration, exact argument handling, per-file result checking, and policy/readiness mapping.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise root `.mise.toml`, multiple paths, filenames with spaces, linked worktrees, no-match, and advisory/required configurations.

### Failure/Invalid Path Validation

- Missing mise, command failure, path race, untrusted file, and untracked-only config must never produce a false required success.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`

## Objective

Eliminate false-success toolchain trust and make it an explicit readiness phase.

## Scope of Work

- Tracked mise-config discovery
- Exact trust execution and verification
- Required/advisory phase result reporting
- Root/nested/linked-worktree equivalence

## Deliverables

### Behavioral Specifications

- Trust discovery, execution, evidence, and failure semantics

### Validation Artifacts

- No-match, path, policy, and trust-failure scenarios

## Out of Scope

- Project bootstrap command configuration (`8vb.t.vyz.1`)
- Running the complete preparation sequence (`8vb.t.vyz.2`)

## References

- https://github.com/cs3b/ace/issues/313
- Parent `8vb.t.vyz`
- `../ux-usage.md`
