---
id: v.0.5.0+task.044
status: done
priority: medium
estimate: 3h
dependencies: []
---

# Add --all Flag to Task-Manager Next Command

## Behavioral Specification

### User Experience
- **Input**: Users execute `task-manager next` with optional `--all` flag to retrieve either single next task (default) or all pending ready tasks
- **Process**: System identifies pending tasks ready for work, filters by dependencies and readiness, returns appropriate number based on flag usage
- **Output**: Single task (default) or complete list of all actionable tasks with consistent formatting

### Expected Behavior
When users run `task-manager next` with different flag combinations, the system should:
1. **Default behavior**: Return single next pending task ready for work (maintains backward compatibility)
2. **With `--all` flag**: Return all pending tasks that are ready to be worked on (no dependency blockers)
3. **Consistent formatting**: Use same output format whether returning one task or multiple tasks
4. **Proper filtering**: Only include tasks that are actually actionable (no unmet dependencies)
5. **Clear status reporting**: Indicate when no tasks are available vs when tasks exist but aren't ready

### Interface Contract
```bash
# CLI Interface - Default behavior (single task)
task-manager next
# Expected output (single task format):
# "v.0.5.0+task.045 - Fix authentication bug (high priority, 4h estimate)"
# OR: "No tasks ready for work"

# CLI Interface - All ready tasks
task-manager next --all
# Expected output (multiple task format):
# "3 tasks ready for work:"
# "v.0.5.0+task.045 - Fix authentication bug (high priority, 4h)"
# "v.0.5.0+task.046 - Update documentation (medium priority, 2h)"
# "v.0.5.0+task.047 - Refactor utilities (low priority, 6h)"
# OR: "No tasks ready for work"

# Alternative flag support (--limit -1)
task-manager next --limit -1
# Expected: Same behavior as --all flag for flexibility
```

**Error Handling:**
- No tasks available: Clear message indicating no tasks are ready
- Dependency conflicts: Tasks with unmet dependencies are excluded from results
- Repository access issues: Error message with specific access problem details

**Edge Cases:**
- All tasks blocked by dependencies: "No tasks ready (X tasks blocked by dependencies)"
- Large number of ready tasks: All tasks returned (no arbitrary limits)
- Mixed priority tasks: Returned in appropriate priority/order

### Success Criteria
- [x] **Backward Compatibility**: Default behavior returns single task as before
- [x] **All Flag Functionality**: `--all` flag returns all actionable tasks
- [x] **Consistent Output**: Same formatting standards for single and multiple task output
- [x] **Smart Filtering**: Only ready tasks (no dependency blockers) are included

### Validation Questions
- [x] **Task Readiness**: What exact criteria determine if a task is "ready for work"?
- [x] **Output Format**: Should multiple tasks use JSON, plain text, or structured format?
- [x] **Priority Ordering**: How should multiple tasks be ordered when returned?
- [x] **Performance Impact**: Any concerns with retrieving all tasks for large backlogs?

## Objective

Provide users and automation systems with flexibility to retrieve either a single next task or view all available actionable tasks for better planning and batch processing capabilities while maintaining backward compatibility.

## Scope of Work

### User Experience Scope
- Task retrieval workflow with flag-based behavior control
- Consistent output formatting for single vs multiple task returns
- Clear status reporting for task availability and readiness
- Backward compatibility with existing usage patterns

### System Behavior Scope
- Task filtering logic for dependency and readiness checking
- Flag processing and behavior switching (`--all`, `--limit -1`)
- Output formatting and presentation consistency
- Performance optimization for large task backlogs

### Interface Scope
- `task-manager next` command with enhanced flag support
- Output formatting standards for both single and multiple tasks
- Error messaging for various task availability scenarios
- Alternative flag support (`--limit -1`) for user preference

### Deliverables

#### Behavioral Specifications
- User experience flow definitions for task retrieval options
- System behavior specifications for flag-based workflow switching
- Interface contract definitions for enhanced command functionality

#### Validation Artifacts
- Success criteria validation methods for backward compatibility
- User acceptance criteria for all-task retrieval functionality
- Behavioral test scenarios for various task states and flag combinations

## Phases

1. **Analysis**: Research current CLI command structure and flag handling patterns
2. **Implementation**: Add `--all` option and modify validation logic to support `--limit -1`
3. **Testing**: Update existing tests and add comprehensive test coverage for new functionality
4. **Integration**: Verify compatibility with existing sorting, filtering, and output formatting

## Technical Approach

### Architecture Pattern
- **Pattern**: Extend existing dry-cli command pattern with additional boolean option
- **Integration**: Seamless integration with ATOM architecture - modify existing CLI command organism
- **Impact**: Minimal system impact - purely additive functionality to existing command structure

