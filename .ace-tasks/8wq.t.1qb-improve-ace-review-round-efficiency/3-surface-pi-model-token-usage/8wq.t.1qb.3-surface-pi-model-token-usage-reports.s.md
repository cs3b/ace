---
id: 8wq.t.1qb.3
status: done
priority: medium
created_at: "2026-09-27 01:09:58"
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [.ace-tasks/8wq.t.1qb-improve-ace-review-round-efficiency/8wq.t.1qb-improve-ace-review-round-efficiency-and-usage.s.md]
  commands: []
tags: [ace-review, ace-llm, observability, pi]
parent: 8wq.t.1qb
---

# Surface pi model token usage reports

## Behavioral Specification

### User Experience

- **Input**: An agent session (e.g. an ace-review round) runs through the pi CLI the
  same way it does today; no new operator steps.
- **Process**: The pi client integration reports per-model token usage — input,
  output, and cached tokens — for each model call, and the session records it.
- **Output**: Session reports show real measured usage per model instead of
  "usage unavailable" + estimated costs. On a loop like PR 171 (~3.9M tokens), the
  operator can see the actual cost of the cycle after it finishes.

### Expected Behavior

ace-review 0.55.0 already records per-model usage when the provider supplies it, but
the pi client surfaces none, so pi-sourced sessions mark usage unavailable and all
cost figures stay estimates (issue §5). After this slice, pi-sourced model calls carry
the same usage data as other providers, and any pi call that genuinely cannot report
usage states so explicitly rather than silently.

### Interface Contract

- Agent API surface (provider client layer; exact module names confirmed at replan):
  - pi-sourced completions return usage metadata: `{ model, input_tokens,
    output_tokens, cached_tokens, total_tokens }` — consistent with what other
    provider clients already hand to session usage recording.
  - Missing usage from the CLI is an explicit, classified "unavailable" state
    (reported in the session), not a silent zero.
- Error Handling:
  - pi CLI output lacks usage fields (old CLI version) → session records usage
    unavailable with the pi version if known; no fabricated numbers.
- Edge Cases:
  - Cached-token counts absent for a model → recorded as absent, not 0, so cost
    models can distinguish "no cache" from "unknown".
  - Multi-model sessions keep per-model attribution.

### Success Criteria

- A pi-sourced ace-review session's report shows per-model input/output/cached tokens
  matching the provider's own accounting (spot-checkable against the pi CLI's own
  usage output).
- Sessions no longer print "usage unavailable" for pi calls when the CLI supplies
  data; the unavailable path remains only for genuinely missing data.
- Cost summaries for pi sessions are measured, not estimated.

### Validation Questions

- Does the pi CLI expose usage today (which output/stream), or does this require a pi
  CLI change first? (Discovery is part of the slice; if the CLI cannot report, the
  honest outcome may be a documented upstream request + explicit unavailable state.)
- Should historical sessions with estimated usage be re-costed when usage appears?

## Vertical Slice

- Type: subtask of orchestrator 8wq.t.1qb; independent of .0/.1/.2.
- Size: small (assuming the pi CLI already emits usage; medium if it must be added
  upstream).
- Outcome: pi loops have measured token costs in session reports.

## Verification Plan

### Unit/Component Validation

- Usage parsing maps input/output/cached fields correctly; absent fields stay absent.
- Malformed/missing usage blocks produce the explicit unavailable state.

### Integration/E2E Validation

- A scripted pi-sourced session produces a report with measured per-model usage.

### Failure/Invalid Path Validation

- CLI output without usage fields → session records unavailable, no invented values.

### Verification Commands

- `ace-test ace-llm-providers-cli all` and `ace-test ace-review all`.

## Out of Scope

- Changing pricing/cost models beyond feeding them measured tokens.
- Non-pi providers (they already surface usage).

## References

- cs3b/ace#335 §5 (pi usage reporting ask; ~3.9M-token unmeasured cycle)
