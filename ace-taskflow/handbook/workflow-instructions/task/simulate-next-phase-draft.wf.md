---
update:
  frequency: on-change
  last-updated: '2026-02-26'
---

# Simulate Next-Phase Draft Workflow

## Goal

Produce deterministic, read-only LLM analysis for the draft stage of `ace-taskflow review-next-phase`.

## Read-Only Guardrails

- Simulation only: do not create or modify downstream draft/plan/work artifacts.
- Return structured analysis payload only.
- If write-back preview is needed, produce preview content only; do not persist stage artifacts from this workflow.

## Input Contract

- Source content from `--source <idea-ref|task-ref|path>`.
- Source must be parseable as task/idea-style structured content.

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

## Draft-Stage Analysis Requirements

- Identify clarity and completeness of user-facing intent.
- Flag ambiguities that block drafting confidence.
- Propose actionable refinements for scope and acceptance clarity.
- Capture unresolved information needed before plan/work simulation.

## Failure Guidance

### Malformed Source Content

When source is malformed, missing required structure, or unreadable:
- Set `status: failed`.
- Add diagnostic detail to `findings`.
- Add at least one remediation step in `questions` or `refinements`.

### Insufficient Context

When source is valid but incomplete for a reliable draft simulation:
- Set `status: partial`.
- Populate `unresolved_gaps` with concrete missing inputs.
- Keep `findings`, `questions`, and `refinements` actionable.

## Example Output

```yaml
status: partial
findings:
  - "Objective describes desired outcome, but acceptance conditions are incomplete."
questions:
  - "Which validation command should prove success for this change?"
refinements:
  - "Add explicit success criteria for failure and retry behavior."
unresolved_gaps:
  - "No measurable acceptance check is defined."
```
