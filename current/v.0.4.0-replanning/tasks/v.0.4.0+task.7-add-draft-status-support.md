---
id: v.0.4.0+task.7
status: draft
priority: medium
estimate: 4h
dependencies: [v.0.4.0+task.1]
---

# Add Draft Status Support to Existing Tools

## Objective

Enhance existing tools, particularly `create-path task-new`, to support the new "draft" status for tasks. This enables the creation of behavioral specifications that are not yet ready for implementation, supporting the new specification cycle.

## What: Behavioral Specification

### User Experience
- **Command**: `create-path task-new --title "Task Title" --status "draft"`
- **Default**: Status remains "pending" for backward compatibility
- **Validation**: Accept "draft" as valid status value

### Expected Behavior
1. create-path accepts --status parameter with "draft" value
2. Generated task files have `status: draft` in metadata
3. task-manager commands recognize and handle draft status
4. No special filtering unless explicitly requested
5. Backward compatibility maintained

### Tool Integration
- **create-path**: Generate tasks with draft status
- **task-manager**: List and manage draft tasks normally
- **nav-path**: Find tasks regardless of status
- **git-commit**: Handle draft tasks in commit messages

## How: Implementation Plan

### Planning Steps
* [ ] Review current status handling in tools
* [ ] Identify all tools that read task status
* [ ] Plan backward compatibility approach
* [ ] Design status validation logic

### Execution Steps
- [ ] Update create-path to accept --status parameter
- [ ] Add "draft" to valid status values
- [ ] Update task generation to use provided status
- [ ] Verify task-manager handles draft status
- [ ] Test nav-path with draft status tasks
- [ ] Update tool documentation
- [ ] Add tests for draft status handling
- [ ] Ensure backward compatibility

## Scope of Work

### Deliverables

#### Modify
- dev-tools/lib/coding_agent_tools/organisms/task_creator.rb (if exists)
- dev-tools/lib/coding_agent_tools/models/task.rb (add draft status)
- dev-tools/spec/ (related test files)
- docs/tools.md (document --status parameter)

## Acceptance Criteria

- [ ] create-path accepts --status "draft"
- [ ] Draft tasks are created correctly
- [ ] Existing tools handle draft status
- [ ] Backward compatibility maintained
- [ ] Documentation updated
- [ ] Tests cover draft status

## Out of Scope

- ❌ Automatic status transitions
- ❌ Special draft task behaviors
- ❌ Status validation beyond valid values
- ❌ Migration of existing tasks

## References

- Current create-path implementation
- Task model structure
- Status field usage across tools