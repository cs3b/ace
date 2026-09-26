---
id: 8vb.t.vyz.1
status: done
priority: high
created_at: "2026-08-12 21:19:02"
estimate: TBD
dependencies: []
tags: [worktree, bootstrap, config, provenance]
parent: 8vb.t.vyz
bundle:
  presets: [project]
  files: [ace-git-worktree/lib/ace/git/worktree/configuration.rb, ace-git-worktree/lib/ace/git/worktree/commands/config_command.rb, ace-git-worktree/lib/ace/git/worktree/cli/commands/config.rb, ace-git-worktree/lib/ace/git/worktree/molecules/config_loader.rb, ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb, ace-git-worktree/test/fast/models/worktree_config_test.rb, ace-git-worktree/test/e2e/TS-WORKTREE-001-basic-lifecycle/TC-007-config-surface-validation.runner.md]
  commands: [ace-git-worktree config show --json, ace-git-worktree config validate --bootstrap --json, ace-test ace-git-worktree all]
needs_review: false
---

# Configure project setup policy with provenance

## Behavioral Specification

### User Experience

- **Input:** A maintainer initializes project worktree configuration or sets, inspects, and validates bootstrap policy.
- **Process:** ACE writes only the requested project override, resolves it through the package/user/project cascade, validates every field, and attributes each effective value to its source.
- **Output:** Humans and automation can see the exact command policy that will run and why, before creating a worktree.

### Expected Behavior

- `config init` creates only a minimal project override and does not copy the full package defaults.
- `config set-bootstrap` supports command, worktree-relative working directory, finite timeout, explicit environment, and required/advisory policy.
- `config show --json` exposes resolved values plus package, user, or project provenance for each value.
- `config validate --bootstrap` validates syntax, types, paths, timeout, environment keys, and policy without executing bootstrap.
- Repeated init/set operations are deterministic and preserve unrelated project configuration.

### Interface Contract

```text
ace-git-worktree config init
ace-git-worktree config set-bootstrap --command <command> [--working-dir <path>] [--timeout <seconds>] [--required|--advisory] [--env KEY=VALUE]
ace-git-worktree config show --json
ace-git-worktree config validate --bootstrap [--json]
```

Resolved JSON contains a schema version, config file locations, effective bootstrap object, per-field provenance, validation status, and actionable errors. Environment values that are sensitive are redacted in output while their presence and source remain visible.

Error Handling:

- Empty commands, absolute/escaping working directories, nonpositive or excessive timeouts, malformed environment keys, contradictory policy flags, and invalid config syntax return nonzero without partial writes.
- Initialization refuses to overwrite an incompatible existing project override and explains the exact conflict.
- Missing optional package/user files are normal; unreadable or malformed files are surfaced with their cascade source.

Edge Cases:

- A project may deliberately configure no bootstrap; `show` reports `not_configured` rather than inventing a command.
- Project values override user and package values field-by-field according to the existing cascade contract.
- Commands with arguments are stored as a command contract without unsafe reparsing or lossy quoting.

## Success Criteria

- Init creates a minimal, valid, idempotent project override and preserves unrelated content.
- Set-bootstrap represents command, working directory, timeout, environment, and required/advisory policy.
- Show JSON identifies the effective value and exact cascade source for every field.
- Validate detects all invalid/contradictory states and runs no project command.
- Failed writes leave the prior configuration byte-for-byte intact.
- No setup behavior is inferred when configuration is absent.

## Validation Questions

- None open. Command policy fields, minimal override, and provenance reporting are fixed by issue #313.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Projects can declare and audit exactly what worktree preparation is allowed to run
- **Advisory size:** Large
- **Context dependencies:** Worktree configuration cascade, config CLI/models, structured output and validation

## Verification Plan

### Unit/Component Validation

- Verify init/set atomicity, cascade merge/provenance, field validation, sensitive-value redaction, and deterministic JSON.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise package/user/project precedence, minimal initialization, repeated updates, invalid existing files, and no-bootstrap state.

### Failure/Invalid Path Validation

- Invalid paths, timeout, environment, policy, syntax, and incompatible existing config must fail without partial mutation or command execution.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`

## Objective

Give projects an explicit, validated bootstrap policy whose effective values and sources are always inspectable.

## Scope of Work

- Config init/set-bootstrap/show/validate interfaces
- Minimal project override and atomic updates
- Command/working-dir/timeout/env/policy schema
- Cascade provenance and sensitive output handling

## Deliverables

### Behavioral Specifications

- Configuration commands, schema, provenance, and validation contract

### Validation Artifacts

- Cascade, idempotency, invalid-state, atomic-write, and redaction scenarios

## Out of Scope

- Inferring or executing bootstrap commands
- Toolchain trust implementation (`8vb.t.vyz.0`)

## References

- https://github.com/cs3b/ace/issues/313
- Parent `8vb.t.vyz`
- `../ux-usage.md`
