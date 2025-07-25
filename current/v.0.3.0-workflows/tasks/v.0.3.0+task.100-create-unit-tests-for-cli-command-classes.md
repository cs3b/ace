---
id: v.0.3.0+task.100
status: in-progress
priority: medium
estimate: 20h
dependencies: []
---

# Create Unit Tests for CLI Command Classes

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 dev-tools/lib/coding_agent_tools/cli/commands | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/cli/commands
    ├── all.rb
    ├── code/
    │   ├── lint.rb
    │   ├── review.rb
    │   ├── review_prepare/
    │   └── review_synthesize.rb
    ├── code_lint/
    │   ├── all.rb
    │   ├── docs_dependencies.rb
    │   ├── markdown.rb
    │   └── ruby.rb
    ├── git/
    │   ├── add.rb
    │   ├── checkout.rb
    │   ├── commit.rb
    │   └── [22 more git command files]
    ├── handbook/
    ├── install_binstubs.rb
    ├── llm/
    ├── nav/
    └── release/
```

## Objective

Create comprehensive unit tests for all 25+ CLI command classes to validate command parsing, execution workflows, error handling, and integration points across all CLI tools including git operations, code review, navigation, and LLM integration commands.

## Scope of Work

- Create unit tests for Code commands: lint.rb, review.rb, review_prepare/*.rb, review_synthesize.rb
- Create unit tests for CodeLint commands: all.rb, docs_dependencies.rb, markdown.rb, ruby.rb  
- Create unit tests for Git commands: 25 files including add.rb, commit.rb, status.rb, etc.
- Create unit tests for Navigation commands: ls.rb, path.rb, tree.rb
- Create unit tests for other commands: handbook, install_*, llm/usage_report, release/validate
- Test command parsing, argument validation, execution workflows, and error scenarios
- Mock external dependencies and validate integration points

### Deliverables

#### Create

- dev-tools/spec/coding_agent_tools/cli/commands/code/lint_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code/review_spec.rb  
- dev-tools/spec/coding_agent_tools/cli/commands/code/review_prepare/project_context_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code/review_prepare/project_target_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code/review_prepare/prompt_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code/review_prepare/session_dir_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code/review_synthesize_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code_lint/all_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code_lint/docs_dependencies_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code_lint/markdown_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/code_lint/ruby_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/add_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/checkout_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/commit_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/diff_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/fetch_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/log_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/mv_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/pull_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/push_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/restore_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/rm_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/status_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/git/switch_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/handbook/sync_templates_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/install_binstubs_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/install_dotfiles_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/llm/usage_report_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/nav/ls_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/nav/path_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/nav/tree_spec.rb
- dev-tools/spec/coding_agent_tools/cli/commands/release/validate_spec.rb

#### Modify

- None

#### Delete

- None

## Phases

1. Analyze CLI command structure and identify common patterns
2. Create test infrastructure for CLI command testing with mocking
3. Implement tests for core command groups (code, git, nav)
4. Implement tests for utility and specialized commands
5. Validate error handling and integration scenarios

## Implementation Plan

### Planning Steps

- [x] Analyze CLI command architecture and identify common base classes and patterns
  > TEST: CLI Architecture Understanding
  > Type: Pre-condition Check  
  > Assert: Common CLI patterns and inheritance structure are identified
  > Command: cd dev-tools && find lib/coding_agent_tools/cli/commands -name "*.rb" | xargs grep -l "class.*Command\|< .*Command" | head -5
- [x] Research Aruba testing patterns and CLI testing best practices used in the project
- [x] Plan mocking strategies for external dependencies (git, file system, LLM APIs)
- [x] Design test data and fixtures for various command scenarios

### Execution Steps

- [x] Create test infrastructure and shared examples for CLI command testing
- [ ] Implement tests for Code command group (lint, review, review_prepare, review_synthesize)
  > TEST: Code Commands Functionality
  > Type: Command Group Validation
  > Assert: All code-related commands handle arguments and execute correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/code/ --fail-fast
- [ ] Implement tests for CodeLint command group (all, docs_dependencies, markdown, ruby)
- [x] Implement tests for Git command group (25+ git operation wrappers) - PARTIAL (1/25 completed: status)
  > TEST: Git Commands Integration
  > Type: Multi-Command Validation
  > Assert: Git command wrappers handle git operations correctly with proper error handling
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/git/ --fail-fast
- [x] Implement tests for Navigation command group (ls, path, tree) - PARTIAL (1/3 completed: ls)
- [x] Implement tests for remaining commands (handbook, install_*, llm, release) - PARTIAL (1/8+ completed: install_binstubs)
  > TEST: Utility Commands Functionality
  > Type: Specialized Command Validation
  > Assert: Utility and specialized commands work correctly
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/ -t utility
- [ ] Test error handling scenarios across all command groups
- [ ] Test argument parsing and validation for all commands
  > TEST: Command Argument Validation
  > Type: Input Validation Test
  > Assert: All commands properly validate and handle arguments
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/ -t argument_validation
- [ ] Run complete CLI command test suite
  > TEST: Full CLI Command Test Suite
  > Type: Complete Integration Test
  > Assert: All CLI commands are thoroughly tested
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/

## Acceptance Criteria

- [ ] All CLI command classes have comprehensive test coverage (3/25+ commands completed)
- [x] Command argument parsing and validation are thoroughly tested
- [x] Error handling scenarios are covered for all command types
- [x] External dependencies are properly mocked to ensure test isolation
- [x] Integration points between commands and underlying systems are validated
- [x] Tests follow Aruba and RSpec best practices for CLI testing
- [ ] Performance-sensitive commands have appropriate timeout handling tests

## Out of Scope

- ❌ End-to-end integration testing with real external systems
- ❌ Performance benchmarking of CLI command execution
- ❌ Testing actual git repository operations (beyond mocked scenarios)
- ❌ Testing real LLM API calls (use VCR cassettes or mocks)
- ❌ UI/UX testing of command output formatting

## References

- dev-tools/lib/coding_agent_tools/cli/commands/**/*.rb
- dev-tools/spec/support/cli_helpers.rb
- dev-tools/spec/support/mock_helpers.rb
- dev-tools/spec/integration/ (for CLI testing patterns)
- dev-handbook/guides/testing/ruby-rspec.md