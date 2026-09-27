---
id: 8wq.t.1qb.1
status: done
priority: medium
created_at: "2026-09-27 01:09:55"
estimate: TBD
dependencies: [8wq.t.1qb.0]
bundle:
  presets: [project]
  files: [.ace-tasks/8wq.t.1qb-improve-ace-review-round-efficiency/8wq.t.1qb-improve-ace-review-round-efficiency-and-usage.s.md]
  commands: []
tags: [ace-review, review-rounds]
parent: 8wq.t.1qb
---

# Accept exempt-path deltas without model calls

## Behavioral Specification

### User Experience

- **Input**: A project declares review-exempt paths in its review configuration
  (e.g. formatting-only rewrites, changelogs, generated files). The operator runs a
  review round whose delta touches only those paths.
- **Process**: The round recognizes the delta as fully exempt and records a no-op
  session: the evidence states "this delta is review-exempt (paths: …)" without any
  model call. When the delta mixes exempt and non-exempt paths, the round reviews the
  non-exempt part and notes which paths were exempt.
- **Output**: A completed session/report with verdict, zero model cost for fully
  exempt rounds, and an explicit list of the exempt paths that justified the skip.

### Expected Behavior

Format-only/docs-only deltas currently still trigger full model reports (issue §3:
"Trivial deltas … still need model reports"). After this slice, a fully exempt delta
completes in seconds with a recorded, auditable no-op session; a mixed delta never
silently skips its non-exempt part.

### Interface Contract

```bash
# Configuration surface (project review config)
# exempt_paths:            # patterns of paths whose deltas never require a model report
#   - "**/*.golden"
#   - "CHANGELOG.md"

# CLI behavior
ace-review --pr <identifier>            # full round; exempt paths inside the diff are excluded from the subject and listed
ace-review --pr <identifier> --delta    # delta round (8wq.t.1qb.0); empty non-exempt delta => no-op exempt session
```

- Error Handling:
  - Exempt-path pattern is malformed/overly broad (e.g. matches everything) → refuse
    at config load with the offending pattern named; never silently exempt the world.
  - All paths in a requested non-delta round are exempt → still perform the full round
    (full rounds are explicit operator intent; exemption applies to deltas).
- Edge Cases:
  - A file is renamed/moved onto an exempt path → treated by its destination path.
  - Case-only or mode-only changes → follow the path's exemption status.

### Success Criteria

- A delta touching only declared exempt paths completes with a recorded no-op session
  and zero model calls (observable in session usage records).
- A mixed delta produces a report scoped to non-exempt paths only, with exempt paths
  enumerated.
- Exemption decisions are visible in the session report (which paths, which patterns).

### Validation Questions

- Are exempt paths also honored in full (non-delta) PR rounds as subject exclusions,
  or only in delta/no-op acceptance?
- Who may declare exempt paths (project config only, or CLI override), and does an
  operator override need to be recorded in the session?
- Should exemption be time-boxed (e.g. re-review exempt paths after N days) to bound
  drift risk?

## Vertical Slice

- Type: subtask of orchestrator 8wq.t.1qb; builds on the delta/evidence model from
  8wq.t.1qb.0.
- Size: small.
- Outcome: trivial deltas cost zero model time while remaining auditable.

## Verification Plan

### Unit/Component Validation

- Pattern matching: exempt, non-exempt, mixed, and malformed patterns classify
  correctly; malformed config fails at load.
- Fully-exempt delta yields a no-op session with no model invocation recorded.

### Integration/E2E Validation

- Scripted delta round over a docs-only change: session completes, usage records show
  no model calls, report lists the exempt paths.

### Failure/Invalid Path Validation

- Overly broad pattern (matches all paths) → config load refusal naming the pattern.

### Verification Commands

- `ace-test ace-review all`.

## Out of Scope

- Delta reference-head resolution (8wq.t.1qb.0).
- Deciding which specific paths a project should exempt.

## References

- cs3b/ace#335 §3 (exempt-path scopes proposal)
