---
id: v.0.9.0+task.296
status: done
priority: high
estimate: TBD
dependencies: []
needs_review: true
worktree:
  branch: 296-ace-sim-rebuild-from-task-285-postmortem-usage-first
  path: "../ace-task.296"
  created_at: '2026-02-27 14:44:31'
  updated_at: '2026-02-27 14:44:31'
  target_branch: main
---

# ace-sim rebuild from task-285 postmortem (usage-first)

## Overview

Replace the failed task-285 implementation path with a usage-first, proof-before-code
specification for a standalone `ace-sim` package.

This orchestrator delivered a three-phase sequence:

1. Prove runnable simulation behavior with workflows/prompts/examples only.
2. Build `ace-sim` package implementation from those proven contracts.
3. Finalize markdown-first artifact-chain runtime and close contract drift as unplanned completion work.

The objective is to prevent scaffold-only completion by requiring explicit happy-path
usage, runnable evidence, and review-gate checks before package implementation.

## Behavioral Specification

### User Experience
- **Input**: Maintainer runs the draft/review lifecycle for this orchestrator and its subtasks.
- **Process**: Subtask 296.01 defines and proves simulation behavior. Subtask 296.02 builds package code from that proof. Subtask 296.03 records and completes markdown-first runtime finalization.
- **Output**: Decision-complete specs with usage docs, evidence contracts, and review questions.

### Expected Behavior
- The orchestrator remains `draft` until both subtasks pass review readiness checks.
- The first subtask is mandatory proof-first scope and must not create package source code.
- The second subtask must not redefine behavior contracts; it implements proven phase-1 contracts.
- The public ace-sim CLI contract for package scope is `ace-sim run` (generic scenario runner).
- Every runnable claim in both subtasks includes `Verification Evidence`.
- The full task must remain executable from clean-base assumptions (no dependency on branch-only command implementations).
- If two consecutive proof attempts fail without improving verification evidence quality, stop and re-spec before coding.

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
- [ ] Phase-1 evidence explicitly proves `draft-output` is consumed by `plan` input (no independent runs)
- [ ] Stop-gate is enforced: two consecutive failed proof attempts trigger re-spec before coding
- [ ] Orchestrator and subtasks contain review questions with proposed defaults
- [ ] Scaffold-vs-runnable gaps are explicitly blocked by review checklist expectations

## Subtasks

- **01**: Phase 1: prove simulation workflows/prompts/examples without package code
- **02**: Phase 2: implement ace-sim package from proven phase-1 contracts
- **03**: Phase 3: markdown-first artifact chain finalization (unplanned)

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| Proof-before-code gating | 296.01 | — | KEPT |
| Task-local usage docs for runnable intent | 296.01 | — | KEPT |
| Generic `ace-sim run` CLI contract | 296.02 | — | KEPT |
| Markdown-first step artifact chain (`input.md -> user.bundle.md -> user.prompt.md -> output.md`) | 296.03 | — | KEPT |
| Multi-provider + repeat-run proof evidence | 296.01 | — | KEPT |
| Standalone `ace-sim` gem package | 296.02 | — | KEPT |

## Locked Decisions

### [HIGH] CLI compatibility path (resolved)
- Do not carry `ace-taskflow review-next-phase` as a v1 compatibility wrapper.
- Canonical interface is `ace-sim run`.

### [HIGH] Writeback default policy (resolved)
- Writeback is opt-in by default.

## Review Questions (Pending Human Input)

### [MEDIUM] Scenario expansion timing
- [ ] Should non-next-phase scenarios be included in v1 scope?
  - Proposed default: no; ship next-phase scenario only in v1 and keep generic runner interface ready.

## References

- `.ace-taskflow/v.0.9.0/retros/8pq3qi-task-285-postmortem-kill-implementation.md`
- `.ace-taskflow/v.0.9.0/retros/8pq3jr-task-285-usage-example-gap.md`
