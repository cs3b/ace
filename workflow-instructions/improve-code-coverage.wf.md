# Improve Code Coverage

## Goal

Systematically analyze code coverage reports and create targeted test tasks to improve overall test coverage by identifying untested code paths, edge cases, and missing test scenarios using quality-focused testing approach.

## Prerequisites

* SimpleCov coverage report available in `.resultset.json` format
* Access to coverage-analyze tool from dev-tools
* Understanding of Ruby/RSpec/VCR testing patterns and ATOM architecture
* Access to draft-task workflow for generating test improvement tasks
* Source code access for uncovered line analysis

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`
* Load tools documentation: `docs/tools.md`
* Load testing standards: `dev-tools/docs/development/guides/testing-with-vcr.md`
* Load ATOM architecture reference: `docs/architecture-tools.md`

## Process Steps

1. **Generate Coverage Analysis Report**
   * Ensure tests have been run to generate coverage data:
     ```bash
     cd dev-tools && # Run project-specific test command spec/
     ```
   * Delete old coverage analysis report:
     ```bash
     rm coverage_analysis/coverage_analysis.json
     ```
   * Generate comprehensive coverage analysis report:
     ```bash
     coverage-analyze coverage/.resultset.json
     ```
   * Verify JSON report exists and is current:
     ```bash
     ls -la ./coverage_analysis/coverage_analysis.json
     ```

2. **Load and Parse Coverage Data**
   * Load the generated JSON coverage report:
     ```bash
     cat ./coverage_analysis/coverage_analysis.json
     ```
   * Identify files with low coverage or significant uncovered method groups
   * Focus on files with coverage percentage below adaptive threshold
   * Prioritize files based on:
     - Architecture importance (ATOM layer: Atoms > Molecules > Organisms > Ecosystems)
     - Critical business logic components
     - Error handling and edge case pathways
     - Public API methods and CLI entry points

3. **Iterative File Analysis Process**
   For each file identified in the coverage report (process 3-5 files per iteration):

   **3.1 Source Code Analysis**
   * Load the source file and examine uncovered line ranges:
   * For each uncovered method, analyze:
     - Method signature and parameters
     - Expected inputs and outputs
     - Error conditions and edge cases
     - Dependencies on external systems (file system, network, etc.)
     - Security considerations (path validation, sanitization)

   **3.2 Test Gap Assessment**
   * Review existing test files for the component:
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
   * Design comprehensive test scenarios following RSpec patterns:
     - Describe blocks for logical grouping
     - Context blocks for different scenarios
     - VCR cassettes for external API interactions
     - Shared examples for common behaviors
     - Custom matchers for domain-specific assertions

5. **Task Creation for Test Improvements**
   For each file requiring test improvements:

   * **Create focused test improvement task:**
     Use `create-path` to create starting file:
     ```bash
     task-manager create --title "Improve test coverage for [FileName] - [SpecificFocus]" --priority medium --estimate "3h"
     ```

   * **Task should include:**
     - Specific uncovered methods and line ranges
     - Detailed test scenarios to implement
     - Edge cases and error conditions to cover
     - Expected test file structure and organization
     - References to ATOM architecture testing patterns
     - Integration requirements with existing test suite

6. **Quality Guidelines and Validation**

   **6.1 Coverage as Attention Indicator**
   * Use coverage data to identify areas needing attention, not as a percentage target
   * Focus on meaningful test scenarios that validate business logic
   * Prioritize quality tests over coverage percentage metrics
   * Ensure tests provide value beyond just exercising code

   **6.2 Test Implementation Standards**
   * Follow RSpec best practices and project conventions
   * Use VCR for external API interactions and HTTP requests
   * Implement proper test isolation and cleanup
   * Use factory patterns or fixtures for test data setup
   * Follow ATOM architecture testing patterns for each layer

   **6.3 Continuous Improvement**
   * Re-run coverage analysis after test implementation
   * Validate that new tests provide meaningful scenario coverage
   * Review test execution time and optimize if necessary
   * Update test documentation and examples

## Error Handling

### Common Issues

**Missing Coverage Data:**
* Symptom: No `.resultset.json` file found
* Solution: Run test suite first to generate coverage data
* Command: `cd dev-tools && # Run project-specific test command`

**Coverage Tool Errors:**
* Symptom: coverage-analyze command fails
* Solution: Check tool availability and file permissions
* Command: `ls -la dev-tools/exe/coverage-analyze`

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
* Tasks follow project standards and ATOM architecture patterns
* Quality-focused approach prioritizes meaningful tests over coverage percentages
* Integration with existing Ruby/RSpec/VCR testing infrastructure

## Usage Example

```bash
# Generate comprehensive coverage analysis
cd dev-tools && # Run project-specific test command
coverage-analyze coverage/.resultset.json --comprehensive --detailed

# Create test improvement task for a specific component
task-manager create --title "Improve test coverage for DirectoryCreator - error handling and edge cases" --priority medium --estimate "3h"

# Analyze specific file patterns
coverage-analyze coverage/.resultset.json --focus "**/atoms/**" --max-files 5
```

## Templates

<template path="task-test-improvement.md" description="Task template for test coverage improvements">
---
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

* Read the dev-tools technical architecture guide: `dev-tools/docs/architecture-tools.md`
* Understanding of ATOM architecture pattern (Atoms, Molecules, Organisms, Ecosystems)
* Familiarity with Ruby/RSpec testing patterns and VCR cassette management

## Scope of Work

- Add missing test scenarios for uncovered methods
- Implement edge case testing for boundary conditions
- Add error condition testing for failure scenarios
- Follow Ruby/RSpec/VCR testing standards and ATOM architecture patterns
- Ensure meaningful test coverage beyond just exercising code

### Deliverables

#### Create
- spec/[path]/[component_name]_spec.rb (if not exists)

#### Modify
- spec/[path]/[component_name]_spec.rb (add new test scenarios)

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
- [ ] Tests follow RSpec best practices and project conventions
- [ ] VCR cassettes used for external interactions
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
- [ ] Cross-layer communication (ATOM architecture)

## References
- Coverage analysis: coverage_analysis/coverage_analysis.json
- Testing standards: dev-tools/docs/development/guides/testing-with-vcr.md
- ATOM architecture: docs/architecture-tools.md
- Source file: [SourceFilePath]
</template>

---

*This workflow provides a systematic approach to improving test coverage through quality-focused testing strategies that prioritize meaningful test scenarios over coverage percentage metrics.*
