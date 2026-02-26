# Reflection: Task 285 Scope Gap - Completeness Guardrails

**Date**: 2026-02-26
**Context**: Follow-up analysis of task 285 after discovering that the first delivered version implemented only the simulation scaffold and not the runnable LLM stage simulation path.
**Author**: Codex
**Type**: Conversation Analysis

## What Went Well

- The gap was detected quickly during real usage ("where are the workflows / where is LLM simulation?").
- Existing architecture had a clean extension point (`stage_executor`), so adding missing pieces did not require redesign.
- Follow-up subtasks (285.05-285.07) closed the functional gap with focused scope (workflows, executor integration, synthesis ordering).

## What Could Be Improved

- Task 285 was marked `done` while executable completeness was still missing in practice.
- Completion decisions relied on scaffolding and code structure, not hard proof of runnable behavior.
- Success criteria and validation questions stayed unchecked while statuses advanced to `done`.

## Key Learnings

- "Framework complete" is not equivalent to "feature complete" for behavior-facing tasks.
- Completion gates must require execution evidence, not only implementation artifacts.
- Review gates must explicitly detect scaffold-vs-runnable divergence.

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Scaffold mistaken for complete solution**: Core LLM simulation behavior was absent while pipeline/plumbing existed.
  - Occurrences: 1 major incident in task 285.
  - Impact: Required reopening task lineage and adding 3 unplanned subtasks (285.05-285.07).
  - Root Cause: Definition of done did not enforce runnable-path proof.

- **Status drift vs unresolved checklist items**: Tasks/orchestrator reached `done` with unchecked success criteria.
  - Occurrences: Multiple 285 files.
  - Impact: False confidence and delayed detection of material scope gap.
  - Root Cause: No completion validator tied to required checklist sections.

#### Medium Impact Issues

- **Retro coverage mismatch**: Initial retro (`8pppak`) documented process mechanics but not feature-completeness miss.
  - Occurrences: 1.
  - Impact: Key lesson not captured until additional review.

- **Provider-dependent demo fragility**: Live execution can fail due to provider availability, making "works now" hard to prove deterministically.
  - Occurrences: observed in follow-up verification attempt.
  - Impact: Adds noise to completion decisions unless evidence contract is explicit.

### Improvement Proposals

#### Process Improvements

- Require explicit completion evidence for behavior claims (command + artifact proof).
- Keep orchestrator status non-done while any child success criteria required for feature viability are unresolved.
- Add a final "completeness check" pass before marking task/orchestrator done.

#### Tool Enhancements

- Add `ace-task done` guard for unresolved required checklist items, with explicit override.
- Add review checklist checks for runnable-path proof when task claims executable behavior.
- Add task template guidance for `Verification Evidence` section in execution-oriented tasks.

#### Communication Protocols

- During drafting/review, explicitly ask: "What proves this works end-to-end?"
- During completion, require short proof summary with artifact path references.

### Token Limit & Truncation Issues

- **Large Output Instances**: Not a primary factor for this incident.
- **Truncation Impact**: None on root cause.
- **Mitigation Applied**: N/A.
- **Prevention Strategy**: Keep retro evidence scoped to concrete task/spec/code artifacts.

## Action Items

### Stop Doing

- Marking behavior-facing tasks as done based on structure/plumbing alone.
- Treating unchecked success criteria as non-blocking for final completion.

### Continue Doing

- Using subtasks to isolate missing concerns once a gap is found.
- Capturing incidents in retros with actionable follow-up tasks.

### Start Doing

- Implement task 285.08: completion gate validation for unresolved required checklist items.
- Implement task 285.09: verification evidence contract for simulation claims.
- Implement task 285.10: review-gate hardening for scaffold-vs-runnable detection.

## Technical Details

- Original scaffold path had session store, synthesis, writeback preview, and trigger policy.
- Missing behavior initially: concrete simulation workflows + default LLM executor wiring + synthesis ordering for question prioritization.
- Follow-up implementation now exists in:
  - `ace-taskflow/handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md`
  - `ace-taskflow/handbook/workflow-instructions/task/simulate-next-phase-plan.wf.md`
  - `ace-taskflow/lib/ace/taskflow/molecules/next_phase_stage_executor.rb`
  - `ace-taskflow/lib/ace/taskflow/molecules/simulation_synthesis_builder.rb`

## Additional Context

- Existing task-285 retro: `.ace-taskflow/v.0.9.0/retros/8pppak-task-285-next-phase-dry-runs.md`
- Follow-up subtasks: `v.0.9.0+task.285.08`, `285.09`, `285.10`
