# Idea

---
title: Integrate ace-git-commit with ace-taskflow for Task-Aware Commits
filename_suggestion: feat-git-commit-taskflow
enhanced_at: 2025-10-02 00:25:32
location: active
llm_model: gflash
---

## Problem
Currently, `ace-git-commit` generates commit messages based solely on the staged or unstaged changes, and an optional user prompt. It lacks direct integration with `ace-taskflow`, which manages project tasks. This means developers (and AI agents) must manually reference task IDs or context within their commit messages, leading to potential inconsistencies and a weaker link between code changes and project tasks. There is no automated way to leverage task details (like title, type, or description) to inform the LLM when generating a commit message, reducing the accuracy and relevance of generated commits for specific tasks.

## Solution
Enhance `ace-git-commit` to integrate directly with `ace-taskflow`, allowing it to generate commit messages that are aware of and contextualized by a specified task. This will involve introducing a new CLI option to `ace-git-commit` (e.g., `--task <task_id>`) that, when provided, instructs the tool to fetch relevant details from the `ace-taskflow` task and incorporate them into the LLM prompt for commit message generation.

## Implementation Approach
1.  **CLI Extension**: Modify the `exe/ace-git-commit` script to accept a new `--task <task_id>` option. This option will parse the task identifier (e.g., `060`, `v.0.9.0+060`).
2.  **Task Data Retrieval**: Within `ace-git-commit`, introduce new logic (likely within a `Molecules` or `Organisms` layer) to interact with `ace-taskflow`. This could involve:
    *   Directly requiring `ace-taskflow` as a dependency in `ace-git-commit`'s gemspec and using `ace-taskflow`'s internal APIs (e.g., `Ace::Taskflow::Organisms::TaskLoader.load_task(task_id)`).
    *   Alternatively, executing `ace-taskflow task <task_id> --json` as a subprocess to get structured task data, though direct dependency is preferred for performance and robustness.
3.  **LLM Prompt Enhancement**: The `Ace::GitCommit::Organisms::CommitGenerator` will receive the task details (e.g., task title, type like 'feat' or 'fix', a brief summary) and incorporate this information into the prompt sent to `ace-llm`. For example, the prompt could include: "The changes are part of task '[Task ID]: [Task Title]', which is a [Task Type] type of task. Consider this context when generating the commit message."
4.  **Error Handling**: Implement robust error handling for cases where the specified task ID is invalid or the task cannot be found, utilizing `Ace::Core::ErrorReporter` for consistent CLI error feedback.

## Considerations
-   **Dependency Management**: `ace-git-commit` will need `ace-taskflow` as a runtime dependency in its `.gemspec`.
-   **Configuration**: How to handle default task IDs (e.g., if a task is 'active' in `ace-taskflow`) or project-specific task ID formats.
-   **CLI Interface**: Ensure the `--task` option is intuitive and works seamlessly with existing options like `--staged`.
-   **Atomicity**: The new logic for fetching task data should be encapsulated, potentially as a new `Ace::GitCommit::Molecules::TaskContextLoader`.

## Benefits
-   **Improved Traceability**: Automatically links generated commits directly to `ace-taskflow` tasks, creating a clear audit trail.
-   **Enhanced AI Agent Workflow**: AI agents can be instructed to use the `--task` flag, ensuring their commits are perfectly aligned with the task they are working on, making their contributions more structured and understandable.
-   **Increased Efficiency**: Reduces manual effort for developers and agents to craft task-specific commit messages.
-   **Consistency**: Promotes a standardized approach to linking commits with tasks across the project, improving overall version control hygiene.
-   **Richer Commit Messages**: Leverages task context to generate more informative and relevant commit messages via `ace-llm`.

---

## Original Idea

```
⏺ Read(ace-git-commit/handbook/workflow-instructions/commit.wf.md)
  ⎿  Read 66 lines (ctrl+o to expand)

⏺ Now let me read the task file:

⏺ Bash(ace-taskflow task v.0.9.0+task.060 --path)
  ⎿  Error: Task 'v.0.9.0+task.060' not found.
     Valid formats: 018, task.018, v.0.9.0+018, backlog+025

⏺ Let me try with the correct format:

⏺ Bash(ace-taskflow task 060 --path)
  ⎿  .ace-taskflow/v.0.9.0/t/060-implement-sequential-group-execution-ace/task.060.md
```

---
Captured: 2025-10-02 00:25:15