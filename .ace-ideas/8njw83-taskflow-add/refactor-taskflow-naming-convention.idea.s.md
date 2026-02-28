---
title: Refactor ace-taskflow Primary Task File Naming Convention
filename_suggestion: refactor-taskflow-naming-convention
enhanced_at: 2025-12-20 21:29:33
location: archived
archived_reason: converted to task 271
task_ref: v.0.9.0+task.271
llm_model: gflash
---

# Refactor ace-taskflow Primary Task File Naming Convention

## Problem
The current file naming convention in `ace-taskflow` uses a redundant suffix (e.g., `.00`) to denote the primary task file or orchestrator subtask (e.g., `T123-feature-name.00.md`). This suffix is unnecessary when the task ID already uniquely identifies the main task, leading to verbose paths that complicate deterministic parsing and human readability.

## Solution
Refactor the task creation and resolution logic within the `ace-taskflow` gem to eliminate the `.00` suffix for the main task file. The primary task file should be simplified to `Tnnn-code-name.md`. This change applies only to the main task file; sequential subtasks (e.g., `.01`, `.02`) must retain their numbering to maintain workflow order.

## Implementation Approach
Implementation should focus on the `ace-taskflow` gem, specifically within the ATOM architecture:

1.  **Molecules/Organisms:** Modify the `TaskPathGenerator` (Molecule) and `TaskOrchestrator` (Organism) to construct paths without the `.00` suffix for the primary task.
2.  **CLI Commands:** Update `ace-taskflow start` and related commands to use the new convention immediately.
3.  **Migration:** Develop a small utility or integrate logic into the gem's initialization to automatically rename existing `*.00.md` files to `*.md` when the gem is updated, ensuring a smooth transition for ongoing projects.
4.  **Context Loading:** Verify that `ace-context` and `ace-nav` (if referencing task files via `wfi://` protocol) can correctly resolve the new, simplified paths.

## Considerations
- **Backward Compatibility:** A clear migration path is essential to avoid breaking existing task worktrees.
- **Subtask Distinction:** Ensure the logic clearly distinguishes between the main task file (no suffix) and numbered subtasks (e.g., `.01`, `.02`).
- **Agent Integration:** Update any embedded agents or workflows in `ace-taskflow/handbook/` that rely on the old naming convention.

## Benefits
- Cleaner, shorter file paths in the `.ace-taskflow/` directory.
- Improved readability for human developers.
- Simplified path resolution logic, making it easier for AI agents to deterministically identify the primary task file.

---

## Original Idea

```
ace-taskflow - lets get rid of .00 for orchestrator subtask just nnn-code-name
```