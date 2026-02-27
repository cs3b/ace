---
id: v.0.9.0+task.296
status: draft
priority: high
estimate: TBD
dependencies: []
needs_review: true
---

# ace-sim rebuild from task-285 postmortem (usage-first)

## Overview

Replace the failed task-285 implementation path with a usage-first, proof-before-code
specification for a standalone `ace-sim` package.

This orchestrator enforces a two-phase sequence:

1. Prove runnable simulation behavior with workflows/prompts/examples only.
2. Build `ace-sim` package implementation from those proven contracts.

The objective is to prevent scaffold-only completion by requiring explicit happy-path
usage, runnable evidence, and review-gate checks before package implementation.

## Behavioral Specification

### User Experience
- **Input**: Maintainer runs the draft/review lifecycle for this orchestrator and its subtasks.
- **Process**: Subtask 296.01 defines and proves simulation behavior. Subtask 296.02 builds package code from that proof.
- **Output**: Decision-complete specs with usage docs, evidence contracts, and review questions.

### Expected Behavior
- The orchestrator remains `draft` until both subtasks pass review readiness checks.
- The first subtask is mandatory proof-first scope and must not create package source code.
- The second subtask must not redefine behavior contracts; it implements proven phase-1 contracts.
- The public ace-sim CLI contract for package scope is `ace-sim run` (generic scenario runner).
- Every runnable claim in both subtasks includes `Verification Evidence`.

### Interface Contract

```bash
# Review workflow actions on this orchestrator lineage
mise exec -- ace-task show 296
mise exec -- ace-task show 296.01
mise exec -- ace-task show 296.02
```

### Success Criteria
- [ ] Two-subtask sequence is explicit and dependency-ordered (`296.01` -> `296.02`)
- [ ] Phase-1 spec includes a concrete happy-path usage document path and evidence contract
- [ ] Phase-2 spec includes a concrete package usage document path and evidence contract
- [ ] Orchestrator and subtasks contain review questions with proposed defaults
- [ ] Scaffold-vs-runnable gaps are explicitly blocked by review checklist expectations

## Subtasks

- **01**: Phase 1: prove simulation workflows/prompts/examples without package code
- **02**: Phase 2: implement ace-sim package from proven phase-1 contracts

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| Proof-before-code gating | 296.01 | — | KEPT |
| Task-local usage docs for runnable intent | 296.01 | — | KEPT |
| Generic `ace-sim run` CLI contract | 296.02 | — | KEPT |
| Multi-provider + repeat-run simulation matrix | 296.01 | — | KEPT |
| Standalone `ace-sim` gem package | 296.02 | — | KEPT |

## Review Questions (Pending Human Input)

### [HIGH] CLI compatibility path
- [ ] Should `ace-taskflow review-next-phase` be supported as a compatibility wrapper in v1 of `ace-sim`?
  - Proposed default: no wrapper in v1; provide migration notes and focus on `ace-sim run`.

### [HIGH] Writeback default policy
- [ ] Should writeback be disabled by default for v1 simulations?
  - Proposed default: yes, writeback opt-in via explicit flag.

### [MEDIUM] Scenario expansion timing
- [ ] Should non-next-phase scenarios be included in v1 scope?
  - Proposed default: no; ship next-phase scenario only in v1 and keep generic runner interface ready.

## References

- `.ace-taskflow/v.0.9.0/retros/8pq3qi-task-285-postmortem-kill-implementation.md`
- `.ace-taskflow/v.0.9.0/retros/8pq3jr-task-285-usage-example-gap.md`
- `.ace-taskflow/v.0.9.0/tasks/295-task-sim-extract/295-ace-sim-gem-285-worktr.s.md`
