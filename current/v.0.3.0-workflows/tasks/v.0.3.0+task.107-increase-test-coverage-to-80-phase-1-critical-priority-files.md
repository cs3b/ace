---
id: v.0.3.0+task.107
status: pending
priority: high
estimate: 12h
dependencies: []
---

# Increase Test Coverage to 80% - Phase 1 (Critical Priority Files)

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/atoms | sed 's/^/    /'
```

_Result excerpt:_

```
dev-tools/lib/coding_agent_tools/atoms
├── code
├── code_quality
├── directory_scanner.rb
├── docs_dependencies_config_loader.rb
├── git
├── project_root_detector.rb
└── taskflow_management
```

## Objective

Increase test coverage from critically low levels (16-27%) to at least 80% for the 5 most under-tested atom files in the dev-tools Ruby gem. This phase targets the files with the lowest coverage that pose the highest risk to code quality and maintainability.

## Scope of Work

- Implement comprehensive unit tests for 5 critical atom files
- Address 345+ untested lines of code across these files
- Follow TDD principles and ATOM architecture testing patterns
- Ensure robust error handling and edge case coverage

### Deliverables

#### Create

- `dev-tools/spec/coding_agent_tools/atoms/taskflow_management/file_system_scanner_spec.rb` (comprehensive tests)
- `dev-tools/spec/coding_agent_tools/atoms/taskflow_management/yaml_frontmatter_parser_spec.rb` (comprehensive tests)
- `dev-tools/spec/coding_agent_tools/atoms/git/status_color_formatter_spec.rb` (comprehensive tests)
- `dev-tools/spec/coding_agent_tools/atoms/taskflow_management/shell_command_executor_spec.rb` (comprehensive tests)
- `dev-tools/spec/coding_agent_tools/atoms/git/submodule_detector_spec.rb` (comprehensive tests)

#### Modify

- Existing spec files (if any) to achieve comprehensive coverage
- Coverage configuration to track improvements

## Phases

1. Analysis - Review current implementation and identify test gaps
2. Test Design - Plan comprehensive test scenarios for each file
3. Implementation - Write tests following RSpec and project conventions
4. Validation - Verify 80%+ coverage achieved for all target files

## Implementation Plan

### Planning Steps

- [ ] Analyze each target file's current implementation and identify all methods, edge cases, and error paths
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: All methods and code paths are documented for testing
  > Command: cd dev-tools && bundle exec rspec --dry-run --format json | jq '.examples | length'

- [ ] Review existing test patterns in the codebase to maintain consistency
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Testing patterns and conventions are understood
  > Command: cd dev-tools && find spec -name "*_spec.rb" | head -5 | xargs grep -l "describe\|context\|it"

- [ ] Design comprehensive test scenarios covering normal flows, edge cases, and error conditions

### Execution Steps

- [ ] Implement tests for file_system_scanner.rb (16.79% → 80%+)
  - Cover directory scanning, file filtering, and error handling
  - Test recursive vs non-recursive scanning modes
  - Validate pattern matching and exclusion logic
  > TEST: File System Scanner Coverage
  > Type: Coverage Validation
  > Assert: Coverage increased from 16.79% to at least 80%
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/taskflow_management/file_system_scanner_spec.rb && bundle exec rake coverage:check[coding_agent_tools/atoms/taskflow_management/file_system_scanner.rb,80]

- [ ] Implement tests for yaml_frontmatter_parser.rb (21.30% → 80%+)
  - Cover YAML parsing, frontmatter extraction
  - Test malformed YAML handling and validation
  - Validate content separation logic
  > TEST: YAML Parser Coverage
  > Type: Coverage Validation
  > Assert: Coverage increased from 21.30% to at least 80%
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/taskflow_management/yaml_frontmatter_parser_spec.rb && bundle exec rake coverage:check[coding_agent_tools/atoms/taskflow_management/yaml_frontmatter_parser.rb,80]

- [ ] Implement tests for status_color_formatter.rb (22.62% → 80%+)
  - Cover Git status color formatting for different states
  - Test ANSI color code generation and formatting
  - Validate status parsing and categorization
  > TEST: Status Color Formatter Coverage
  > Type: Coverage Validation
  > Assert: Coverage increased from 22.62% to at least 80%
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/git/status_color_formatter_spec.rb && bundle exec rake coverage:check[coding_agent_tools/atoms/git/status_color_formatter.rb,80]

- [ ] Implement tests for shell_command_executor.rb (23.01% → 80%+)
  - Cover command execution, output capture, and error handling
  - Test timeout handling and process management
  - Validate security aspects and command sanitization
  > TEST: Shell Command Executor Coverage
  > Type: Coverage Validation
  > Assert: Coverage increased from 23.01% to at least 80%
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/taskflow_management/shell_command_executor_spec.rb && bundle exec rake coverage:check[coding_agent_tools/atoms/taskflow_management/shell_command_executor.rb,80]

- [ ] Implement tests for submodule_detector.rb (27.16% → 80%+)
  - Cover Git submodule detection and validation
  - Test repository structure analysis
  - Validate submodule status and health checks
  > TEST: Submodule Detector Coverage
  > Type: Coverage Validation
  > Assert: Coverage increased from 27.16% to at least 80%
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/git/submodule_detector_spec.rb && bundle exec rake coverage:check[coding_agent_tools/atoms/git/submodule_detector.rb,80]

- [ ] Run comprehensive test suite and verify overall coverage improvements
  > TEST: Phase 1 Overall Coverage
  > Type: Final Validation
  > Assert: All 5 target files achieve 80%+ coverage
  > Command: cd dev-tools && bundle exec rake coverage:report | grep -E "(file_system_scanner|yaml_frontmatter_parser|status_color_formatter|shell_command_executor|submodule_detector)" | awk '$3 >= 80'

## Acceptance Criteria

- [ ] All 5 target files achieve at least 80% test coverage
- [ ] Tests follow RSpec conventions and project testing patterns
- [ ] All edge cases and error conditions are covered
- [ ] Tests are maintainable and well-documented
- [ ] Coverage reports show measurable improvement from baseline

## Out of Scope

- ❌ Refactoring the implementation files (focus is on testing existing code)
- ❌ Performance optimization of the tested components
- ❌ Integration tests (focus on unit test coverage)
- ❌ Files not in the critical priority list (covered in subsequent phases)

## References

- Current coverage baseline: SimpleCov report showing 16-27% coverage
- ATOM architecture testing guidelines in dev-tools documentation
- Existing RSpec test patterns in dev-tools/spec directory
- Ruby gem testing best practices for security-sensitive components