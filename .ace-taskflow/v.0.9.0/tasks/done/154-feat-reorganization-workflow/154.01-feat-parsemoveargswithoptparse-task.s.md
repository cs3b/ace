---
id: v.0.9.0+task.154.01
status: done
priority: medium
estimate: 1h
dependencies: []
parent: v.0.9.0+task.154
---

# Add parse_move_args_with_optparse to TaskArgParser

## Scope

Add a new method `parse_move_args_with_optparse` to `TaskArgParser` that parses arguments for the `task move` command with support for `--child-of`, `--dry-run`, and positional arguments.

## Implementation Plan

### Planning Steps

* [x] Review existing `parse_create_args_with_optparse` pattern
* [x] Identify required options for move command

### Execution Steps

- [x] Add `parse_move_args_with_optparse` method to `TaskArgParser`
  - Parse `task_ref` (first positional arg - the task to move)
  - Parse `--child-of PARENT` / `-p PARENT` (target parent, or empty to promote)
  - Parse `--dry-run` / `-n` (preview without executing)
  - Parse `--release VERSION` (target release for cross-release moves)
  - Parse `--backlog` (shorthand for --release backlog)
  - Parse `-h / --help`
- [x] Add comprehensive tests in `task_arg_parser_test.rb`
- [x] Run tests: `ace-test test/molecules/task_arg_parser_test.rb`

## Deliverables

- [x] `parse_move_args_with_optparse` method added to `task_arg_parser.rb`
- [x] Comprehensive test coverage for new method

## Acceptance Criteria

- [x] Method parses `ace-taskflow task move 019 --child-of 121` correctly
- [x] Method parses `ace-taskflow task move 121.01 --child-of` (empty = promote)
- [x] Method parses `ace-taskflow task move 019 --child-of self` (convert to orchestrator)
- [x] Method parses `--dry-run` flag correctly
- [x] Method parses `--release VERSION` for cross-release moves
- [x] All tests pass
