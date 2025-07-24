---
id: task.83
status: pending
priority: medium
estimate: 7h
dependencies: [task.79, task.80, task.81, task.82]
---

# Implement unit tests for CLI Commands Core Operations

## Objective

Implement comprehensive unit tests for 12 core CLI command components covering code operations, navigation, system integration, and utility commands. These components require testing of command-line argument parsing, user interaction patterns, and integration with underlying atoms/molecules.

**Target Coverage**: 85% for each component (lower due to CLI complexity and user interaction)
**Estimated Effort**: 7 hours
**Files to Test**: 12 files (1,347 relevant lines total)

## Scope of Work

### Files to Test

#### Code Operations Commands (8 files)
- `lib/coding_agent_tools/cli/commands/code/lint.rb` (41 lines) - Code linting command
- `lib/coding_agent_tools/cli/commands/code/review.rb` (155 lines) - Interactive code review
- `lib/coding_agent_tools/cli/commands/code/review_prepare/project_context.rb` (54 lines) - Review context preparation
- `lib/coding_agent_tools/cli/commands/code/review_prepare/project_target.rb` (45 lines) - Review target selection
- `lib/coding_agent_tools/cli/commands/code/review_prepare/prompt.rb` (90 lines) - Review prompt generation
- `lib/coding_agent_tools/cli/commands/code/review_prepare/session_dir.rb` (42 lines) - Session directory management
- `lib/coding_agent_tools/cli/commands/code/review_synthesize.rb` (153 lines) - Review synthesis
- `lib/coding_agent_tools/cli/commands/code_lint/all.rb` (63 lines) - Comprehensive linting

#### Navigation and System Commands (4 files)
- `lib/coding_agent_tools/cli/commands/nav.rb` (8 lines) - Navigation command entry point
- `lib/coding_agent_tools/cli/commands/nav/ls.rb` (121 lines) - Enhanced directory listing
- `lib/coding_agent_tools/cli/commands/nav/path.rb` (80 lines) - Path operations and resolution
- `lib/coding_agent_tools/cli/commands/nav/tree.rb` (141 lines) - Directory tree visualization

## Implementation Plan

### Planning Steps

- [ ] Analyze CLI command patterns and argument parsing logic
- [ ] Create test fixtures for various command-line scenarios and user inputs
- [ ] Design mocking strategies for underlying business logic components
- [ ] Plan testing for interactive vs non-interactive command execution

### Execution Steps

#### Phase 1: Code Review Commands (3h)

- [ ] Implement comprehensive tests for `code/review.rb`
  - Test interactive and batch review modes
  - Test argument parsing and validation
  - Test integration with review preparation and synthesis
  - Test error handling and user guidance
  - Mock underlying review orchestration components
  - Test output formatting and user feedback

- [ ] Implement comprehensive tests for review preparation commands
  - Test `project_context.rb` context loading and validation
  - Test `project_target.rb` target selection and filtering
  - Test `prompt.rb` prompt generation and customization
  - Test `session_dir.rb` directory creation and management
  - Mock file system operations and project scanning
  - Test error handling for missing or invalid inputs

- [ ] Implement comprehensive tests for `review_synthesize.rb`
  - Test synthesis of multiple review sessions
  - Test output format options and customization
  - Test integration with LLM providers for synthesis
  - Test handling of large review datasets
  - Mock LLM API calls and synthesis orchestration

#### Phase 2: Linting Commands (2h)

- [ ] Implement comprehensive tests for `code/lint.rb`
  - Test linting execution with various options
  - Test integration with multiple linting tools
  - Test error reporting and result aggregation
  - Test autofix functionality and validation
  - Mock underlying linting atoms and molecules
  - Test performance with large codebases

- [ ] Implement comprehensive tests for `code_lint/all.rb`
  - Test comprehensive linting across multiple languages
  - Test parallel execution and coordination
  - Test result compilation and reporting
  - Test configuration loading and customization
  - Mock individual linting components
  - Test error aggregation and prioritization

