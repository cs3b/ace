---
id: v.0.9.0+task.026
status: pending
priority: medium
estimate: 3h
dependencies: []
---

# Add reschedule subcommand to tasks command

## Description

Implement a reschedule subcommand for `ace-taskflow tasks` that allows reordering tasks by updating their sort values in frontmatter, similar to the old task-manager reschedule command.

## Planning Steps

* [ ] Review old task-manager reschedule implementation
* [ ] Design sort value management approach
* [ ] Plan command interface and options

## Execution Steps

- [ ] Modify `ace-taskflow/lib/ace/taskflow/commands/tasks_command.rb`
  - [ ] Add reschedule subcommand handling
  - [ ] Parse task IDs from arguments
  - [ ] Add `--add-next` option (places at front of queue)
  - [ ] Add `--add-at-end` option (places at end of queue)
  - [ ] Add `--after <task>` option (places after specific task)
  - [ ] Add `--before <task>` option (places before specific task)
  - [ ] Read default strategy from configuration
- [ ] Create `ace-taskflow/lib/ace/taskflow/organisms/task_scheduler.rb`
  - [ ] Implement sort value calculation logic
  - [ ] Support relative positioning (before/after specific task)
  - [ ] Handle frontmatter updates
  - [ ] Support batch operations
- [ ] Update configuration handling
  - [ ] Add `tasks.defaults.reschedule_strategy` config option
  - [ ] Support values: "add_next" (default), "add_at_end"
  - [ ] Allow project and user-level configuration
- [ ] Update task model to support sort values
  - [ ] Add sort field parsing from frontmatter
  - [ ] Implement sort value comparison
- [ ] Add command help documentation
- [ ] Create tests for reschedule functionality

## Acceptance Criteria

- [ ] `ace-taskflow tasks reschedule 025 026 027` uses configured default strategy
- [ ] `--add-next` flag places tasks before existing pending tasks
- [ ] `--add-at-end` flag places tasks after highest task
- [ ] `--after task.029` places tasks after task 029
- [ ] `--before task.029` places tasks before task 029
- [ ] Multiple tasks can be rescheduled in one command
- [ ] Sort values are properly updated in task frontmatter
- [ ] Command preserves relative order of specified tasks
- [ ] Configuration default is respected when no flag specified
- [ ] Relative positioning works with any task reference format

## Implementation Notes

Based on dev-tools/lib/coding_agent_tools/cli/commands/task/reschedule.rb:
- Use sort field in frontmatter for ordering
- Support flexible task ID formats (full ID, number only, partial match)
- Maintain backward compatibility with existing task files

Default strategy configuration:
- Built-in default: "add_next" (tasks go to front of queue)
- Can be overridden to "add_at_end" in config
- Command flags always override configuration
