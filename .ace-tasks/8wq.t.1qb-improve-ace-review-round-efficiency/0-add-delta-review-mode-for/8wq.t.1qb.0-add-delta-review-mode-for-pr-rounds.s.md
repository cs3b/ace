---
id: 8wq.t.1qb.0
status: done
priority: medium
created_at: "2026-09-27 01:09:50"
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [.ace-tasks/8wq.t.1qb-improve-ace-review-round-efficiency/8wq.t.1qb-improve-ace-review-round-efficiency-and-usage.s.md]
  commands: []
tags: [ace-review, review-rounds]
parent: 8wq.t.1qb
---

# Add delta review mode for PR rounds

## Behavioral Specification

### User Experience

- **Input**: The operator runs a PR review round and names a reference point — an
  earlier reviewed head (explicitly, or one recorded by a prior review session).
- **Process**: The round reviews only the diff between the reference head and the
  current head. Prior session findings for unchanged files are carried forward as
  evidence rather than re-derived by the model; findings already addressed upstream are
  not re-reported.
- **Output**: A normal review session/report whose scope states "delta since `<ref>`",
  listing only delta findings plus carried-forward context, so the operator can see the
  round was cheap and why.

### Expected Behavior

On PR cs3b/st-nervus-chat#171, rounds 3–10 reviewed nearly unchanged diffs at full cost
(~40 min of model time wasted). After this slice: a round invoked against an unchanged
delta completes against a near-empty diff with prior findings attached as evidence, and
the round still produces a verdict through the normal convergence rules.

### Interface Contract

```bash
# CLI interface (shape; exact flags confirmed at replan)
ace-review --pr <identifier> --delta <head>   # review changes since <head>, carrying forward prior session evidence
ace-review --pr <identifier> --delta          # reference head auto-resolved from the most recent prior session for this PR
```

- The resulting session records the reference head, so a later `--delta` without an
  argument chains from it.
- Error Handling:
  - No prior session exists and no explicit head was given → refuse with a clear
    message (never silently fall back to a full review).
  - Reference head is not an ancestor of the current head → refuse, explaining the
    divergence.
  - Delta diff is empty → the round completes as a no-op delta with carried-forward
    findings and a verdict, without requiring a full model pass.
- Edge Cases:
  - Force-push rewrites history between rounds → the ancestry check fails closed.
  - Prior session evidence unavailable/unreadable → the round states evidence was not
    carried forward instead of pretending it was.

### Success Criteria

- A delta round on an unchanged delta completes without reviewing unchanged files
  (observable in the session's subject/diff scope).
- Carried-forward findings appear in the round's evidence and report.
- Estimated saving demonstrated on a multi-round scenario: later rounds cost
  proportionally to the delta, not the whole PR.

### Validation Questions

- Should `--delta` compose with existing scoping flags (exempt paths, budgets), and
  what wins when both constrain the subject?
- When a delta round produces no new findings but prior Critical/High findings remain
  unresolved, does convergence treat the round as clean or as blocked?
- Is the auto-resolved reference head per-PR or per-branch, and how is it recorded?

## Vertical Slice

- Type: subtask of orchestrator 8wq.t.1qb (first slice — validates session
  carry-forward, the riskiest path).
- Size: medium.
- Outcome: an operator can run round N+1 scoped to the changes since round N at
  proportionally lower cost.

## Verification Plan

### Unit/Component Validation

- Delta resolution between two heads returns exactly the intermediate diff.
- Empty-delta rounds produce a carried-forward verdict without a model call.
- Missing prior session + no explicit head fails with the refusal message.

### Integration/E2E Validation

- A scripted two-round PR flow: full round, push one commit, `--delta` round — the
  second session's scope contains only the delta file(s) and the prior findings.

### Failure/Invalid Path Validation

- Non-ancestor reference head → clear refusal, no session created.
- Force-pushed PR → refusal citing rewritten history.

### Verification Commands

- `ace-test ace-review all` — package suite stays green.
- Manual/e2e scripted PR scenario as above.

## Out of Scope

- Exempt-path acceptance without model calls (subtask 8wq.t.1qb.1).
- Chunked review of genuinely oversized deltas (subtask 8wq.t.1qb.2).
- Verdict semantics changes.

## References

- cs3b/ace#335 §2 (delta rounds proposal, PR 171 cost data)
