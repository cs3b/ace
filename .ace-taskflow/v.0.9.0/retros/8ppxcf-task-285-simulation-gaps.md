# Retro: Task 285 Simulation Gaps and Fixes

**Date**: 2026-02-26
**Context**: Working tree fixes for task 285 to close gaps in next-phase simulation (spec completeness, runnable path proof, and early detection).
**Author**: Codex
**Type**: Conversation Analysis

## What Went Well

- The simulation scaffold was already modular (stage executor, synthesis, writeback), which made it possible to add runnable behavior without redesign.
- The worktree now includes CLI and command wiring changes plus tests, which improve runnable proof and guard regressions.
- Follow-up subtasks provided a clear containment for missing behavior (workflows, executor wiring, synthesis ordering).

## What Could Be Improved

- The spec did not explicitly require proof of runnable LLM simulation behavior, so scaffolding was mistaken as complete delivery.
- Success criteria in the orchestrator were left unchecked at completion, which allowed the task to be marked done despite missing behavior.
- Simulation workflows and default executor wiring were not mandated in the original scope, delaying detection of missing execution paths.

## Key Learnings

- A “framework complete” definition is insufficient for behavior-facing features; runnable proof must be part of done criteria.
- Simulation workflows, CLI wiring, and executor defaults must be treated as first-class deliverables, not optional follow-ons.
- Completion gating must assert that required checklist items are resolved before status transitions to `done`.

## Conversation Analysis (For conversation-based retros)

### Challenge Patterns Identified

#### High Impact Issues

- **Scaffold vs Runnable Gap**: The original delivery created structure but lacked executable LLM simulation.
  - Occurrences: 1 major incident in task 285
  - Impact: Required unplanned subtasks and rework; delayed usable behavior
  - Root Cause: Spec and success criteria did not demand proof of runnable execution

- **Unchecked Success Criteria**: Task marked `done` while success checklist items remained unresolved.
  - Occurrences: Multiple items in 285 orchestrator
  - Impact: False confidence in completion; missing behavior discovered later
  - Root Cause: No completion gate tied to checklist resolution

#### Medium Impact Issues

- **Workflow/CLI Coverage Gaps**: Simulation workflows and review-next-phase wiring were not mandated initially.
  - Occurrences: 1
  - Impact: Reduced ability to validate the end-to-end simulation chain via actual command paths

### Improvement Proposals

#### Process Improvements

- Require explicit runnable-path evidence (command + artifact output) before a behavior-facing task can be marked `done`.
- Treat workflow definitions, CLI command wiring, and default executor wiring as mandatory deliverables for simulation features.
- Enforce completion gates that block `done` when required success criteria are unchecked.

#### Tool Enhancements

- Add a simulation “smoke run” command to validate workflow + executor wiring with a minimal fixture.
- Add warnings when simulation stages are stubbed or produce empty outputs, with clear remediation steps.
- Extend `ace-task done` guardrails to require verification evidence for simulation claims.

#### Communication Protocols

- Always include a “proof of runnable behavior” section in task specs for simulation features.
- During review, ask explicitly: “What proves the simulation runs end-to-end?”

## Action Items

### Stop Doing

- Marking simulation features as complete based on structure alone.
- Treating unchecked success criteria as non-blocking for task completion.

### Continue Doing

- Using subtasks to isolate missing runnable behavior when gaps are discovered.
- Writing targeted tests for newly wired execution paths.

### Start Doing

- Add a standard simulation verification checklist (workflow presence, CLI command wiring, executor defaults, sample run evidence).
- Capture runnable proof artifacts in `.cache/ace-taskflow/simulations/<b36ts-id>/` and reference them in task completion notes.

## Technical Details

- Missing behavior initially: LLM-backed stage executor wiring and concrete simulation workflows for draft/plan.
- Current worktree changes span:
  - Workflows: `ace-taskflow/handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md`, `ace-taskflow/handbook/workflow-instructions/task/simulate-next-phase-plan.wf.md`
  - CLI wiring: `ace-taskflow/lib/ace/taskflow/cli.rb`, `ace-taskflow/lib/ace/taskflow/cli/commands/review_next_phase.rb`
  - Execution: `ace-taskflow/lib/ace/taskflow/molecules/next_phase_stage_executor.rb`, `ace-taskflow/lib/ace/taskflow/organisms/next_phase_simulation_runner.rb`
  - Writeback/synthesis: `ace-taskflow/lib/ace/taskflow/molecules/simulation_writeback_mixin.rb`, `ace-taskflow/lib/ace/taskflow/molecules/simulation_synthesis_builder.rb`
  - Tests: `ace-taskflow/test/commands/review_next_phase_command_test.rb`, `ace-taskflow/test/molecules/*_simulation_*_test.rb`
  - Config: `ace-taskflow/.ace-defaults/taskflow/config.yml`, `ace-taskflow/lib/ace/taskflow/configuration.rb`

## Additional Context

- Orchestrator: `.ace-taskflow/v.0.9.0/tasks/285-task-iterative-review/285-orchestrator.s.md`
- Related retros: `8pppak-task-285-next-phase-dry-runs.md`, `8pps6l-task-285-scope-gap-completeness-guardrails.md`
