---
id: v.0.9.0+task.011
status: done
estimate: 6h
dependencies: [v.0.9.0+task.010]
---

# Redesign ace-test-runner for Performance and Simplicity

## Behavioral Specification

### User Experience
- **Input**: Developers run `ace-test` command in a project with test files
- **Process**: System executes all tests in groups using native Minitest, displays compact progress, generates detailed reports
- **Output**: Fast test execution matching rake performance (< 0.5s for 83 tests) with concise 2-line error summaries and detailed reports

### Expected Behavior
The redesigned ace-test-runner provides blazing-fast test execution by leveraging native Minitest execution patterns instead of fighting against them. The current implementation's 3.2s execution time (vs rake's 0.37s) stems from running each test file in a separate process, creating massive overhead.

The new design executes all tests in a group within a single Ruby process, similar to how rake test works internally. This maintains the ATOM architecture within the gem structure while using proven, efficient test execution patterns.

Key behavioral changes:
1. **Group-based Execution**: All tests in a group run in single Ruby process
2. **Native Minitest**: Use Minitest's built-in execution flow, not custom process spawning
3. **Compact Output**: 2-line error summaries for quick scanning
4. **Detailed Reports**: Full error details saved to test-reports/ directory
5. **Feature Parity**: Support line numbers, patterns, and all existing ace-test features

### Interface Contract
```bash
# CLI Interface (maintained compatibility)
ace-test [options]
  --format FORMAT        # Output format: compact (default), json, markdown, verbose
  --report-dir DIR      # Report storage directory (default: test-reports/)
  --fail-fast           # Stop execution on first failure
  --filter PATTERN      # Run only tests matching pattern
  --line NUMBER         # Run test at specific line number
  --verbose             # Show detailed test execution
  --config FILE         # Use specific configuration file
  --help                # Display help information

# Performance-focused outputs
# Compact format (new default):
✅ 148 passed, ❌ 2 failed, ⚠️ 1 skipped (0.42s)
Failures:
  test/foo_test.rb:42 - test_validation_error
  test/bar_test.rb:15 - test_connection_timeout
Reports: test-reports/2025-01-20-14-30-45/

# Verbose format (detailed during execution):
Running group: unit_tests (42 tests)
Running group: integration_tests (41 tests)
✅ 148 passed, ❌ 2 failed, ⚠️ 1 skipped (0.42s)
[... full error details ...]
```

**Error Handling:**
- [Test execution failure]: Display error "Test execution failed: [reason]" with exit code 1
- [Group configuration missing]: Use default grouping with warning
- [Minitest not available]: Display error "Minitest not available. Run: bundle install" with exit code 1
- [Permission denied]: Display error "Cannot write to test-reports/. Check permissions" with exit code 1

**Edge Cases:**
- [No test groups configured]: Run all tests in single default group
- [Empty test group]: Skip group with notification, continue with others
- [Mixed test types]: Execute each group with appropriate test runner
- [Line number conflicts]: Show error when line number spans multiple files

### Success Criteria
- [ ] **Performance**: Test execution time matches rake test performance (< 0.5s for 83 tests)
- [ ] **Native Execution**: Uses Minitest's built-in execution flow, not separate processes
- [ ] **Compact Output**: 2-line error summaries for quick developer scanning
- [ ] **Group Execution**: All tests in group execute in single Ruby process
- [ ] **Feature Parity**: Supports line numbers, patterns, fail-fast, and report generation
- [ ] **ATOM Architecture**: Follows established lib/ structure with atoms/molecules/organisms
- [ ] **Configuration**: YAML-based test group and pattern configuration
- [ ] **Report Generation**: Detailed reports saved to timestamped directories

### Validation Questions
- [ ] **Group Definition**: How should default test groups be determined when no configuration exists?
- [ ] **Memory Management**: How should we handle memory usage for large test suites in single process?
- [ ] **Error Isolation**: How should test failures in one group affect other group execution?
- [ ] **Configuration Location**: Should test group configuration be in .ace/test.yml or separate file?
- [ ] **Backward Compatibility**: Should the old process-per-file execution be available as fallback option?

## Objective

Redesign ace-test-runner to achieve rake test performance levels while maintaining all current features and following ATOM architecture. The current implementation's 8.6x performance penalty (3.2s vs 0.37s) makes it impractical for development use, requiring a fundamental architectural shift from process-per-file to group-based native execution.

## Scope of Work

- **User Experience Scope**: Fast test execution, compact output format, detailed report generation
- **System Behavior Scope**: Group-based test execution, native Minitest integration, ATOM architecture implementation
- **Interface Scope**: CLI compatibility, YAML configuration, timestamped report storage

