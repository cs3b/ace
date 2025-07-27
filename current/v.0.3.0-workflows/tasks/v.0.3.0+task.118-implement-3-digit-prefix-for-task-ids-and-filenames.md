---
id: v.0.3.0+task.118
status: pending
priority: medium
estimate: 6h
dependencies: []
---

# Implement 3-digit prefix for task IDs and filenames

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools | sed 's/^/    /'
```

_Result excerpt:_

```
dev-tools/lib/coding_agent_tools
├── atoms
├── cli
├── constants
├── ecosystems
├── middlewares
├── models
├── molecules
├── organisms
└── version.rb
```

## Objective

Standardize task ID format across the project to use 3-digit zero-padded prefixes (e.g., `v.0.3.0+task.001` instead of `v.0.3.0+task.1`) to improve sorting consistency and file organization.

## Scope of Work

- Update task ID generation logic to use 3-digit padding
- Ensure filename conventions align with ID format
- Maintain backward compatibility with existing task IDs
- Update any documentation references to reflect new format

### Deliverables

#### Create

- Updated ID generation logic in task management utilities

#### Modify

- dev-tools/lib/coding_agent_tools/organisms/taskflow_management/task_id_generator.rb (or equivalent)
- dev-tools/exe/task-manager (ID generation logic)
- Any nav-path task creation logic

#### Delete

- N/A

## Phases

1. Audit current ID generation implementation
2. Update ID generation to use 3-digit padding
3. Test with new task creation
4. Verify backward compatibility

## Implementation Plan

### Planning Steps

- [ ] Analyze current task ID generation logic in the codebase
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current ID generation mechanism is identified and understood
  > Command: grep -r "task\." dev-tools/lib/ --include="*.rb"
- [ ] Review existing task files to understand current naming patterns
- [ ] Plan migration strategy for maintaining compatibility

### Execution Steps

- [ ] Locate and update the task ID generation logic to use 3-digit zero-padding
- [ ] Update nav-path task-new functionality to use new ID format
  > TEST: Verify ID Generation
  > Type: Action Validation
  > Assert: New task IDs are generated with 3-digit padding (e.g., 001, 002, 118)
  > Command: task-manager generate-id | grep -E "task\.[0-9]{3}$"
- [ ] Test task creation with new ID format to ensure file naming consistency
- [ ] Verify that existing task operations still work with current task files

## Acceptance Criteria

- [ ] AC 1: New task IDs are generated with 3-digit zero-padding (e.g., task.001, task.002)
- [ ] AC 2: Filenames reflect the new ID format consistently
- [ ] AC 3: Existing task files and operations remain functional
- [ ] AC 4: task-manager generate-id command returns 3-digit format

## Out of Scope

- ❌ Renaming existing task files to new format (maintains backward compatibility)
- ❌ Modifying completed or archived tasks
- ❌ Changes to task content or metadata structure

## References

Based on requirements from: dev-taskflow/backlog/ideas/exe-task-manager.md
Item #1: "ensure we are using prefixed ids for tasks and filenames (not v.0.3.0+task.1 instead not v.0.3.0+task.001) - lets use 3 digits prefix"