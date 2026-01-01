---
id: v.0.9.0+task.157.23
status: done
priority: low
estimate: 1h
dependencies:
- v.0.9.0+task.157.11
parent: v.0.9.0+task.157
---

# ace-review - Fix execute_simple Timeout

## Objective

Make execute_simple method in GhCliExecutor use the configured gh_timeout instead of hardcoded 10 seconds.

## Current Issues

- `molecules/gh_cli_executor.rb:21` - Default timeout: 30 seconds (from config)
- `molecules/gh_cli_executor.rb:66` - execute_simple hardcoded timeout: 10 seconds
- Config already has `gh_timeout: 30` but execute_simple doesn't use it

## Scope of Work

### Files to Modify

- `ace-review/lib/ace/review/molecules/gh_cli_executor.rb`

## Implementation Plan

### Execution Steps

- [x] Update execute_simple method to use config timeout
  > Change hardcoded 10 to use Ace::Review.config["defaults"]["gh_timeout"]
  > Or add separate execute_simple_timeout to config

- [x] Consider if execute_simple needs different timeout than regular execute
  > If yes, add `gh_simple_timeout` to .ace-defaults/review/config.yml

- [x] Run tests with `ace-test ace-review`

- [x] Bump patch version

## Acceptance Criteria

- [x] execute_simple uses configurable timeout
- [x] All ace-review tests pass
- [x] Gem version bumped
