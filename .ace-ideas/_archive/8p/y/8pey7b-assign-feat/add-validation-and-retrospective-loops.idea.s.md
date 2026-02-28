---
title: Enhanced Assignment Lifecycle with Verification and Retrospective Loops
filename_suggestion: feat-assign-validation-reflection-loops
enhanced_at: 2026-02-15 22:48:07.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2026-02-18 19:12:56.000000000 +00:00
id: 8pey7b
tags: []
created_at: '2026-02-15 22:48:07'
---

# Enhanced Assignment Lifecycle with Verification and Retrospective Loops

## Problem
Current assignments in `ace-assign` follow a linear execution path that lacks formal verification gates and structured learning cycles. Agents may mark tasks as complete without a functional demonstration, and valuable architectural insights gained during implementation are often lost because there is no mandatory reflection phase.

## Solution
Introduce two recursive loops into the `ace-assign` workflow to ensure quality and continuous improvement:

1. **The Validation Loop (Demo & Re-plan):** A mandatory execution phase where the agent must run a `demo` command (utilizing `ace-test-runner` or a custom script). If the demo fails, the tool triggers a 'Re-planning Molecule' that generates new sub-tasks or phases in the taskflow, preventing the assignment from closing until the demo passes.
2. **The Reflection Loop (Post-Mortem):** Once the validation loop is satisfied, the agent enters a 'Refactor Reflection' state. It must document what it would do differently (e.g., architectural changes, dependency choices) in the task's frontmatter or a `.ace-taskflow/retro/` entry before the assignment is officially finalized.

## Implementation Approach
- **Atoms:** `demo_status_checker`, `reflection_template_renderer`.
- **Molecules:** `validation_gate` (checks demo exit codes), `replan_orchestrator` (updates `.ace-taskflow` state).
- **Organisms:** `AssignmentLifecycleManager` to coordinate the transition between 'In Progress', 'Verifying', and 'Reflecting' states.
- **CLI Interface:** Add `--verify` and `--reflect` flags to `ace-assign` to trigger these specific states manually or via agent automation.

## Considerations
- Integration with `ace-taskflow` to ensure the state machine correctly reflects the 'Verifying' status.
- Ensuring the reflection loop doesn't become 'context bloat' by keeping the output concise and structured for future LLM retrieval.
- Compatibility with `wfi://` protocols for discovering demo instructions.

## Benefits
- Increases reliability of agent-produced code through forced E2E validation.
- Captures institutional knowledge and 'lessons learned' directly within the repository structure.
- Aligns with the ACE principle of 'Transparent & Inspectable' workflows.

---

## Original Idea

```
ace-assign - add two additional loops - 1) demo the solutions show me that it works, if not plan new pahases, where at the end you have to repeat those vslidation 2) when you pass the demo phase - now when you have build it what would you do differently
```