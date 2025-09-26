# Idea

---

title: Enhance ace-taskflow task done to move completed tasks to a 'done' subdirectory
filename_suggestion: feat-taskflow-move-done-tasks
enhanced_at: 2025-09-25 01:02:00
location: active
llm_model: gflash
---

## Problem

Currently, when a task is marked as `done` using `ace-taskflow task done <task-ref>`, its corresponding task folder remains within the active `.ace-taskflow/v.X.Y.Z/t/` directory. This clutters the `t/` directory, making it difficult for both human developers and AI agents to quickly identify and navigate only the *pending* tasks. While `ace-taskflow tasks --status pending` can filter, the file system itself doesn't reflect the task's completed status, which contradicts the spirit of clear organization and the `docs/blueprint.md` mention of `.ace-taskflow/done/**/*` as an ignored path for completed tasks.

## Solution

Enhance the `ace-taskflow task done <task-ref>` command to perform a file system move of the task's directory. In addition to updating the task's internal status to `done`, the command should move the entire task folder from its current location (e.g., `.ace-taskflow/v.0.9.0/t/<task-id>-<task-slug>`) to a `done/` subdirectory within the same versioned path (e.g., `.ace-taskflow/v.0.9.0/done/<task-id>-<task-slug>`). This ensures that the file system organization visually and practically distinguishes between active and completed tasks.

## Implementation Approach

This feature will primarily be implemented within the `ace-taskflow` gem.

1. **Modify `ace-taskflow` CLI**: The `task done` command's underlying `Organism` (e.g., `Ace::Taskflow::Organisms::TaskManager` or similar) will be updated to include the file system operation.
2. **Introduce a `Molecule`**: A new `Molecule` (e.g., `Ace::Taskflow::Molecules::TaskDirectoryMover`) should be created to encapsulate the logic for moving a task's directory. This molecule would take the current path and the target `done` path, ensuring robust file operations.
3. **Path Construction**: The `TaskDirectoryMover` will construct the destination path by replacing `t/` with `done/` within the versioned `.ace-taskflow/` structure, adhering to the `Configuration Cascade` principles.
4. **Error Handling**: Implement robust error handling for file system operations, potentially leveraging `Ace::Taskflow::ErrorReporter` for consistent CLI error feedback (ADR-009).
5. **Path Validation**: Ensure all file paths are validated using multi-layer validation as per ACE security principles.
6. **Update `ace-nav`**: `ace-nav`'s resource discovery mechanisms might need updates to correctly locate tasks, considering they could now reside in either `t/` or `done/` directories. This could involve modifying `ace-nav`'s `Organisms` or `Molecules` responsible for path resolution.

## Considerations

- **Backward Compatibility**: For existing tasks already marked as `done` but still residing in `t/`, consider a migration command or a graceful fallback mechanism in `ace-taskflow` and `ace-nav` to locate them.
- **Atomic Operations**: Ensure the task status update and the file system move are as atomic as possible to prevent inconsistent states if an operation fails.
- **CLI Output**: The `ace-taskflow task done` command should provide clear output indicating that the task folder has been moved.
- **`docs/blueprint.md`**: This change aligns with the `.ace-taskflow/done/**/*` entry in the `Ignored Paths` section, making the blueprint more accurate and actionable for agents.

## Benefits

- **Improved Readability**: The `t/` directory will exclusively contain *active* tasks, significantly improving clarity for humans and agents.
- **Clearer Task State**: The file system organization will directly reflect the task's status, providing an immediate visual cue.
- **Enhanced AI Navigation**: AI agents can more efficiently focus on pending tasks by listing contents of `t/` and effectively ignoring `done/` tasks as per `docs/blueprint.md`.
- **Consistency**: Aligns the physical file structure with the logical task status and project documentation.
- **Better Organization**: Provides a cleaner and more organized historical record of completed work within the project's task management system.

---

## Original Idea

```
currently completed tasks stay in t/ folder - this doesn' help when browsing the folder - we should improve the `ace-taskflow task done <task-ref>` to move task folder to done -> e.g.: .ace-taskflow/v.0.9.0/t/done/ - additional to marking task status as done
```

---
Captured: 2025-09-25 01:01:44

