---

title: Automated Task and Subtask Status Update based on Local Changes
filename_suggestion: feat-taskflow-review-update-tasks
enhanced_at: 2025-12-21 12:45:06
location: active
llm_model: gflash
source: "taskflow:v.0.9.0"
---


# Automated Task and Subtask Status Update based on Local Changes

## Problem
When developing complex features managed by `ace-taskflow`, local changes (especially within a Git worktree or before a PR) often implicitly complete or modify the scope of existing subtasks. Manually reviewing and updating the status of these subtasks in the task file (`.ace-taskflow/tasks/T-XXX.md`) is time-consuming and prone to human error, leading to stale task documentation.

## Solution
Implement a new workflow and corresponding CLI command, `ace-taskflow review-changes [TASK_ID]`, that uses LLM analysis to compare the current local code changes (diff) against the defined subtasks in the specified task ID. The workflow will generate a structured suggestion (e.g., a patch or YAML update) to automatically mark subtasks as completed, adjusted, or identify new required subtasks based on the code progress.

## Implementation Approach
1. **New CLI Command:** Add `review-changes` to `ace-taskflow/lib/ace/taskflow/commands/cli.rb` (Organism).
2. **Diff Generation:** Use `ace-git-commit` or dedicated Atoms/Molecules to generate a focused diff of local changes (e.g., comparing current branch to main/base).
3. **Context Loading:** Use `ace-context` to load the task definition (`T-XXX.md`) and its associated subtasks.
4. **LLM Orchestration:** Utilize `ace-llm` to send the task context and the generated diff to the model. The prompt (managed via `ace-prompt` and cached using the standard Prompt Caching Pattern) will instruct the LLM to analyze the diff and output a structured update plan (e.g., a list of subtask IDs and their proposed new status/description).
5. **Application:** A dedicated Molecule will parse the LLM's structured output and apply the changes to the task file, offering a confirmation step to the user or agent.
6. **Workflow Documentation:** Create a new self-contained workflow instruction file (`ace-taskflow/handbook/workflow-instructions/review-task-progress.wf.md`) following ADR-001.

## Considerations
- **Diff Scope:** Define clear parameters for the diff scope (e.g., `--staged`, `--worktree`, or comparing against a specific branch).
- **Deterministic Output:** Ensure the LLM is constrained to output a machine-readable format (like YAML or JSON) for reliable parsing and application of changes.
- **Configuration:** Allow configuration via the `ace-taskflow` config cascade to define LLM parameters (model, temperature) for this specific operation.

## Benefits
- Ensures task documentation (especially subtask status) remains accurate and synchronized with code development.
- Greatly improves efficiency for developers managing large tasks with many subtasks.
- Provides higher quality input for autonomous agents relying on `ace-taskflow` data for subsequent actions.

---

## Original Idea

```
ace-taskflow - add workflow to based on the pr / local changes - review task, take into acccount recent changes and update the subtasks (or any tasks) - usefull especial in the multisubtask tasks
```