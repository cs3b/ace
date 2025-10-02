---
name: improve-code-coverage
description: Analyze coverage and create targeted test tasks to improve coverage
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
argument-hint: ""
---

# Improve Code Coverage

## Goal

Systematically analyze code coverage reports and create targeted test tasks to improve overall test coverage by identifying untested code paths, edge cases, and missing test scenarios using quality-focused testing approach.

## Prerequisites

* Coverage report available (SimpleCov `.resultset.json`, Jest coverage, pytest coverage, Go coverage)
* Access to coverage analysis tools
* Understanding of testing patterns and project architecture
* Access to task creation workflows
* Source code access for uncovered line analysis

## Project Context Loading

- Read and follow: `ace-nav wfi://load-project-context`

## Framework Detection

**Auto-detect testing framework and coverage tools:**

**Ruby:**
- Check `Gemfile` for `simplecov`
- Coverage file: `coverage/.resultset.json`
- Tool: SimpleCov

**JavaScript:**
- Check `package.json` for `jest`, coverage scripts
- Coverage file: `coverage/coverage-final.json`
- Tool: Jest coverage, nyc, c8

**Python:**
- Check `requirements.txt` for `pytest-cov`, `coverage`
- Coverage file: `.coverage`, `coverage.xml`
- Tool: pytest-cov, coverage.py

**Go:**
- Coverage file: `coverage.out`
- Tool: `go test -cover`

## Process Steps

1. **Generate Coverage Analysis Report**
   * Ensure tests have been run to generate coverage data:
     ```bash
     # Ruby/RSpec
     bundle exec rspec

     # JavaScript/Jest
     npm test -- --coverage

     # Python/pytest
     pytest --cov=.

     # Go
     go test -coverprofile=coverage.out ./...
     ```

   * Verify coverage data exists:
     ```bash
     # Check for coverage files
     ls -la coverage/ .coverage coverage.out
     ```

2. **Load and Parse Coverage Data**
   * Load the generated coverage report
   * Identify files with low coverage or significant uncovered method groups
   * Focus on files with coverage percentage below adaptive threshold
   * Prioritize files based on:
     - Architecture importance (critical components first)
     - Business logic components
     - Error handling and edge case pathways
     - Public API methods and CLI entry points

3. **Iterative File Analysis Process**
   For each file identified in the coverage report (process 3-5 files per iteration):

   **3.1 Source Code Analysis**
   * Load the source file and examine uncovered line ranges
   * For each uncovered method, analyze:
     - Method signature and parameters
     - Expected inputs and outputs
     - Error conditions and edge cases
     - Dependencies on external systems (file system, network, etc.)
     - Security considerations (path validation, sanitization)

   **3.2 Test Gap Assessment**
   * Review existing test files for the component
   * Identify missing test scenarios:
     - Happy path tests for normal operation
     - Edge cases (empty inputs, boundary conditions)
     - Error conditions (permission errors, invalid paths)
     - Integration scenarios with dependent components
     - Security scenarios (path traversal, injection attempts)

   **3.3 Test Quality Evaluation**
   * Assess current test quality, not just coverage percentage:
     - Are tests testing behavior or just exercising code?
     - Do tests cover meaningful business scenarios?
     - Are error conditions properly tested?
     - Do tests verify edge cases and boundary conditions?
     - Are integration points properly tested?

4. **Test Strategy Design**
   For each file requiring improved coverage:

   **4.1 Edge Case Identification**
   * Identify specific edge cases based on method analysis:
     - Boundary value testing (min/max inputs, empty collections)
     - Error condition testing (network failures, permission errors)
     - State transition testing (object lifecycle scenarios)
     - Concurrency scenarios (if applicable)
     - Resource limitation scenarios (memory, disk space)

   **4.2 Test Scenario Planning**
   * Design comprehensive test scenarios following framework patterns:
     - Logical grouping of related tests
     - Different contexts for different scenarios
     - Mocking/stubbing for external API interactions
     - Shared examples for common behaviors
     - Custom matchers/assertions for domain-specific validation

5. **Task Creation for Test Improvements**
   For each file requiring test improvements:

   * **Create focused test improvement task** using the embedded template
   * **Task should include:**
     - Specific uncovered methods and line ranges
     - Detailed test scenarios to implement
     - Edge cases and error conditions to cover
     - Expected test file structure and organization
     - References to architecture testing patterns
     - Integration requirements with existing test suite

6. **Quality Guidelines and Validation**

   **6.1 Coverage as Attention Indicator**
   * Use coverage data to identify areas needing attention, not as a percentage target
   * Focus on meaningful test scenarios that validate business logic
   * Prioritize quality tests over coverage percentage metrics
   * Ensure tests provide value beyond just exercising code

   **6.2 Test Implementation Standards**
   * Follow framework best practices and project conventions
   * Use appropriate mocking/stubbing for external interactions
   * Implement proper test isolation and cleanup
   * Use factory patterns or fixtures for test data setup
   * Follow project architecture testing patterns for each layer

   **6.3 Continuous Improvement**
   * Re-run coverage analysis after test implementation
   * Validate that new tests provide meaningful scenario coverage
   * Review test execution time and optimize if necessary
   * Update test documentation and examples

