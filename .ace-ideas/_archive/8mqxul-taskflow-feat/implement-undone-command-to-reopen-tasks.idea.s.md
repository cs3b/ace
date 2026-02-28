---
title: Implement ace-taskflow undone command to reopen tasks
filename_suggestion: feat-taskflow-task-reopen
enhanced_at: 2025-11-27 22:34:08.000000000 +00:00
location: active
llm_model: gflash
status: done
completed_at: 2025-12-09 00:19:36.000000000 +00:00
id: 8mqxul
tags: []
created_at: '2025-11-27 22:33:58'
---

# Implement ace-taskflow undone command to reopen tasks

## Problem
Currently, tasks moved to the `.ace-taskflow/done` directory are considered permanently closed within the ACE project's task management system (`ace-taskflow`). There is no direct, standardized CLI command to easily revert a completed task back to an active state, such as moving it back to the current release folder and updating its status to "in-progress" or "open". This limitation hinders agile development practices where tasks might need to be reopened due to new information, incomplete work, or shifting priorities, requiring manual file system operations and metadata editing.

## Solution
Introduce a new `ace-taskflow undone <task_identifier>` command. This command will locate a specified task within the `.ace-taskflow/done` directory, move its corresponding markdown file back to the active `.ace-taskflow/vX.Y/release` folder, and automatically update its frontmatter `status` field to `in-progress` (or a configurable default active status). The command should also update the `last-updated` timestamp in the task's frontmatter.

## Implementation Approach
The implementation will reside within the `ace-taskflow` gem, adhering to the ATOM architecture pattern.
*   **CLI Command**: A new `undone` command will be added to `lib/ace/taskflow/commands/cli.rb` using Thor.
*   **Organism**: A new organism, e.g., `Ace::Taskflow::Organisms::TaskReopener`, will orchestrate the process. It will handle task identification, file movement, and metadata updates.
*   **Molecules**: 
    *   A molecule like `Ace::Taskflow::Molecules::TaskFinder` (or an existing one) will be used to locate the task file in the `done` directory.
    *   A molecule for file system operations, e.g., `Ace::Taskflow::Molecules::FileManager`, will handle moving the task file.
    *   `Ace::Core::Molecules::FrontmatterManager` (or a similar component in `ace-taskflow`) will be used to read, modify, and write the task's frontmatter (updating `status` and `last-updated`).
*   **Atoms**: Pure functions for path manipulation, YAML parsing/serialization, and string operations will be utilized.
*   **Configuration**: The paths to the `done` directory and the current `release` directory will be retrieved via `ace-core`'s configuration cascade, ensuring flexibility and project-specific overrides.

## Considerations
-   **Task Identification**: The `task_identifier` could be the task ID (e.g., `T-123`), a partial title, or a filename. Fuzzy matching could be considered for user convenience.
-   **Target Release Folder**: The command should intelligently determine the current active release folder (e.g., `.ace-taskflow/vX.Y/release`).
-   **Status Management**: Allow for a configurable default "reopened" status (e.g., `in-progress`, `open`, `backlog`).
-   **Error Handling**: Gracefully handle cases where the task is not found, or if a task with the same ID already exists in the target release folder.
-   **Deterministic Output**: Ensure the CLI output is consistent and machine-readable for AI agents.
-   **Integration**: Consider how this interacts with `ace-nav` for task discovery and `ace-git-commit` if changes need to be committed.

## Benefits
-   **Enhanced Task Lifecycle Management**: Provides a crucial missing piece for managing tasks, allowing for more dynamic and flexible workflows within ACE.
-   **Improved AI Agent Capabilities**: AI agents can programmatically reopen tasks, enabling more sophisticated autonomous task management and re-prioritization.
-   **Reduced Manual Overhead**: Eliminates the need for manual file manipulation and frontmatter editing when a task needs to be reactivated.
-   **Consistency**: Standardizes the process of reopening tasks across the ACE ecosystem.
-   **Agility**: Supports more agile development practices by making it easier to adapt to changing project requirements.

---

## Original Idea

```
ace-taskflow task undone - to reopen main task (bring back to the release folder and set the status in-progress
```