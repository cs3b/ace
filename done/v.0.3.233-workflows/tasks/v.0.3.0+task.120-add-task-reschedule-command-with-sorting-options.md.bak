---
id: v.0.3.0+task.120
status: done
priority: high
estimate: 8h
dependencies: []
sort: 124
---

# Add task reschedule command with sorting options

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

Implement a new `task-manager reschedule` command that allows reordering tasks with flexible sorting options to improve task prioritization and workflow management.

## Scope of Work

- Add new reschedule subcommand to task-manager
- Implement --add-next and --add-at-the-end flag options
- Update task sorting logic to respect sort attributes
- Ensure proper task metadata updates during rescheduling

### Deliverables

#### Create

- Task reschedule command implementation
- Sort attribute management logic
- CLI argument parsing for reschedule command

#### Modify

- dev-tools/lib/coding_agent_tools/cli/task_manager.rb (add reschedule command)
- dev-tools/exe/task-manager (command routing)
- Task sorting and ordering logic
- Task metadata update mechanisms

#### Delete

- N/A

## Phases

1. Audit current task management and sorting implementation
2. Design reschedule command architecture
3. Implement core reschedule functionality
4. Add sorting option flags
5. Test task reordering scenarios

## Implementation Plan

### Planning Steps

- [x] Analyze current task management CLI structure and command patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current CLI structure and task management methods are identified
  > Command: grep -r "class.*CLI\|def.*command" dev-tools/lib/coding_agent_tools/cli/
- [x] Study existing task sorting and prioritization logic
- [x] Design reschedule command interface and flag behavior specifications
- [x] Plan sort attribute schema and metadata updates

### Execution Steps

- [x] Implement task-manager reschedule command with basic functionality
- [x] Add --add-next flag that moves specified tasks before other pending tasks
  > TEST: Verify --add-next functionality
  > Type: Action Validation
  > Assert: Tasks moved with --add-next appear before existing pending tasks in sort order
  > Command: task-manager reschedule task.001 task.002 --add-next && task-manager next --limit 5 | head -3
- [x] Add --add-at-the-end flag that finds highest pending number and sequences from there
- [x] Implement sort attribute updates in task metadata during reschedule operations
- [x] Update default task sorting to prioritize sort attribute over status-based ordering
- [x] Add validation and error handling for invalid task IDs or paths

## Acceptance Criteria

- [x] AC 1: task-manager reschedule command accepts list of task IDs or file paths
- [x] AC 2: --add-next flag correctly repositions tasks before existing pending tasks
- [x] AC 3: --add-at-the-end flag (default) sequences tasks after highest pending number  
- [x] AC 4: Task sorting respects sort attribute priority while maintaining status precedence (in-progress before pending)
- [x] AC 5: Reschedule operations update task metadata with appropriate sort values

## Out of Scope

- ❌ Batch reschedule operations across multiple releases
- ❌ Complex dependency resolution during reschedule
- ❌ UI/interactive reschedule interface (command-line only)
- ❌ Historical tracking of reschedule operations

## References

Based on requirements from: dev-taskflow/backlog/ideas/exe-task-manager.md
Item #3: "allow to overwrite sort"
- Command: `task-manager reschedule <list-of-tasks-can-be-ids-or-paths>`
- Flags: `--add-next` (move tasks to beginning of pending queue)
- Flags: `--add-at-the-end` (default behavior, sequence after highest pending)
- Sorting: sort attribute takes priority within status groups (in-progress > pending regardless of sort number)