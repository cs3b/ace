---
id: v.0.9.0+task.285
status: done
priority: medium
estimate: TBD
dependencies: []
worktree:
  branch: 285-iterative-review-with-next-phase-dry-runs
  path: "../ace-task.285"
  created_at: '2026-02-26 15:44:11'
  updated_at: '2026-02-26 15:44:11'
  target_branch: main
---

# Iterative Review with Next-Phase Dry Runs

## Overview

Add an iterative review layer to the idea -> task -> plan pipeline using next-phase simulation.
The workflow should run dry-run style simulations of downstream phases, extract missing context
and decision gaps, then write final questions/refinements back to the artifact being reviewed.

### Pipeline Focus

- Idea review path: `idea -> simulate draft -> simulate plan`
- Task review path: `task -> simulate plan`
- Work-on simulation is explicitly deferred to a separate extension subtask

### Behavior Rules

- Simulation does not create or mutate downstream task/plan artifacts
- All intermediate artifacts are written to `.cache/ace-taskflow/simulations/<b36ts-id>/`
- Final synthesized questions/refinements are written back to the reviewed artifact (`idea` or `task`)

### Packages Affected

- `ace-taskflow`:
  - idea and task workflow orchestration
  - simulation execution and synthesis pipeline
  - configuration cascade and CLI override behavior
  - write-back behavior for reviewed artifacts
- `ace-b36ts`:
  - run/session identifier generation (`<b36ts-id>`)
- `ace-bundle` / workflow instructions:
  - protocol-driven review simulation entrypoints via `wfi://...`

## Subtasks

- **01**: Simulation Session Framework + Cache Contract (b36ts)
- **02**: Idea-State Next-Phase Simulation (Draft + Plan) and Write-Back
- **03**: Task-State Plan Simulation + Auto/Manual Trigger Controls
- **04**: Work-On Simulation Extension Subtask

### Concept Inventory

| Concept | Introduced by | Removed by | Status |
|---------|--------------|------------|--------|
| Next-phase simulation run model | 285.01 | — | NEW |
| Session artifact cache at `.cache/ace-taskflow/simulations/<b36ts-id>/` | 285.01 | — | NEW |
| Stage-by-stage simulation outputs (`draft`, `plan`) | 285.01 | — | NEW |
| Idea-path simulation chain (`idea -> draft -> plan`) | 285.02 | — | NEW |
| Task-path simulation chain (`task -> plan`) | 285.03 | — | NEW |
| Write-back contract: final questions only to source artifact | 285.02/285.03 | — | NEW |
| Auto-trigger defaults enabled for idea and task reviews | 285.03 | — | NEW |
| Optional future work-on simulation mode | 285.04 | — | NEW |

## Success Criteria

- [ ] Orchestrator and subtask specs fully define the simulation contract without implementation ambiguity
- [ ] Cache contract and write-back rules are explicit and consistent across subtasks
- [ ] Idea and task review flows define deterministic stage order and outputs
- [ ] Work-on simulation remains isolated as extension scope
- [ ] Spec is ready for review-task gating (draft -> pending)

## References

- `.ace-taskflow/v.0.9.0/ideas/_maybe/_archive/8poz4f-taskflow-add/idea.idea.s.md`
- `.ace-taskflow/v.0.9.0/ideas/_maybe/_archive/8pp43s-taskflow-add/idea.idea.s.md`