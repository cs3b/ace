---

id: v.0.3.0+task.07
status: done
priority: high
estimate: 10h
dependencies: [v.0.3.0+task.06]
---

# Implement Task Manager Organism

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 1 .ace/tools/lib/coding_agent_tools/organisms | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/lib/coding_agent_tools/organisms
    └── (existing organisms)
```

## Objective

Implement the core TaskManager organism that orchestrates molecules to provide high-level task management functionality, including finding next tasks, recent tasks, and all tasks with topological sorting.

## Scope of Work

* Implement task_manager.rb organism with core business logic
* Port logic from get-next-task, get-recent-tasks, and get-all-tasks
* Implement topological sorting with cycle detection
* Handle complex priority and status sorting
* Create comprehensive integration tests

### Deliverables

#### Create

* lib/coding_agent_tools/organisms/task_management/task_manager.rb
* spec/coding_agent_tools/organisms/task_management/task_manager_spec.rb

#### Modify

* None

#### Delete

* None

## Phases

1. Implement core TaskManager structure
2. Port next task finding logic
3. Port recent tasks logic
4. Implement topological sort for all tasks
5. Add comprehensive testing

## Implementation Plan

### Planning Steps

* [x] Analyze get-all-tasks topological sort algorithm (270 lines)
  > TEST: Algorithm Analysis
  > Type: Pre-condition Check
  > Assert: Topological sort logic is understood
  > Command: grep -n "topological" .ace/tools/exe-old/get-all-tasks | wc -l
* [x] Study priority and status sorting requirements
* [x] Design organism API for all three main operations

### Execution Steps

- [x] Create task_management directory in organisms/
- [x] Implement TaskManager class with initialization
- [x] Implement find_next_task method with dependency resolution
  > TEST: Next Task Finding
  > Type: Integration Test
  > Assert: Finds correct next actionable task
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/task_management/task_manager_spec.rb -e "find_next_task"
- [x] Implement find_recent_tasks with time-based filtering
- [x] Implement get_all_tasks with topological sorting
- [x] Add cycle detection for dependency graphs
  > TEST: Cycle Detection
  > Type: Integration Test
  > Assert: Detects circular dependencies
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/organisms/task_management/task_manager_spec.rb -e "cycle"
- [x] Implement color-coded output for next actionable task
- [x] Create comprehensive integration tests

## Acceptance Criteria

* [x] TaskManager can find the next actionable task with dependency resolution
* [x] Recent tasks filtering works with flexible time periods
* [x] All tasks are returned in topological order with cycle detection
* [x] Priority and status sorting matches exe-old behavior
* [x] Integration tests cover all major scenarios

## Out of Scope

* ❌ CLI command implementation
* ❌ Direct file I/O (handled by molecules)
* ❌ Migration of other exe-old tools

## References

* Dependency: v.0.3.0+task.06 (molecules implementation)
* Complex logic reference: .ace/tools/exe-old/get-all-tasks (270 lines)
* Next task logic: .ace/tools/exe-old/get-next-task (82 lines)
* Recent tasks logic: .ace/tools/exe-old/get-recent-tasks (78 lines)