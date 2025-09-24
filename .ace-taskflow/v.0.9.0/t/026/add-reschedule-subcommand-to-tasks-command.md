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
  - [ ] Add `--add-next` and `--add-at-end` options
- [ ] Create `ace-taskflow/lib/ace/taskflow/organisms/task_scheduler.rb`
  - [ ] Implement sort value calculation logic
  - [ ] Handle frontmatter updates
  - [ ] Support batch operations
- [ ] Update task model to support sort values
  - [ ] Add sort field parsing from frontmatter
  - [ ] Implement sort value comparison
- [ ] Add command help documentation
- [ ] Create tests for reschedule functionality

## Acceptance Criteria

- [ ] `ace-taskflow tasks reschedule 025 026 027` reorders tasks
- [ ] `--add-next` flag places tasks before existing pending tasks
- [ ] `--add-at-end` flag places tasks after highest task (default)
- [ ] Multiple tasks can be rescheduled in one command
- [ ] Sort values are properly updated in task frontmatter
- [ ] Command preserves relative order of specified tasks

## Implementation Notes

Based on dev-tools/lib/coding_agent_tools/cli/commands/task/reschedule.rb:
- Use sort field in frontmatter for ordering
- Support flexible task ID formats (full ID, number only, partial match)
- Maintain backward compatibility with existing task files
