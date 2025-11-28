---
id: v.0.9.0+task.122.06
status: done
priority: high
estimate: 2-3h
dependencies:
  - v.0.9.0+task.122.05
parent: v.0.9.0+task.122
---

# Configurable Terminal States

## Scope

Make terminal statuses configurable instead of hardcoded. Currently `done` and `cancelled` are hardcoded in `task_manager.rb` for orchestrator auto-completion logic.

## Problem

Terminal statuses are hardcoded:

```ruby
terminal_statuses = %w[done cancelled]  # Lines 347, 359 in task_manager.rb
```

This should be configurable to support additional terminal states like `suspended`, `superseded`.

## Deliverables

### Config Changes

- [x] Add `terminal_statuses` to `.ace.example/taskflow/config.yml`
- [x] Add default in `config_loader.rb`
- [x] Add accessor in `configuration.rb`
- [x] Add extraction in `config_loader.rb` (extract_taskflow_config method)

### Code Changes

- [x] Update `all_subtasks_terminal?` to use config
- [x] Update `count_pending_subtasks` to use config

### Tests

- [x] Add tests for configurable terminal_statuses

## Acceptance Criteria

- [x] Terminal statuses are read from config
- [x] Default includes: done, cancelled, suspended, superseded
- [x] Orchestrator auto-complete respects configured terminal states
- [x] All existing tests pass
