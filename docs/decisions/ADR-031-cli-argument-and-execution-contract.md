# ADR-031: CLI Argument and Execution Contract

## Status

Accepted
Date: 2026-03-13

## Context

ACE increasingly delegates work to subprocesses and CLI-backed providers. Recent changes across assignment execution, CLI provider adapters, E2E orchestration, and command resolution tightened how arguments, environment, and working directories are passed into subprocesses. The recurring themes are:

- provider CLI arguments may originate from configuration as strings or arrays but need deterministic normalized execution
- subprocesses must receive explicit `working_dir` and selected environment state rather than relying on ambient process cwd or full environment inheritance
- shell interpolation is unsafe for tool delegation because it invites quoting bugs and command injection risk
- result parsing and report routing depend on stable argv structure and explicit context propagation

These patterns are being applied across packages, but the architecture rule has not been recorded in one place.

## Decision

We will standardize ACE subprocess delegation on deterministic argv-array execution with explicit context propagation.

Key aspects of this decision:

- Public configuration may continue to expose string or array forms where already supported, but execution paths must normalize delegated commands to argv arrays before spawning subprocesses.
- String and array semantics remain strict. Implementations must not re-interpret string values through shell parsing or ad hoc tokenization rules that differ across callers.
- Subprocesses must be launched without shell interpolation. Use direct argument-array execution APIs.
- `working_dir` is part of the execution contract and must be propagated explicitly when delegation depends on repository-relative behavior or sandbox-local paths.
- Environment forwarding must be deliberate and minimal. Pass only the required variables for the delegated task instead of blindly inheriting full parent environment state.
- Result parsing, report paths, and verification steps must rely on explicit arguments and propagated context rather than inferred cwd or shell-joined strings.

## Consequences

### Positive

- Delegated execution becomes safer and more predictable.
- Different callers converge on the same subprocess behavior.
- Working-directory-sensitive workflows stop leaking artifacts into unintended locations.
- Tests can assert structured command behavior more reliably.

### Negative

- Callers that previously relied on shell semantics need explicit normalization and propagation logic.
- Some configuration merge paths become more constrained because they must preserve atomic argument semantics.
- Debugging requires inspecting normalized argv and forwarded context rather than one shell command string.

### Neutral

- This ADR does not ban CLI delegation; it defines the contract for how delegation must happen.
- Existing APIs may still accept legacy string inputs while internally normalizing them for deterministic execution.

## Alternatives Considered

### Alternative 1: Shell-joined command strings

- **Description**: Build subprocess commands as shell strings and let the shell parse them.
- **Pros**: Familiar and compact to read.
- **Cons**: Injection risk, quoting fragility, cwd ambiguity, and inconsistent behavior across callers.
- **Why not chosen**: ACE already has evidence that explicit argv handling is safer and more reliable.

### Alternative 2: Ambient cwd and full environment inheritance

- **Description**: Let subprocesses implicitly inherit current working directory and most of `ENV`.
- **Pros**: Less plumbing at call sites.
- **Cons**: Hidden coupling, artifact leakage, and poor sandbox behavior.
- **Why not chosen**: Recent fixes explicitly propagated `working_dir` and stripped unrelated environment state to prevent these failures.

### Alternative 3: In-process Ruby integration everywhere

- **Description**: Eliminate subprocess delegation entirely and require Ruby APIs for all integrations.
- **Pros**: Strong control and reduced shell overhead.
- **Cons**: Not practical for provider CLIs and external tooling that must remain process-based.
- **Why not chosen**: ACE still needs a safe, documented subprocess contract.

## Related Decisions

- [ADR-023: dry-cli Framework](ADR-023-dry-cli-framework.md)
- [ADR-028: Assignment Fork Execution and Recovery](ADR-028-assignment-fork-execution-and-recovery.md)

## References

- `ace-assign/CHANGELOG.md`
- `ace-llm/CHANGELOG.md`
- `ace-llm-providers-cli/CHANGELOG.md`
- `ace-test-runner-e2e/CHANGELOG.md`
- `ace-test-runner/CHANGELOG.md`
- `CHANGELOG.md`