### Deliverables

#### Behavioral Specifications
- Group-based test execution flow with single-process model
- Compact output format with 2-line error summaries
- Native Minitest integration without process spawning overhead
- YAML configuration system for test groups and patterns

#### Validation Artifacts
- Performance benchmarks comparing new vs old implementation
- Test suite validating all existing ace-test features
- Example configurations for common project layouts
- Migration guide from current to redesigned implementation

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby class structures, module organization
- ❌ **Technology Decisions**: Alternative testing frameworks beyond Minitest
- ❌ **Advanced Features**: Parallel execution, test coverage integration
- ❌ **Legacy Support**: Maintaining process-per-file execution model

## Technical Approach

### Architecture Pattern
- **Current Problem**: TestExecutor.execute_with_progress calls execute_single_file for each test file, creating process overhead
- **Solution**: Use grouped execution via TestExecutor.execute_tests which properly leverages CommandBuilder.build_test_command
- **ATOM Integration**: Maintain existing ATOM structure but optimize execution flow within molecules layer
- **Performance Target**: Match rake test's native Ruby execution model

### Technology Stack
- **Test Framework**: Minitest (existing) with native autorun execution
- **Process Model**: Single Ruby process per test group instead of per file
- **Command Building**: Enhanced CommandBuilder to support group-based execution patterns
- **Output Handling**: New compact formatter for 2-line error summaries

### Implementation Strategy
- **Phase 1**: Modify TestExecutor to default to group execution instead of file-by-file
- **Phase 2**: Create CompactFormatter for performance-focused output
- **Phase 3**: Add YAML configuration for test groups
- **Phase 4**: Update CLI to use group-based execution by default

## Tool Selection

| Criteria | Current (per-file) | Grouped Execution | Rake Test | Selected |
|----------|--------------------|--------------------|-----------|----------|
| Performance | Poor (3.2s) | Good (target <0.5s) | Excellent (0.37s) | Grouped |
| Integration | Good | Excellent | Good | Grouped |
| Maintenance | Fair | Good | Excellent | Grouped |
| Features | Excellent | Excellent | Poor | Grouped |
| Memory Usage | High | Medium | Low | Grouped |

**Selection Rationale:** Grouped execution provides the best balance of performance (approaching rake test speeds) while maintaining all ace-test features and ATOM architecture.

### Dependencies
- **Existing**: Minitest, ace-core (configuration), ace-test-support
- **No new dependencies**: Solution uses existing tools more efficiently
- **Ruby stdlib**: Enhanced use of require patterns and Minitest.autorun

## File Modifications

### Modify
- `ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb`
  - Changes: Replace default file-by-file execution with group execution
  - Impact: Massive performance improvement, maintains existing interface
  - Integration points: CommandBuilder, result parsing, progress callbacks

- `ace-test-runner/lib/ace/test_runner/atoms/command_builder.rb`
  - Changes: Enhance group command building, add test group support
  - Impact: Better command generation for grouped execution
  - Integration points: Test detection, configuration loading

### Create
- `ace-test-runner/lib/ace/test_runner/formatters/compact_formatter.rb`
  - Purpose: Performance-focused output with 2-line error summaries
  - Key components: Concise error display, timing info, report references
  - Dependencies: BaseFormatter, test results parsing

- `ace-test-runner/lib/ace/test_runner/models/test_group.rb`
  - Purpose: Data structure for test group configuration
  - Key components: Group name, file patterns, execution options
  - Dependencies: Configuration loading, test detection

- `ace-test-runner/config/groups.yml`
  - Purpose: Default test group configuration
  - Key components: Standard Ruby project test groups (unit, integration, system)
  - Dependencies: Configuration cascade from ace-core

### Enhance
- `ace-test-runner/exe/ace-test`
  - Changes: Add --groups option, make compact format default
  - Impact: Better CLI UX focused on performance
  - Integration points: Argument parsing, configuration loading

## Implementation Plan

### Planning Steps

* [ ] Analyze current execution bottlenecks in TestExecutor
  > TEST: Performance Analysis
  > Type: Pre-condition Check
  > Assert: Identified specific performance bottlenecks in file-by-file execution
  > Command: # time ace-test vs time rake test comparison

* [ ] Research Minitest group execution patterns
  > TEST: Minitest Pattern Research
  > Type: Research Validation
  > Assert: Documented how rake test achieves fast execution with Minitest
  > Command: # strace or similar analysis of rake test execution

