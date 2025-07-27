---
id: v.0.3.0+task.130
status: pending
priority: medium
estimate: 6h
dependencies: []
---

# Clean up RSpec output pollution in test suite

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/spec | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/spec
    ├── cassettes
    ├── coding_agent_tools
    ├── integration
    ├── spec_helper.rb
    ├── support
    └── unit
```

## Objective

Eliminate noise and pollution in RSpec test output to improve test readability, developer experience, and CI/CD log clarity. The current test suite produces significant stdout/stderr pollution including warnings, debug messages, and configuration errors that obscure actual test results and failures.

## Scope of Work

- Fix RSpec `raise_error` matcher warnings by specifying exception types
- Suppress configuration loading warnings during tests
- Gate debug output to prevent leakage during test runs
- Improve output capture in command tests
- Route error messages to proper channels (stderr vs stdout)

### Deliverables

#### Modify

- spec/coding_agent_tools/atoms/git/log_color_formatter_spec.rb
- spec/coding_agent_tools/atoms/docs_dependencies_config_loader_spec.rb (multiple lines)
- lib/coding_agent_tools/atoms/docs_dependencies_config_loader.rb
- lib/coding_agent_tools/cli/commands/install_dotfiles.rb
- spec/coding_agent_tools/cli/commands/install_dotfiles_spec.rb
- spec/coding_agent_tools/cli/commands/code/review_prepare/session_dir_spec.rb
- spec/coding_agent_tools/cli/commands/code_lint/ruby_spec.rb
- spec/coding_agent_tools/cli/commands/code_lint/markdown_spec.rb
- spec/coding_agent_tools/ecosystems_spec.rb

## Phases

1. Audit - Categorize all sources of output pollution
2. Fix RSpec warnings - Update tests to use specific exception types
3. Suppress config warnings - Add test environment detection
4. Gate debug output - Add environment checks around debug statements
5. Improve output handling - Ensure proper stdout/stderr separation

## Implementation Plan

### Planning Steps

- [x] Analyze current test output to identify pollution sources
  > TEST: Output Analysis Complete
  > Type: Pre-condition Check
  > Assert: All 5 categories of pollution are documented with file locations
  > Command: rspec --dry-run | grep -E "(WARNING|Warning|Error:|Debug:|Created)"
- [ ] Research RSpec best practices for output suppression
- [ ] Plan logger integration strategy for proper output routing

### Execution Steps

#### Category 1: Fix RSpec `raise_error` Warnings (5 instances)

- [ ] Fix `log_color_formatter_spec.rb:322` - specify `raise_error(NoMethodError)`
  > TEST: Verify RSpec Warning Removed
  > Type: Action Validation  
  > Assert: No "Using the `raise_error` matcher without providing a specific error" warning for this file
  > Command: rspec spec/coding_agent_tools/atoms/git/log_color_formatter_spec.rb:322 2>&1 | grep -v "WARNING.*raise_error"

- [ ] Fix `docs_dependencies_config_loader_spec.rb:805` - specify `raise_error(RuntimeError)` for validation errors
  > TEST: Verify Validation Error Specifications
  > Type: Action Validation
  > Assert: All `raise_error` calls specify expected exception types
  > Command: rspec spec/coding_agent_tools/atoms/docs_dependencies_config_loader_spec.rb:805 2>&1 | grep -v "WARNING.*raise_error"

- [ ] Fix `docs_dependencies_config_loader_spec.rb:564` - specify `raise_error(RuntimeError)` for array validation
- [ ] Review all 82 files with `raise_error` usage for similar issues
- [ ] Update any remaining generic `raise_error` calls to specify exception types

#### Category 2: Suppress Configuration Loading Warnings (6 instances)

- [ ] Modify `docs_dependencies_config_loader.rb` lines 48-49 to detect test environment
  > TEST: Verify Warning Suppression in Tests
  > Type: Action Validation
  > Assert: No "Warning: Failed to load config" messages appear during test runs
  > Command: rspec spec/coding_agent_tools/atoms/docs_dependencies_config_loader_spec.rb 2>&1 | grep -v "Warning.*Failed to load config"

- [ ] Replace `warn` calls with conditional logger or test-aware output
- [ ] Ensure warnings still appear in production/development environments

#### Category 3: Gate Debug Output (2 instances)

- [ ] Add test environment check to `install_dotfiles.rb` debug output
  > TEST: Verify Debug Output Gating
  > Type: Action Validation
  > Assert: No "Debug: Project root:" messages during test runs
  > Command: rspec spec/coding_agent_tools/cli/commands/install_dotfiles_spec.rb 2>&1 | grep -v "Debug:"

- [ ] Wrap debug statements in environment-aware conditionals
- [ ] Ensure debug output is available when explicitly requested

#### Category 4: Improve Test Output Capture (2 instances)

- [ ] Update `install_dotfiles_spec.rb` to properly capture "Created directory:" output
  > TEST: Verify Output Capture
  > Type: Action Validation
  > Assert: No "Created directory:" messages leak to test output
  > Command: rspec spec/coding_agent_tools/cli/commands/install_dotfiles_spec.rb 2>&1 | grep -v "Created directory"

- [ ] Review other command tests for similar output leakage
- [ ] Implement consistent output capture patterns

#### Category 5: Route Error Messages Properly (2 instances)

- [ ] Review error message routing in test files
- [ ] Ensure error messages use stderr instead of stdout where appropriate
- [ ] Update error handling to use proper logging framework

#### Final Validation

- [ ] Run full test suite and verify clean output
  > TEST: Complete Output Cleanup Verification
  > Type: Integration Test
  > Assert: RSpec output contains no pollution warnings or unwanted messages
  > Command: rspec 2>&1 | grep -E "(WARNING|Warning|Error.*undefined method|Debug.*Project root|Created directory)" | wc -l | test $(cat) -eq 0

## Acceptance Criteria

- [ ] AC 1: RSpec runs produce clean output with no warnings or pollution
- [ ] AC 2: All existing tests continue to pass with same behavior
- [ ] AC 3: Debug output only appears when explicitly enabled via environment variables
- [ ] AC 4: Configuration warnings are suppressed in test environment but preserved in production
- [ ] AC 5: Error messages are properly routed to stderr instead of stdout where appropriate

## Out of Scope

- ❌ Refactoring test structure or organization
- ❌ Adding new test coverage (focus is on cleanup only)
- ❌ Changing test frameworks or major testing infrastructure
- ❌ Performance optimization of test suite

## References

- RSpec documentation on `raise_error` matcher best practices
- Ruby testing conventions for output handling
- Project logging standards and environment detection patterns
- Previous VCR configuration fixes as reference for test environment handling