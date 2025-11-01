---
id: v.0.9.0+task.097
status: draft
priority: medium
estimate: 4h
dependencies: []
---

# Make ace-taskflow task transitions more flexible and idempotent

## Behavioral Specification

### User Experience
- **Input**: Users run task transition commands like `ace-taskflow task done 058` or `ace-taskflow task update 058 --status done`
- **Process**: Users experience smooth transitions without rigid validation errors, receiving informative messages when operations are already satisfied
- **Output**: Tasks successfully transition to desired states, with clear feedback about what happened (transitioned, already in state, or moved)

### Expected Behavior
The ace-taskflow task transition system should be flexible and forgiving, allowing users to:
- Transition tasks from any status directly to "done" without requiring intermediate steps
- Mark tasks as done multiple times without errors (idempotent operations)
- Use custom statuses like "ready-for-review" that aren't in the predefined list
- Receive informative messages instead of errors when desired state is already achieved

When a user attempts to transition a task that's already in the desired state or location, the system should succeed with an informative message rather than failing with an error. This makes automation and scripting more reliable.

### Interface Contract
```bash
# CLI Interface
ace-taskflow task done <task-reference>
# Success: Task marked as done (even if already done)
# Output: "Task 058 marked as done" or "Task 058 is already done"
# Exit code: 0 (success)

ace-taskflow task update <task-reference> --status <status>
# Success: Task status updated (supports custom statuses)
# Output: "Task status updated to ready-for-review"
# Exit code: 0 (success)

# Configuration Interface (optional)
# .ace/taskflow/config.yml
strict_transitions: false  # Default: flexible transitions
# or via CLI flag
ace-taskflow task done 058 --strict  # Use rigid validation
```

**Error Handling:**
- [Invalid task reference]: "Task not found: 058"
- [File system error]: "Unable to move task: permission denied"

**Edge Cases:**
- [Already done]: Success with message "Task 058 is already done"
- [Already in done/ folder]: Success with message "Task 058 already in done/"
- [Custom status to done]: Success, transitions from any status
- [Same status transition]: Success with message "Task already has status: done"

### Success Criteria
- [ ] **Flexible Transitions**: Tasks can transition from any status (including custom) directly to "done"
- [ ] **Idempotent Operations**: Running `task done` multiple times succeeds without errors
- [ ] **Custom Status Support**: Tasks can have and transition from custom statuses like "ready-for-review"
- [ ] **Informative Messages**: Operations that are already satisfied return success with clear messages
- [ ] **Backward Compatibility**: Optional strict mode available for users who prefer rigid validation

### Validation Questions
- [ ] **Configuration Preference**: Should flexible transitions be the default, or should it be opt-in via configuration?
- [ ] **Strict Mode Interface**: Should strict validation be available via CLI flag (--strict) or only via config?
- [ ] **Message Verbosity**: Should info messages be shown by default or only with --verbose?
- [ ] **Custom Status Persistence**: Should the list of valid statuses be configurable per project?

## Objective

Enable more flexible and forgiving task state management in ace-taskflow, reducing friction for users who encounter rigid validation errors during normal workflows. This improves the user experience when managing tasks, especially in automated scripts or when dealing with tasks that may have custom statuses or are already in desired states.

## Scope of Work

- **User Experience Scope**: Task status transitions, task completion workflow, idempotent operations
- **System Behavior Scope**: Status validation logic, directory movement operations, error messaging
- **Interface Scope**: `ace-taskflow task done`, `ace-taskflow task update --status`, configuration options

### Deliverables

#### Behavioral Specifications
- Flexible status transition rules
- Idempotent operation behavior
- Custom status support specification

#### Validation Artifacts
- Test scenarios for flexible transitions
- Idempotency test cases
- Backward compatibility validation

## Out of Scope

- ❌ **Implementation Details**: Specific code changes to StatusValidator, TaskManager classes
- ❌ **Technology Decisions**: Whether to refactor molecules or organisms
- ❌ **Performance Optimization**: Caching strategies for status checks
- ❌ **Future Enhancements**: Bulk task transitions, status history tracking

## References

- Source idea: .ace-taskflow/v.0.9.0/ideas/done/20251007-215437-rethink-the-transitions-should-they-be-fixed-and.md
- Related error example: "Error: Invalid status transition: ready-for-review → done"
- Current rigid validation in ace-taskflow task management
