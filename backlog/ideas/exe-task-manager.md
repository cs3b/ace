1. ensure we are using prefixed ids for tasks and filenames
   (not v.0.3.0+task.1 instead not v.0.3.0+task.001) - lets use 3 digits prefix

2. lets make it more compact
instead of:

  2. v.0.3.0+task.116
     Title: Refactor create-path executable to use dry library pattern
     Status: PENDING
     Path: /Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-taskflow/current/v.0.3.0-workflows/tasks/v.0.3.0+task.116-refactor-create-path-executable-to-use-dry-library-pattern.md
     Dependencies: v.0.3.0+task.112

lets use:

  v.0.3.0+task.116 * PENDING * Refactor create-path executable to use dry library pattern
    dev-taskflow/current/v.0.3.0-workflows/tasks/v.0.3.0+task.116-refactor-create-path-executable-to-use-dry-library-pattern.md
    dependencies: v.0.3.0+task.112

3. allow to overwrite sort:

task-manager reschedule <list-of-those-tasks-can-be-ids-or-paths>
two flags:
  --add-next (find all the pending task with number and move them at the end on this same order after those tasks)
  --add-at-the-end (finds the highest number still pending and count from this number with sort: ) - this is the default behavoirs

It should have impact on how we sort tasks by default (the sort attribute have priority in the status (still in-progress will be before pending even if the number is lower)

4. allow to read dates (not only date time from yaml) (update: was date not date time)

task-manager next --limit 5
Warning: Failed to parse task file /Users/michalczyz/Projects/CodingAgent/handbook-meta/dev-taskflow/current/v.0.3.0-workflows/tasks/v.0.3.0+task.100-create-unit-tests-for-cli-command-classes.md: Tried to load unspecified class: Date
No actionable tasks found

---
id: v.0.3.0+task.100
status: in-progress
priority: medium
estimate: 20h
dependencies: []
completion: 85%
updated: 2025-07-25
remaining_work: 5_git_commands
---
