---
id: 8xb.t.k3v.3
status: draft
priority: medium
created_at: "2026-10-12 13:24:28"
estimate: L
dependencies: ["8xb.t.k3v.0", "8xb.t.k3v.1", "8xb.t.k3v.2"]
tags: []
parent: 8xb.t.k3v
bundle:
  presets: ["project"]
  files:
    - ".ace-tasks/8xb.t.k3v-measured-harness-evolution-for-ace/research-harness-learning-paper-and-gap-map.md"
  commands: []
---

# Add comparative workflow validation to sim

## Behavioral Specification

### User Experience

- Input: two harness variants (e.g., current `*.wf.md` workflow vs a proposed revision) and a fixed task set.
- Process: `ace-sim run` executes the same task set against both variants and produces one comparative report.
- Output: a side-by-side comparison (outcome, failure points, cost/timing) with an explicit recommendation: adopt, reject, or inconclusive. The human decides; promotion then follows the ADR-034/ADR-022 cascade path.

### Expected Behavior

- Comparison runs both variants over an identical, fresh task set (fresh tasks, not the tasks that motivated the revision — per ADR-034).
- The report aggregates execution feedback records (8xb.t.k3v.1) from both runs; no new metrics source is invented.
- Recommendation logic: adopt only on measurable improvement; tie or regression → reject; noisy/small sample → inconclusive.
- Mechanism is manually initiated (tool-assisted comparative validation), not an autonomous rewrite loop — per the paper's finding that single revisions are reliable while unbounded revision sequences are not.

### Interface Contract

```bash
# Behavioral surface (exact flags decided at replan; mirrors provider comparison):
ace-sim run --compare-old <path-or-ref> --compare-new <path-or-ref> --tasks <task-set>
# Expected output: comparative report file path + summary line (adopt/reject/inconclusive)
```

Error Handling:

- Variant missing/unreadable → actionable error before any run starts (fail fast, no partial comparison).
- One variant crashes on all tasks → report still produced; crash treated as worst outcome for that variant.

Edge Cases:

- Task set too small for a meaningful comparison → report marked inconclusive with sample-size note.
- Identical variants supplied → report detects and short-circuits.

## Success Criteria

- A real workflow revision can be compared against its baseline end to end, producing one comparative report with recommendation.
- The report's data comes from execution feedback records (traceable), not ad-hoc parsing.
- A tie/regression demonstrably results in a reject recommendation.

## Verification Plan

- Unit/component: recommendation logic (improve/tie/regression/inconclusive), fail-fast validation.
- Integration: compare two real variants of a workflow over a small fixed task set.
- Failure path: invalid variant path; one-sided total failure.

## Validation Questions

- Fresh-task source for comparisons: `ace-e2e` scenarios, sim scenario library, or dedicated task sets?
- Recommendation thresholds: absolute improvement vs statistical noise handling (v1: simple, explicit defaults).