#### Phase 3: Navigation Commands (2h)

- [ ] Implement comprehensive tests for navigation commands
  - Test `nav.rb` command routing and delegation
  - Test `nav/ls.rb` enhanced directory listing with filters
  - Test `nav/path.rb` path resolution and operations
  - Test `nav/tree.rb` directory tree generation and visualization
  - Mock file system operations and project structure
  - Test output formatting and customization options

- [ ] Test cross-platform compatibility and edge cases
  - Test with various directory structures and permissions
  - Test with symbolic links and special files
  - Test performance with large directory trees
  - Test error handling for inaccessible directories

## Testing Patterns and Requirements

### CLI Command Testing
```ruby
# Use CLI helpers for direct command testing
include CliHelpers

it "executes command with correct arguments" do
  result = execute_cli_command("code-lint", ["--all", "--fix"])
  expect(result.success?).to be true
  expect(result.stdout).to include("Linting completed")
end
```

### Argument Parsing Testing
```ruby
# Test various argument combinations
context "with valid arguments" do
  it "parses options correctly" do
    command = described_class.new
    result = command.call(["--interactive", "--output", "report.json"])
    expect(result).to eq(0)
  end
end

context "with invalid arguments" do
  it "shows help and returns error code" do
    command = described_class.new
    result = command.call(["--invalid-option"])
    expect(result).to eq(1)
  end
end
```

### Interactive Command Testing
```ruby
# Mock user input for interactive commands
before do
  allow($stdin).to receive(:gets).and_return("y\n", "continue\n")
  allow($stdout).to receive(:puts)
end
```

### Integration Testing
- Test command integration with underlying atoms/molecules
- Test proper error propagation from lower layers
- Test output formatting and user experience
- Test help text generation and consistency

## Deliverables

### Test Files to Create (12 files)
- `spec/coding_agent_tools/cli/commands/code/lint_spec.rb`
- `spec/coding_agent_tools/cli/commands/code/review_spec.rb`
- `spec/coding_agent_tools/cli/commands/code/review_prepare/project_context_spec.rb`
- `spec/coding_agent_tools/cli/commands/code/review_prepare/project_target_spec.rb`
- `spec/coding_agent_tools/cli/commands/code/review_prepare/prompt_spec.rb`
- `spec/coding_agent_tools/cli/commands/code/review_prepare/session_dir_spec.rb`
- `spec/coding_agent_tools/cli/commands/code/review_synthesize_spec.rb`
- `spec/coding_agent_tools/cli/commands/code_lint/all_spec.rb`
- `spec/coding_agent_tools/cli/commands/nav_spec.rb`
- `spec/coding_agent_tools/cli/commands/nav/ls_spec.rb`
- `spec/coding_agent_tools/cli/commands/nav/path_spec.rb`
- `spec/coding_agent_tools/cli/commands/nav/tree_spec.rb`

## Acceptance Criteria

- [ ] All 12 CLI command components have comprehensive unit tests with 85%+ coverage
- [ ] Command-line argument parsing is thoroughly tested with valid and invalid inputs
- [ ] Interactive command flows are tested with mocked user input
- [ ] Integration with underlying business logic is properly mocked and validated
- [ ] Error handling and user feedback are comprehensively tested
- [ ] Help text and usage information are validated
- [ ] Output formatting is consistent and properly tested
- [ ] Performance with large datasets and directories is validated

## Dependencies

- **task.79**: Infrastructure and shared helpers must be completed
- **task.80-82**: Lower layer atoms must be available for mocking
- **CLI helpers**: Direct command invocation testing utilities
- **Mock user input**: Strategies for testing interactive commands

## Success Metrics

- **Coverage Target**: 85% line coverage for all 12 components
- **Test Count**: 12-20 test cases per component (144-240 total)
- **Performance**: Test suite completes in < 40 seconds
- **User Experience**: All help text, error messages, and interactive flows tested
- **Integration**: Proper mocking of all underlying business logic components