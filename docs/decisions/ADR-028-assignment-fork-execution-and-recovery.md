# ADR-028: Assignment Fork Execution and Recovery

## Status

Accepted
Date: 2026-03-13

## Context

Assignment execution has evolved from simple linear phase driving into scoped subtree execution with explicit fork delegation, status semantics, rerun handling, and overseer integration. Recent work established that assignment execution is not just "run the current phase." Operators and tooling now rely on explicit subtree scopes such as `--assignment <id>@<phase>`, fork-root execution, scoped status output, stall detection, rerun recovery, and completion evidence.

These behaviors are now spread across the assignment executor, fork launcher, status workflows, and overseer views:

- scoped assignment targeting is used across commands and status output
- `fork-run` executes targeted fork-enabled subtrees instead of relying on the global current phase
- subtree stall detection and stall-reason clearing on successful rerun are persisted as part of runtime state
- provider/LLM failures are surfaced as actionable blocked or stalled work rather than silent success
- overseer and related workflows now require assignment-completion evidence and post-action verification artifacts

Without a documented architectural contract, future changes could regress subtree-first behavior, hide provider failures, or mark forked work complete without evidence.

## Decision

We will treat scoped subtree execution, fork delegation, recovery behavior, and completion evidence as part of the assignment execution contract.

Key aspects of this decision:

- Assignment-targeting commands may address either a whole assignment or an explicit subtree via `--assignment <id>@<phase>`.
- When a targeted subtree is fork-enabled, execution delegates to the scoped fork root and remains confined to that subtree for status, advancement, and completion checks.
- Fork state is modeled explicitly. A fork marker on a parent/root phase defines a runtime delegation boundary; child presence alone does not imply fork semantics.
- Stall detection is a first-class runtime outcome. Provider/LLM failures, missing session identifiers, and equivalent execution breakdowns must surface as stalled or failed work with recorded evidence, not as implicit success.
- Successful reruns clear stale stall indicators within the targeted subtree and re-establish truthful status.
- Completion requires evidence. A forked subtree is not complete merely because a subprocess exited; the relevant workflow must verify the scoped outcome and preserve traceability artifacts.

## Consequences

### Positive

- Assignment drivers, status displays, and operator workflows share one execution model.
- Scoped reruns become safe because the targeted subtree is the source of truth.
- Provider and runtime failures become diagnosable state instead of silent ambiguity.
- Overseer and cleanup workflows can reason about assignment safety using explicit evidence.

### Negative

- Assignment execution logic is more stateful and requires more metadata.
- Status rendering and recovery flows must continue to understand scoped subtree semantics.
- Provider integration failures now impose documentation and traceability requirements instead of being treated as transient noise.

### Neutral

- Whole-assignment execution remains supported; the ADR formalizes how explicit subtree scopes behave when used.
- Fork execution remains a workflow/runtime concept rather than a new top-level assignment type.

## Alternatives Considered

### Alternative 1: Global-current-phase execution only

- **Description**: Ignore subtree scopes and always advance the assignment's global current phase.
- **Pros**: Simpler mental model and less status complexity.
- **Cons**: Incorrect for split subtrees, parallel child work, and scoped reruns.
- **Why not chosen**: ACE now relies on explicit subtree targeting for correct forked execution.

### Alternative 2: Best-effort fork execution with no persistent stall state

- **Description**: Retry or fail transiently without recording stall reasons or recovery state.
- **Pros**: Less runtime metadata.
- **Cons**: Poor operator visibility, misleading status output, and weak recovery guidance.
- **Why not chosen**: Recent executor and status changes already treat stall state as durable operational data.

### Alternative 3: Treat subprocess exit as sufficient completion evidence

- **Description**: Mark forked work complete when the fork launcher exits successfully.
- **Pros**: Minimal verification logic.
- **Cons**: Misses wrong-scope execution, incomplete subtree outcomes, and provider-level false positives.
- **Why not chosen**: Assignment workflows now require scoped outcome verification and evidence preservation.

## Related Decisions

- [ADR-001: Workflow Self-Containment Principle](ADR-001-workflow-self-containment-principle.md)
- [ADR-023: dry-cli Framework](ADR-023-dry-cli-framework.md)
- [ADR-031: CLI Argument and Execution Contract](ADR-031-cli-argument-and-execution-contract.md)

## References

- `ace-assign/CHANGELOG.md`
- `ace-overseer/CHANGELOG.md`
- `ace-task/CHANGELOG.md`
- `ace-assign/handbook/workflow-instructions/assign/drive.wf.md`
- `ace-assign/handbook/guides/fork-context.g.md`

