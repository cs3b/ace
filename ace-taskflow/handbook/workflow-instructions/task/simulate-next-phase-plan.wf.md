---
update:
  frequency: on-change
  last-updated: '2026-02-26'
---

# Simulate Next-Phase Plan Workflow

## Goal

Produce deterministic, read-only LLM analysis for the plan stage of `ace-taskflow review-next-phase`, using prior draft-stage context.

## Read-Only Guardrails

- Simulation only: do not create or modify downstream draft/plan/work artifacts.
- Return structured analysis payload only.
- This workflow informs synthesis/write-back layers but does not persist implementation outputs.

## Input Contract

- Source content from `--source <idea-ref|task-ref|path>`.
- Prior draft-stage context from the preceding simulation stage.
- Prior context should include draft findings/questions/refinements and status.

## Output Contract

Return a single structured payload with this exact shape:

```yaml
status: ok|partial|failed
findings:
  - "..."
questions:
  - "..."
refinements:
  - "..."
unresolved_gaps:
  - "..."   # optional; include when context is incomplete
```

## Plan-Stage Analysis Requirements

- Use prior draft-stage output as required context, not optional reference.
- Convert draft insights into implementation-oriented checks and sequencing guidance.
- Preserve unresolved constraints from draft and add plan-specific risks/questions.
- Ensure refinements are concrete enough for deterministic downstream synthesis.

## Failure Guidance

### Missing Prior Draft Context

When draft-stage context is unavailable or malformed:
- Set `status: failed`.
- Describe contract mismatch in `findings`.
- Add remediation in `questions` or `refinements`.

### Insufficient Combined Context

When source and draft context exist but remain insufficient for a reliable plan simulation:
- Set `status: partial`.
- Populate `unresolved_gaps` with concrete missing inputs.
- Keep `findings`, `questions`, and `refinements` actionable.

## Example Output

```yaml
status: ok
findings:
  - "Draft-stage constraints are clear enough to produce a sequenced plan."
questions:
  - "Should verification run only targeted tests or include full suite validation?"
refinements:
  - "Add a rollback note for each high-risk file modification."
unresolved_gaps: []
```
