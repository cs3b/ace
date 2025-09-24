---
id: v.0.4.0+task.7
status: done
priority: medium
estimate: 4h
dependencies: [v.0.4.0+task.1]
---

# Add Draft Status Support to Existing Tools

## Objective

Enhance existing tools, particularly `create-path task-new`, to support the new "draft" status for tasks. This enables the creation of behavioral specifications
that are not yet ready for implementation, supporting the new specification cycle.

## What: Behavioral Specification

### User Experience

* **Command**: `create-path task-new --title "Task Title" --status "draft"`
* **Default**: Status remains "pending" for backward compatibility
* **Validation**: Accept "draft" as valid status value

### Expected Behavior

1.  create-path accepts --status parameter with "draft" value
2.  Generated task files have `status: draft` in metadata
3.  task-manager commands recognize and handle draft status
4.  No special filtering unless explicitly requested
5.  Backward compatibility maintained

### Tool Integration

* **create-path**: Generate tasks with draft status
* **task-manager**: List and manage draft tasks normally
* **nav-path**: Find tasks regardless of status
* **git-commit**: Handle draft tasks in commit messages

## How: Implementation Plan

### Planning Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Review current status handling in tools
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Identify all tools that read task status
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Plan backward compatibility approach
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Design status validation logic

### Execution Steps

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Update create-path to accept --status parameter
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Add "draft" to valid status values
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Update task generation to use provided status
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Verify task-manager handles draft status
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Test nav-path with draft status tasks
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Update tool documentation
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Add tests for draft status handling
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Ensure backward compatibility

## Scope of Work

### Deliverables

#### Modify

* .ace/tools/lib/coding\_agent\_tools/organisms/task\_creator.rb (if exists)
* .ace/tools/lib/coding\_agent\_tools/models/task.rb (add draft status)
* .ace/tools/spec/ (related test files)
* docs/tools.md (document --status parameter)

## Acceptance Criteria

* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />create-path accepts --status "draft"
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Draft tasks are created correctly
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Existing tools handle draft status
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Backward compatibility maintained
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Documentation updated
* {: .task-list-item} <input type="checkbox" class="task-list-item-checkbox" disabled="disabled" checked="checked" />Tests cover draft status

## Example

```bash
# Create a draft task to define behavior before implementation
create-path task-new --title "implement user authentication system" --status "draft"
```

1.  The command creates a new task file with draft status:
        # => Created: .ace/taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.8-implement-user-authentication-system.md

2.  The generated task file includes the draft status in metadata:
        ---
        id: v.0.4.0+task.8
        status: draft
        priority: medium
        estimate: TBD
        dependencies: []
        ---
    {: .language-yaml}

3.  Draft tasks appear in normal tool outputs:
        task-manager next
        # Shows both pending and draft tasks without special filtering

        nav-path task authentication
        # Finds the draft task file normally

        git-status
        # Includes draft tasks in repository status reporting
    {: .language-bash}

4.  The draft status enables specification before implementation:
    * Task contains behavioral requirements and acceptance criteria
    * Implementation details are developed when status changes to "pending"
    * Allows for review and refinement of specifications before coding begins

## Out of Scope

* ❌ Automatic status transitions
* ❌ Special draft task behaviors
* ❌ Status validation beyond valid values
* ❌ Migration of existing tasks

## References

* Current create-path implementation
* Task model structure
* Status field usage across tools