## Error Handling

### Common Issues

**Missing Coverage Data:**
* Symptom: No coverage file found
* Solution: Run test suite first to generate coverage data
* Command: Run project-specific test command with coverage enabled

**Coverage Tool Errors:**
* Symptom: Coverage analysis command fails
* Solution: Check tool availability and file permissions
* Verify coverage tool is installed and configured

**Unclear Test Requirements:**
* Symptom: Difficulty determining what tests to write
* Solution: Focus on error conditions and edge cases first
* Approach: Start with simple scenarios, then add complexity

### Recovery Procedures

If analysis fails or produces unclear results:
1. Verify coverage data is current and complete
2. Start with highest-impact files (low coverage + high importance)
3. Focus on one component/file at a time
4. Use incremental approach with regular validation
5. Consult existing test patterns in the codebase

## Success Criteria

* Coverage analysis report generated successfully
* Uncovered code sections identified and analyzed
* Test improvement tasks created for priority components
* Each task includes specific test scenarios and edge cases
* Tasks follow project standards and architecture patterns
* Quality-focused approach prioritizes meaningful tests over coverage percentages
* Integration with existing testing infrastructure

## Usage Example

```bash
# Ruby/SimpleCov
bundle exec rspec
coverage-analyze coverage/.resultset.json

# JavaScript/Jest
npm test -- --coverage
cat coverage/coverage-summary.json

# Python/pytest
pytest --cov=. --cov-report=json
cat coverage.json

# Go
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

## Framework-Specific Coverage Analysis

### Ruby/SimpleCov

```bash
# Run tests with coverage
bundle exec rspec

# View coverage report
open coverage/index.html

# Analyze specific files
bundle exec rspec --coverage-path=lib/specific/path
```

### JavaScript/Jest

```bash
# Run tests with coverage
npm test -- --coverage

# View coverage report
open coverage/lcov-report/index.html

# Coverage for specific files
npm test -- --coverage --collectCoverageFrom='src/**/*.js'
```

### Python/pytest

```bash
# Run tests with coverage
pytest --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html

# Coverage for specific modules
pytest --cov=mymodule --cov-report=term-missing
```

### Go

```bash
# Run tests with coverage
go test -coverprofile=coverage.out ./...

# View coverage report
go tool cover -html=coverage.out

# Function-level coverage
go tool cover -func=coverage.out
```

<documents>
    <template path="dev-handbook/templates/release-testing/task-test-improvement.template.md">---
id: [AUTO-GENERATED]
status: pending
priority: medium
estimate: 3h
dependencies: []
---

# Improve Test Coverage for [ComponentName] - [FocusArea]

## Objective

Implement comprehensive test coverage for [ComponentName] focusing on [FocusArea] including edge cases, error conditions, and integration scenarios. Address uncovered line ranges [LineRanges] identified in coverage analysis.

## Prerequisites

* Understanding of project architecture and testing patterns
* Familiarity with testing framework (RSpec, Jest, pytest, Go testing)
* Access to coverage analysis reports
* Knowledge of mocking/stubbing strategies

## Scope of Work

- Add missing test scenarios for uncovered methods
- Implement edge case testing for boundary conditions
- Add error condition testing for failure scenarios
- Follow testing standards and architecture patterns
- Ensure meaningful test coverage beyond just exercising code

### Deliverables

#### Create
- [test_file_path] (if not exists)

#### Modify
- [test_file_path] (add new test scenarios)

#### Delete
- None

## Implementation Plan

### Planning Steps
* [ ] Analyze source code for [ComponentName] component
* [ ] Review existing test coverage and identify gaps
* [ ] Design test scenarios for uncovered methods: [MethodList]
* [ ] Plan edge case scenarios and error conditions

### Execution Steps
- [ ] Implement happy path tests for uncovered methods
- [ ] Add edge case tests for boundary conditions
- [ ] Implement error condition tests (invalid inputs, system failures)
- [ ] Add integration tests for component interactions
- [ ] Verify test isolation and cleanup procedures
- [ ] Run full test suite to ensure no regressions

## Acceptance Criteria
- [ ] All uncovered methods have meaningful test scenarios
- [ ] Edge cases and error conditions are properly tested
- [ ] Tests follow framework best practices and project conventions
- [ ] Appropriate mocking/stubbing for external interactions
- [ ] Test execution completes without errors
- [ ] Coverage analysis shows improved meaningful coverage

## Test Scenarios

### Uncovered Methods
[List specific methods and line ranges from coverage analysis]

### Edge Cases to Test
- [ ] Boundary value testing (empty/nil inputs, limits)
- [ ] Error condition testing (exceptions, failures)
- [ ] State transition testing (object lifecycle)
- [ ] Resource limitation scenarios
- [ ] Security scenarios (if applicable)

### Integration Scenarios
- [ ] Component interaction testing
- [ ] External dependency mocking/stubbing
- [ ] Cross-layer communication testing

## References
- Coverage analysis report
- Testing standards documentation
- Architecture documentation
- Source file: [SourceFilePath]
</template>
</documents>

---

*This workflow provides a systematic approach to improving test coverage through quality-focused testing strategies that prioritize meaningful test scenarios over coverage percentage metrics.*