* [ ] Design test group configuration schema
  > TEST: Configuration Design
  > Type: Design Validation
  > Assert: YAML schema supports flexible test grouping
  > Command: # yaml-lint config/groups.yml

### Execution Steps

- [ ] Create CompactFormatter for performance-focused output
  > TEST: Compact Format Validation
  > Type: Action Validation
  > Assert: Formatter produces 2-line error summaries as specified
  > Command: # ace-test --format compact failing_test.rb | wc -l

- [ ] Add TestGroup model for configuration management
  > TEST: Test Group Model
  > Type: Action Validation
  > Assert: Model loads and validates test group configurations
  > Command: # ruby -r ./lib/ace/test_runner/models/test_group -e "puts TestGroup.new.valid?"

- [ ] Modify TestExecutor to use grouped execution by default
  > TEST: Grouped Execution Performance
  > Type: Performance Validation
  > Assert: Grouped execution is at least 5x faster than current implementation
  > Command: # time ace-test test/ (should be < 0.6s for 83 tests)

- [ ] Enhance CommandBuilder for optimized group commands
  > TEST: Command Builder Enhancement
  > Type: Action Validation
  > Assert: Builder generates efficient grouped test commands
  > Command: # ruby -r ./lib/ace/test_runner -e "puts CommandBuilder.new.build_group_command(['test/*.rb'])"

- [ ] Add YAML configuration support for test groups
  > TEST: Configuration Loading
  > Type: Integration Validation
  > Assert: Configuration loads test groups from YAML and ace-core cascade
  > Command: # ace-test --config config/groups.yml --dry-run

- [ ] Update CLI to use compact format and groups by default
  > TEST: CLI Default Behavior
  > Type: Action Validation
  > Assert: CLI defaults to compact format and grouped execution
  > Command: # ace-test test/ | grep "passed.*failed.*skipped"

- [ ] Add backward compatibility flag for file-by-file execution
  > TEST: Backward Compatibility
  > Type: Compatibility Validation
  > Assert: --per-file flag maintains old behavior for debugging
  > Command: # ace-test --per-file test/ (should work but be slower)

- [ ] Performance benchmark and validation
  > TEST: Performance Target Achievement
  > Type: Performance Validation
  > Assert: Test execution time is < 0.5s for 83 tests (matching rake test)
  > Command: # hyperfine "ace-test test/" "rake test" --min-runs 5

## Risk Assessment

### Technical Risks
- **Risk:** Group execution might mask test isolation issues
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Maintain --per-file flag for debugging, add test isolation warnings
  - **Rollback:** Revert to file-by-file execution if isolation issues found

- **Risk:** Memory usage increase with all tests in single process
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Monitor memory usage, add group size limits in configuration
  - **Rollback:** Split large groups into smaller ones

### Integration Risks
- **Risk:** Breaking existing ace-test workflows and scripts
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Maintain CLI compatibility, provide migration guide
  - **Monitoring:** Test all documented ace-test usage patterns

### Performance Risks
- **Risk:** Not achieving target performance improvement
  - **Mitigation:** Benchmark at each step, profile execution patterns
  - **Monitoring:** Continuous performance testing with hyperfine
  - **Thresholds:** Must achieve < 0.6s for 83 tests (5x improvement minimum)

## Acceptance Criteria

- [ ] **Performance**: Test execution time < 0.5s for 83 tests (matching rake test)
- [ ] **Output**: Compact format shows 2-line error summaries by default
- [ ] **Features**: All existing ace-test features work with grouped execution
- [ ] **Configuration**: YAML-based test groups with sensible defaults
- [ ] **Compatibility**: Existing ace-test CLI usage continues to work
- [ ] **Architecture**: Maintains ATOM structure with optimized execution flow
- [ ] **Reliability**: All tests pass with grouped execution

## Out of Scope

- ❌ **Parallel Execution**: Multi-threaded or multi-process parallelism
- ❌ **Test Coverage**: Integration with coverage tools
- ❌ **Test Generation**: Automatic test creation features
- ❌ **Framework Support**: Support for testing frameworks other than Minitest

## References

- Current ace-test-runner task: dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.010-create-ace-test-runner-package-for-test-execution-and.md
- Performance analysis: 3.2s vs rake's 0.37s for 83 tests
- ATOM architecture pattern: ace-core, ace-context, ace-test-support examples
- Native Minitest execution patterns in Ruby standard library
- Current bottleneck: TestExecutor.execute_with_progress using execute_single_file
- Solution pattern: CommandBuilder.build_test_command with Minitest.autorun