### Technology Stack
- **Framework**: dry-cli (already in use) for option definition and parsing
- **Validation**: Ruby built-in validation with custom logic for special `-1` case
- **Testing**: RSpec (existing framework) for comprehensive test coverage
- **No new dependencies required**: All functionality implementable with existing stack

### Implementation Strategy
- **Approach**: Additive enhancement preserving full backward compatibility
- **Rollback**: Simple removal of new option and logic - no breaking changes
- **Testing**: Update existing tests + comprehensive new test scenarios
- **Performance**: No performance impact - leverages existing task loading and filtering

## Tool Selection

| Criteria | Boolean Option | Integer Parsing | Special Case | Selected |
|----------|----------------|-----------------|--------------|----------|
| Performance | Excellent | Good | Good | Boolean Option |
| Integration | Excellent | Good | Fair | Boolean Option |
| Maintenance | Excellent | Good | Fair | Boolean Option |
| Security | Excellent | Excellent | Good | Boolean Option |
| Learning Curve | Excellent | Good | Fair | Boolean Option |

**Selection Rationale:** Boolean `--all` option provides the clearest user interface while maintaining full backward compatibility. Special handling for `--limit -1` provides the alternative interface specified in requirements without compromising the primary UX.

### Dependencies
- **No new dependencies required**: Implementation uses existing dry-cli framework capabilities
- **Existing dependencies sufficient**: Ruby stdlib for validation, existing test framework for coverage
- **Compatibility verified**: Solution works within current ATOM architecture patterns

## File Modifications

### Create
- No new files required

### Modify
- dev-tools/lib/coding_agent_tools/cli/commands/task/next.rb
  - Changes: Add `--all` boolean option, modify limit validation to accept `-1`, add flag handling logic
  - Impact: Extends command capability without breaking existing functionality
  - Integration points: Works with existing TaskManager, filtering, sorting, and formatting systems
- dev-tools/spec/coding_agent_tools/cli/commands/task_spec.rb
  - Changes: Update tests that expect `limit: -1` to fail, add comprehensive test coverage for `--all` flag
  - Impact: Ensures reliability and prevents regressions
  - Integration points: Uses existing test infrastructure and mocking patterns

### Delete
- No files to delete

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps
<!-- Research, analysis, and design activities that clarify the technical approach -->
<!-- Use asterisk markers (* [ ]) for activities that don't change system state -->
<!-- Focus on understanding, designing, and preparing for implementation -->

* [x] **Current Implementation Analysis**: Study existing task/next.rb command structure, option definitions, and validation patterns
  > TEST: Understanding Check
  > Type: Pre-condition Analysis
  > Assert: Current dry-cli option patterns and validation logic are understood
  > Command: # Review dev-tools/lib/coding_agent_tools/cli/commands/task/next.rb structure
* [x] **Dry-CLI Option Research**: Research dry-cli boolean option syntax and interaction with existing integer options
  > TEST: Framework Knowledge Check
  > Type: Documentation Review
  > Assert: Optimal approach for adding boolean --all option alongside --limit integer option
  > Command: # Verify dry-cli documentation for boolean + integer option patterns
* [x] **Test Infrastructure Analysis**: Review existing test patterns for CLI commands and validation testing
  > TEST: Test Pattern Understanding
  > Type: Code Review
  > Assert: Test mocking patterns and validation test approaches are clear
  > Command: # Study spec/coding_agent_tools/cli/commands/task_spec.rb testing patterns
* [x] **Output Format Research**: Confirm existing multi-task output formatting handles "all tasks" scenario properly
  > TEST: Output Compatibility Check
  > Type: Behavior Analysis
  > Assert: Existing formatting logic works correctly for unlimited task display
  > Command: # Test task-manager next --limit 10 to verify multi-task output format

### Execution Steps  
<!-- Concrete implementation actions that modify code, create files, or change system state -->
<!-- Use hyphen markers (- [ ]) for actions that result in tangible system changes -->
<!-- Each step should be verifiable and move toward behavioral requirement fulfillment -->

- [x] **Add --all Option Definition**: Add boolean `--all` option to Next command class using dry-cli option syntax
  > TEST: Option Registration
  > Type: CLI Option Validation
  > Assert: --all flag appears in help text and is recognized by command parser
  > Command: task-manager next --help | grep -q "all"
