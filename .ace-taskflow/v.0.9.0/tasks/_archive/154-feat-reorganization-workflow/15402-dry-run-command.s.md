---
id: v.0.9.0+task.154.02
status: done
priority: medium
estimate: 30m
dependencies:
  - v.0.9.0+task.154.01
parent: v.0.9.0+task.154
---

# Add --dry-run to task create command

## Scope

Add `--dry-run` / `-n` option to `task create` command that shows what would be created without actually creating files.

## Implementation Plan

### Execution Steps

- [x] Add `--dry-run` / `-n` option to `parse_create_args_with_optparse` in TaskArgParser
- [x] Modify `create_task` method in TaskCommand to handle dry-run mode
- [x] When dry-run: show path, ID, and metadata that would be created
- [x] Add tests for dry-run functionality
- [x] Run tests: `ace-test test/molecules/task_arg_parser_test.rb && ace-test test/commands/task_command_test.rb`

## Deliverables

- [x] `--dry-run` option parsing in TaskArgParser
- [x] Dry-run handling in TaskCommand#create_task
- [x] Test coverage for new functionality

## Acceptance Criteria

- [x] `ace-taskflow task create "Test" --dry-run` shows preview without creating
- [x] `ace-taskflow task create "Test" -n` works with short flag
- [x] Dry-run output shows: would-be path, ID, status, and metadata
- [x] All tests pass
