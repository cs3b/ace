---
id: v.0.9.0+task.026
status: done
priority: medium
estimate: 3h
dependencies: []
sort: 31
---

# Add reschedule subcommand to tasks command

## Description

Implement a reschedule subcommand for `ace-taskflow tasks` that allows reordering tasks by updating their sort values in frontmatter, similar to the old task-manager reschedule command.

## Planning Steps

* [x] Review old task-manager reschedule implementation
* [x] Design sort value management approach
* [x] Plan command interface and options

## Execution Steps

- [x] Modify `ace-taskflow/lib/ace/taskflow/commands/tasks_command.rb`
  - [x] Add reschedule subcommand handling
  - [x] Parse task IDs from arguments
  - [x] Add `--add-next` option (places at front of queue)
  - [x] Add `--add-at-end` option (places at end of queue)
  - [x] Add `--after <task>` option (places after specific task)
  - [x] Add `--before <task>` option (places before specific task)
  - [x] Read default strategy from configuration
- [x] Create `ace-taskflow/lib/ace/taskflow/organisms/task_scheduler.rb`
  - [x] Implement sort value calculation logic
  - [x] Support relative positioning (before/after specific task)
  - [x] Handle frontmatter updates
  - [x] Support batch operations
- [x] Update configuration handling
  - [x] Add `tasks.defaults.reschedule_strategy` config option
  - [x] Support values: "add_next" (default), "add_at_end"
  - [x] Allow project and user-level configuration
- [x] Update task model to support sort values
  - [x] Add sort field parsing from frontmatter
  - [x] Implement sort value comparison
- [x] Add command help documentation
- [x] Create tests for reschedule functionality

## Acceptance Criteria

- [x] `ace-taskflow tasks reschedule 025 026 027` uses configured default strategy
- [x] `--add-next` flag places tasks before existing pending tasks
- [x] `--add-at-end` flag places tasks after highest task
- [x] `--after task.029` places tasks after task 029
- [x] `--before task.029` places tasks before task 029
- [x] Multiple tasks can be rescheduled in one command
- [x] Sort values are properly updated in task frontmatter
- [x] Command preserves relative order of specified tasks
- [x] Configuration default is respected when no flag specified
- [x] Relative positioning works with any task reference format

## Implementation Notes

Based on dev-tools/lib/coding_agent_tools/cli/commands/task/reschedule.rb:
- Use sort field in frontmatter for ordering
- Support flexible task ID formats (full ID, number only, partial match)
- Maintain backward compatibility with existing task files

Default strategy configuration:
- Built-in default: "add_next" (tasks go to front of queue)
- Can be overridden to "add_at_end" in config
- Command flags always override configuration
