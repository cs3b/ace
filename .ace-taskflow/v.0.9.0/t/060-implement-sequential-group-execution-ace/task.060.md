---
id: v.0.9.0+task.060
status: pending
priority: medium
estimate: TBD
dependencies: []
---

# Implement sequential group execution for ace-test

## Description

Implement sequential group execution for ace-test to run test groups one at a time with visual separation and progress indicators. When running `ace-test all` or `ace-test unit`, test groups should execute in ATOM architecture order (atoms → molecules → organisms → models) with clear visual feedback showing group start, progress, and completion status.

### Current Behavior
- `ace-test all` resolves groups to a flat array of all files
- All files loaded into one Ruby process
- Minitest runs them (potentially in random order)
- No visual separation between atoms, molecules, organisms, etc.

### Desired Behavior
- `ace-test all` runs groups sequentially:
  1. Run atoms → show "Running atoms..." → display progress → check result
  2. Run molecules → show "Running molecules..." → display progress → check result
  3. Run organisms → show "Running organisms..." → display progress → check result
  4. Run models → show "Running models..." → display progress → check result
  5. Run integration → show "Running integration..." → display progress → check result
  6. Run system → show "Running system..." → display progress → check result
  7. Run uncategorized files (if any)
- With `--fail-fast`: Stop at group level if group fails (don't run next groups)

## Planning Steps

* [ ] Review current PatternResolver group resolution logic in `ace-test-runner/lib/ace/test_runner/molecules/pattern_resolver.rb`
* [ ] Analyze TestOrchestrator execution flow in `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb`
* [ ] Review TestExecutor grouped vs per-file execution in `ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb`
* [ ] Design SequentialGroupExecutor architecture (input, output, responsibilities)
* [ ] Review formatter event system in ProgressFormatter and determine new event types needed

## Execution Steps

- [ ] Add `resolve_group_sequential` method to PatternResolver that preserves group structure instead of flattening
- [ ] Create `ace-test-runner/lib/ace/test_runner/organisms/sequential_group_executor.rb` with group-by-group execution logic
- [ ] Add `should_execute_sequentially?` and `sequential_options` helper methods to TestOrchestrator
- [ ] Update TestOrchestrator `run` method to detect and use sequential execution when appropriate
- [ ] Add `on_group_start` and `on_group_complete` event methods to ProgressFormatter
- [ ] Add `execution` configuration accessor to Configuration model
- [ ] Update `.ace/test/runner.yml` with execution settings section (sequential_groups, group_fail_fast)
- [ ] Test sequential execution with `ace-test all` - verify groups run in order with visual separation
- [ ] Test group fail-fast with `ace-test all --fail-fast` - verify stops at first failing group
- [ ] Test backward compatibility - verify single pattern execution still works as before

## Acceptance Criteria

- [ ] `ace-test all` runs groups sequentially with visual separation (shows group name before execution)
- [ ] `ace-test all --fail-fast` stops at first failing group and doesn't run subsequent groups
- [ ] `ace-test unit` runs atoms → molecules → organisms → models in correct order
- [ ] Progress formatter shows per-group status with ✓ or ✗ indicators
- [ ] Backward compatible - running single patterns like `ace-test atoms` still works as before
- [ ] Configuration allows enabling/disabling sequential execution via `execution.sequential_groups`
- [ ] Group fail-fast behavior can be configured via `execution.group_fail_fast` setting

## Implementation Notes

### Files to Create
1. `ace-test-runner/lib/ace/test_runner/organisms/sequential_group_executor.rb` - New organism for sequential group execution

### Files to Modify
1. `ace-test-runner/lib/ace/test_runner/molecules/pattern_resolver.rb` - Add `resolve_group_sequential` method
2. `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb` - Add sequential execution logic
3. `ace-test-runner/lib/ace/test_runner/organisms/progress_formatter.rb` - Add group event methods
4. `ace-test-runner/lib/ace/test_runner/models/configuration.rb` - Add execution config accessor
5. `.ace/test/runner.yml` - Add execution settings (optional, defaults should work)

### Example Output
```
$ ace-test all --fail-fast

Running atoms (15 files)...
..............
✓ atoms complete (0.3s, 45 tests, 0 failures)

Running molecules (12 files)...
...........
✓ molecules complete (0.5s, 38 tests, 0 failures)

Running organisms (8 files)...
...F....
✗ organisms complete (0.4s, 22 tests, 1 failure)

STOPPED: Group 'organisms' failed (--fail-fast enabled)

FAILURES (1):
  test/organisms/task_manager_test.rb:45 - Expected 006 but got 011
```
