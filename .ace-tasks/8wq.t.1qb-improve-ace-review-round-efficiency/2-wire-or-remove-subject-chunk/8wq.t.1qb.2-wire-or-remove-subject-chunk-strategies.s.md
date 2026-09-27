---
id: 8wq.t.1qb.2
status: draft
priority: medium
created_at: "2026-09-27 01:09:58"
estimate: TBD
dependencies: []
bundle:
  presets: ["project"]
  files: [".ace-tasks/8wq.t.1qb-improve-ace-review-round-efficiency/8wq.t.1qb-improve-ace-review-round-efficiency-and-usage.s.md", "ace-review/lib/ace/review/molecules/subject_strategy.rb", "ace-review/.ace-defaults/review/config.yml"]
  commands: []
tags: [ace-review, diff-subject]
parent: 8wq.t.1qb
---

# Wire or remove subject chunk strategies

## Behavioral Specification

### User Experience

Today the documented subject-strategy configuration (adaptive/chunked, including
`max_tokens_per_chunk`) has no effect: the strategy factory exists but is never invoked
by the review pipeline, and an oversized diff hard-fails the input budget — a 40-file
PR cannot be reviewed in one packet (issue §4). After this slice, the operator
experience is honest in one of two directions:

- **Wire**: A PR whose diff exceeds the input budget is automatically split into
  budget-sized packets (adaptive by default; chunked/full selectable via the already
  documented configuration), each packet gets a model pass, and the packets' findings
  are merged into one session report with no duplicated findings across packets.
- **Remove**: Oversized diffs fail with a clear, documented refusal stating the budget
  and the actual size, and all undocumented/dead strategy code and configuration is
  gone (pre-1.0, no shims — ADR-024).

### Expected Behavior

The observable contract is: whatever the review configuration documents about subject
strategy is true of the running system; nothing about chunking is documented without
working. The decision between wire and remove is made at replan with the cost of
findings-merge quality weighed against losing large-PR review capability, then
implemented as one vertical slice.

### Interface Contract

```bash
# If WIRED — configuration becomes real (documented block in .ace-defaults/review/config.yml):
# subject_strategy:
#   type: adaptive            # full | chunked | adaptive
#   chunking:
#     max_tokens_per_chunk: 100000

ace-review --pr <identifier>
#   oversized diff => N packet rounds + one merged report; report states packet count and boundaries

# If REMOVED — strategy code, factory, and the config.yml block are deleted:
ace-review --pr <identifier>
#   oversized diff => refusal naming the budget limit and the actual subject size
```

- Error Handling (both outcomes):
  - Oversized diff under `full` strategy (wired variant) → explicit refusal, same
    message quality as the remove variant.
  - Strategy configuration invalid/unknown type → config load failure naming the key.
- Edge Cases:
  - A diff exactly at the budget boundary → one packet, no split.
  - Findings near packet boundaries reference context from a neighboring packet →
    merged report deduplicates and preserves file/line anchors.

### Success Criteria

- No documented-but-unreachable subject-strategy configuration remains (the current
  `config.yml` block either works end-to-end or is deleted).
- Large-PR behavior is deterministic and stated in the report (packets used, or the
  precise refusal).
- Suite stays green with the dead strategies either exercised or removed.

### Validation Questions

- Wire vs remove: does any current user review 40+-file PRs in one packet today, or is
  delta-scoping (8wq.t.1qb.0) the intended answer for large PRs — making removal the
  simpler honest state?
- If wired: how are per-file context (goal briefs, prior findings) distributed across
  packets without exceeding budgets?

## Vertical Slice

- Type: subtask of orchestrator 8wq.t.1qb; independent of .0/.1/.3.
- Size: medium.
- Outcome: documented subject-strategy behavior and system behavior are identical.

## Verification Plan

### Unit/Component Validation

- Strategy selection and (if wired) packet boundaries respect the token budget.
- (If removed) no production code path references the deleted strategies; config keys
  are gone from defaults.

### Integration/E2E Validation

- A synthetic oversized-diff subject runs end-to-end: wired → merged report with
  packet metadata; removed → the documented refusal.

### Failure/Invalid Path Validation

- Unknown strategy type in config → load failure naming the key (both variants).

### Verification Commands

- `ace-test ace-review all`.

## Out of Scope

- Delta scoping and exempt-path acceptance (8wq.t.1qb.0 / .1).
- Raising or lowering the input budget itself.

## References

- cs3b/ace#335 §4 (chunking dead-code observation)
- ace-review subject strategy surface: `SubjectStrategy.for` (currently invoked only
  by tests), strategies under `ace-review/lib/ace/review/molecules/strategies/`
