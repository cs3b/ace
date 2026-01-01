---
id: v.0.9.0+task.157.25
status: done
priority: low
estimate: 2h
dependencies:
- v.0.9.0+task.157.11
parent: v.0.9.0+task.157
---

# ace-support-core - Add Config for Timeouts and Limits

## Objective

Add configurable timeout and chunk_limit to `.ace-defaults/core/settings.yml` and implement reset_config! method.

## Current Issues

Hardcoded values in:
- `molecules/context_chunker.rb` - DEFAULT_CHUNK_LIMIT=150,000
- `atoms/command_executor.rb` - DEFAULT_TIMEOUT=30

No reset_config! method for test isolation.

## Scope of Work

### Files to Modify

- `ace-support-core/.ace-defaults/core/settings.yml` - Add timeout and chunk_limit
- `ace-support-core/lib/ace/core/molecules/context_chunker.rb`
- `ace-support-core/lib/ace/core/atoms/command_executor.rb`
- `ace-support-core/lib/ace/core.rb` - Add reset_config! if not present

## Implementation Plan

### Execution Steps

- [x] Update .ace-defaults/core/settings.yml
  ```yaml
  core:
    command_executor:
      timeout: 30
    context_chunker:
      chunk_limit: 150000
  ```

- [x] Update context_chunker.rb to read chunk_limit from config
  > Replace DEFAULT_CHUNK_LIMIT with config lookup

- [x] Update command_executor.rb to read timeout from config
  > Replace DEFAULT_TIMEOUT with config lookup

- [x] Add reset_config! method to Ace::Core module
  > Already present - verified existing implementation

- [x] Run tests with `ace-test ace-support-core`
  > 190 tests, 514 assertions, 0 failures, 0 errors

- [x] Bump patch version
  > 0.14.1 -> 0.14.2

## Acceptance Criteria

- [x] timeout and chunk_limit configurable via .ace-defaults/core/settings.yml
- [x] reset_config! method available for test isolation
- [x] All ace-support-core tests pass
- [x] Gem version bumped