- [x] **Update Validation Logic**: Modify `validate_limit` method to accept `-1` as special unlimited value
  > TEST: Limit Validation Update
  > Type: Method Behavior Validation
  > Assert: validate_limit(-1) returns appropriate unlimited value, positive integers still work
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task_spec.rb -k "limit validation"
- [x] **Implement --all Flag Logic**: Add logic in `call` method to detect `--all` flag and set unlimited limit
  > TEST: Flag Processing Logic
  > Type: Command Logic Validation
  > Assert: --all flag sets appropriate unlimited limit internally
  > Command: # Test internal limit processing with --all flag mock
- [x] **Handle --limit -1 Equivalence**: Ensure `--limit -1` works as equivalent to `--all` per behavioral specification
  > TEST: Limit -1 Equivalence
  > Type: Interface Contract Validation
  > Assert: task-manager next --limit -1 produces same result as task-manager next --all
  > Command: # Compare outputs of both commands to ensure equivalence
- [x] **Update Help Examples**: Add `--all` flag to example usage in command definition
  > TEST: Help Text Update
  > Type: Documentation Validation
  > Assert: Help text includes --all flag example and explains behavior
  > Command: task-manager next --help | grep -q "--all"
- [x] **Update Existing Tests**: Fix tests that expect `limit: -1` to fail since it should now succeed
  > TEST: Test Compatibility
  > Type: Regression Prevention
  > Assert: Existing test suite passes with updated validation logic
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task_spec.rb
- [x] **Add Comprehensive New Tests**: Create test cases for --all flag functionality, edge cases, and integration scenarios
  > TEST: New Feature Coverage
  > Type: Feature Validation
  > Assert: All --all flag scenarios are covered by tests (happy path, edge cases, integration)
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/task_spec.rb -k "--all"

## Risk Assessment

### Technical Risks
- **Risk: Breaking Existing Validation Logic**
  - **Probability:** Medium
  - **Impact:** Medium  
  - **Mitigation:** Careful testing of validate_limit method changes, preserve existing behavior for positive integers
  - **Rollback:** Revert validation method to original state, remove new option
- **Risk: Flag Conflict Handling Issues**
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Clear precedence rules (--all overrides --limit), user-friendly warning messages
  - **Rollback:** Simple flag removal doesn't break existing functionality
- **Risk: Output Format Inconsistencies**
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Leverage existing multi-task formatting logic, comprehensive testing
  - **Rollback:** No changes to existing output formatting code

### Integration Risks
- **Risk: Test Suite Regressions**
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Update existing tests that depend on -1 validation failure, maintain test coverage
  - **Monitoring:** Run full test suite to detect any missed dependencies
- **Risk: CLI Interface Confusion**
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Clear documentation, intuitive flag naming, consistent with existing patterns
  - **Monitoring:** User feedback on new flag usage

### Performance Risks
- **Risk: Large Task List Performance**
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Existing code already handles multiple tasks via --limit, no new performance concerns
  - **Monitoring:** No additional monitoring needed - leverages existing task loading
  - **Thresholds:** No new thresholds required

## Acceptance Criteria

<!-- Define conditions that signify successful implementation of behavioral requirements -->
<!-- These should directly map to success criteria from the behavioral specification -->
<!-- Focus on verifying that behavioral requirements are met, not just implementation completed -->

### Behavioral Requirement Fulfillment
- [x] **User Experience Delivery**: All user experience requirements from behavioral spec are implemented and working
- [x] **Interface Contract Compliance**: All interface contracts function exactly as specified in behavioral requirements  
- [x] **System Behavior Validation**: System demonstrates all expected behaviors defined in behavioral specification

### Implementation Quality Assurance  
- [x] **Code Quality**: All code meets project standards and passes quality checks
- [x] **Test Coverage**: All embedded tests in Implementation Plan pass successfully
- [x] **Integration Verification**: Implementation integrates properly with existing system components
- [x] **Performance Requirements**: System meets any performance criteria specified in behavioral requirements

### Documentation and Validation
- [x] **Behavioral Validation**: Success criteria from behavioral specification are demonstrably met
- [x] **Error Handling**: All error conditions and edge cases handle as specified
- [x] **Documentation Updates**: Any necessary documentation reflects the implemented behavior

## Out of Scope

- ❌ **Implementation Details**: Task filtering algorithm specifics, output formatting code
- ❌ **Technology Decisions**: Data structure choices, performance optimization techniques
- ❌ **Advanced Features**: Complex task sorting, filtering, or management capabilities
- ❌ **UI Enhancements**: Interactive task selection or advanced display formatting

## References

- Original idea file: dev-taskflow/current/v.0.5.0-insights/docs/ideas/044-20250814-0024-task-manager-limit-0.md
- Task management system architecture
- Existing `task-manager next` command patterns