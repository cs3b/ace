---
id: v.0.8.0+task.012
status: pending
priority: high
estimate: 8h
dependencies: [v.0.8.0+task.001]
---

# Implement Agent-Friendly Test Reporter

## Behavioral Specification

### User Experience
- **Input**: Running tests via `rake test` or `bin/test` commands with standard Minitest suite
- **Process**: Tests execute with compact, scannable output showing group statistics and minimal failure details, while generating detailed reports in background
- **Output**: Two-line-max failure summaries in console plus timestamped detailed reports in `test-report/` directory

### Expected Behavior

The test reporter provides a compact, agent-optimized console output that works for any Minitest project (ATOM architecture or generic). During test execution, users see grouped test statistics with clear pass/fail/skip counts and execution times. Failures are displayed in a highly condensed format (max 2 lines each) showing file:line location and the core error message.

Simultaneously, the reporter generates comprehensive error reports in a timestamped directory structure, providing full stack traces, assertion details, diffs, and code context in separate files. This dual approach gives agents and humans quick feedback while preserving all debugging information.

The reporter auto-detects project structure (ATOM layers, Rails conventions, or generic directories) and groups tests accordingly. It requires zero configuration to work but allows customization via optional `.test-reporter.yml` file.

### Interface Contract

```bash
# CLI Usage (automatic with ace tools)
rake test           # Uses agent reporter by default
bin/test atoms      # Groups by ATOM layers if detected
bin/test unit       # Works with any test organization

# Output Format
═══════════════════════════════════════════════════════════════════
ATOMS       : ✓ 23  ✗ 2  ⊘ 1  (0.45s)
MOLECULES   : ✓ 45  ✗ 0  ⊘ 0  (1.23s)
ORGANISMS   : ✓ 12  ✗ 1  ⊘ 0  (2.10s)
───────────────────────────────────────────────────────────────────
FAILURES (3):
  test/unit/atoms/path_test.rb:15 :: expected "/path" got "/other"
  test/unit/atoms/json_test.rb:42 :: JSON::ParserError
  test/unit/organisms/flow_test.rb:8 :: NoMethodError: undefined `call`
───────────────────────────────────────────────────────────────────
Details: test-report/20250917-134522/
═══════════════════════════════════════════════════════════════════

# Generated Report Structure
test-report/
└── 20250917-134522/
    ├── summary.txt          # Console output copy
    ├── summary.json         # Machine-readable stats
    ├── failures.json        # Structured failure data
    └── failures/
        ├── 001-path_test.md      # Full error details
        └── 002-json_test.md      # Stack trace, diff, context
```

**Error Handling:**
- Missing test directories: Falls back to generic test grouping
- No tests found: Reports "No tests found" with helpful suggestions
- Reporter conflicts: Warns if multiple reporters configured

**Edge Cases:**
- Projects without ATOM structure: Groups by directory names
- Rails projects: Detects and groups by Rails conventions
- Single test file: Shows as "TESTS" group
- Parallel test execution: Thread-safe report generation

### Success Criteria

- [ ] **Compact Output**: Console shows max 2 lines per failure with file:line and error summary
- [ ] **Auto-Detection**: Reporter automatically detects and groups tests by project structure
- [ ] **Detailed Reports**: Full error details saved in timestamped test-report directories
- [ ] **Zero Configuration**: Works out-of-box with any Minitest project
- [ ] **Independent Module**: No dependencies on other ace_tools code
- [ ] **Reusable**: Can be used in any project that includes ace_tools

### Validation Questions

- [ ] **Report Retention**: Should old reports be auto-cleaned? Currently planning to keep last 10 runs
- [ ] **JSON Format**: What specific fields should the JSON output contain for agent parsing?
- [ ] **Group Names**: Should group names be configurable or always auto-detected?
- [ ] **Color Output**: Should color codes be included or stripped for agent consumption?

## Objective

Provide a test reporter optimized for coding agents and automation that balances minimal console output with comprehensive error tracking, making test failures easy to scan and debug.

## Scope of Work

- **User Experience Scope**: Test execution feedback for both agents and human developers
- **System Behavior Scope**: Minitest reporter that generates dual output (console + files)
- **Interface Scope**: Drop-in replacement for standard Minitest reporters

### Deliverables

#### Behavioral Specifications
- Compact console output format specification
- Detailed report file structure definition
- Auto-detection logic for project structures

#### Validation Artifacts
- Example outputs for different project types
- JSON schema for machine-readable formats
- Configuration file format specification

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby class structures or file organization
- ❌ **Technology Decisions**: Choice of diff libraries or formatting gems
- ❌ **Performance Optimization**: Specific caching or optimization strategies
- ❌ **Future Enhancements**: HTML reports, CI integrations, web dashboards

## Technical Approach

### Architecture Pattern
- [x] Independent module design with zero ace_tools dependencies
- [x] Minitest::Reporter inheritance for integration
- [x] Strategy pattern for group detection and formatting
- [x] Builder pattern for report generation

### Technology Stack
- [x] Pure Ruby implementation (no external gem dependencies)
- [x] Minitest hooks for test lifecycle integration
- [x] JSON standard library for machine-readable output
- [x] FileUtils for report directory management

### Implementation Strategy
- [x] Start with minimal AgentReporter class
- [x] Add group detection logic incrementally
- [x] Build report generation separately
- [x] Test with real ace_tools test suite

## File Modifications

### Create
- lib/ace_tools/test_reporter.rb
  - Main module entry point
  - Configuration loading
  - Public API

- lib/ace_tools/test_reporter/agent_reporter.rb
  - Core Minitest::Reporter subclass
  - Compact console output logic
  - Test result collection

- lib/ace_tools/test_reporter/group_detector.rb
  - Auto-detection of project structure
  - ATOM/Rails/generic pattern matching
  - Configuration file support

- lib/ace_tools/test_reporter/report_generator.rb
  - Timestamped directory creation
  - Detailed failure report generation
  - JSON summary creation

- lib/ace_tools/test_reporter/formatters/compact_formatter.rb
  - Two-line failure formatting
  - Group statistics formatting
  - Console output helpers

- lib/ace_tools/test_reporter/formatters/json_formatter.rb
  - Machine-readable JSON generation
  - Structured failure data
  - Statistics export

- lib/ace_tools/test_reporter/formatters/markdown_formatter.rb
  - Detailed failure reports
  - Stack trace formatting
  - Code context extraction

- lib/ace_tools/test_reporter/configuration.rb
  - Config file loading (.test-reporter.yml)
  - Default settings
  - Environment variable support

### Modify
- test/test_helper.rb
  - Replace current reporters with AgentReporter
  - Add configuration for agent mode
  - Preserve backward compatibility option

- Gemfile
  - Ensure minitest-reporters is available
  - No new gem dependencies needed

## Implementation Plan

### Planning Steps

* [x] **Research Minitest Reporter API**: Understand hooks and lifecycle
* [x] **Analyze existing reporters**: Study minitest-reporters gem patterns
* [x] **Design module structure**: Plan zero-dependency architecture
* [x] **Define output formats**: Specify exact console and file formats

### Execution Steps

- [ ] **Create module structure**: Setup lib/ace_tools/test_reporter/ directory
  > TEST: Module Structure
  > Type: Directory Check
  > Assert: test_reporter module exists with subdirectories
  > Command: test -d lib/ace_tools/test_reporter && ls lib/ace_tools/test_reporter/

- [ ] **Implement AgentReporter core**: Create basic Minitest::Reporter subclass
  > TEST: Reporter Loading
  > Type: Ruby Require
  > Assert: AgentReporter class loads without errors
  > Command: ruby -r ./lib/ace_tools/test_reporter -e "puts AceTools::TestReporter::AgentReporter"

- [ ] **Add group detection**: Implement smart project structure detection
  > TEST: Group Detection
  > Type: Detection Logic
  > Assert: Correctly identifies ATOM/Rails/generic structures
  > Command: ruby -r ./lib/ace_tools/test_reporter -e "p AceTools::TestReporter::GroupDetector.new.detect_groups"

- [ ] **Implement compact formatter**: Create two-line failure formatting
  > TEST: Compact Output
  > Type: Format Check
  > Assert: Failures display in max 2 lines
  > Command: echo "test output" | grep -c "^  test.*::[^\\n]*$"

- [ ] **Add report generation**: Create timestamped detailed reports
  > TEST: Report Generation
  > Type: File Creation
  > Assert: Reports created in test-report directory
  > Command: test -d test-report/*/failures && echo "Reports generated"

- [ ] **Implement JSON output**: Add machine-readable formats
  > TEST: JSON Validity
  > Type: JSON Parse
  > Assert: Generated JSON is valid and complete
  > Command: cat test-report/*/summary.json | ruby -r json -e "JSON.parse(STDIN.read)"

- [ ] **Add configuration support**: Enable .test-reporter.yml loading
  > TEST: Config Loading
  > Type: Configuration Check
  > Assert: Reads and applies configuration file
  > Command: echo "mode: agent" > .test-reporter.yml && ruby -e "require './lib/ace_tools/test_reporter'; p AceTools::TestReporter.config.mode"

- [ ] **Update test helper**: Integrate with ace_tools test suite
  > TEST: Integration
  > Type: Test Execution
  > Assert: Tests run with new reporter
  > Command: bin/test atoms 2>&1 | grep -q "ATOMS"

- [ ] **Add gitignore entry**: Ensure test-report/ is ignored
  > TEST: Git Ignore
  > Type: File Check
  > Assert: test-report/ in .gitignore
  > Command: grep -q "^test-report/" .gitignore

- [ ] **Create example outputs**: Generate sample reports for documentation
  > TEST: Documentation
  > Type: Example Generation
  > Assert: Example reports demonstrate all features
  > Command: bin/test unit && ls -la test-report/*/

## Risk Assessment

### Technical Risks
- **Risk:** Minitest API changes in future versions
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Pin minitest version range, test with multiple versions
  - **Rollback:** Revert to standard reporters

### Integration Risks
- **Risk:** Conflicts with existing reporter configurations
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Clear documentation on reporter replacement
  - **Monitoring:** Test with various project setups

### Performance Risks
- **Risk:** Report generation slows down test execution
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Async report writing, minimal console output
  - **Monitoring:** Benchmark test execution times

## Acceptance Criteria

### Functional Requirements
- [x] **Compact Console Output**: Max 2 lines per failure in terminal
- [ ] **Auto-Detection Works**: Correctly identifies ATOM/Rails/generic projects
- [ ] **Reports Generated**: Detailed reports created in test-report/
- [ ] **JSON Output Valid**: Machine-readable JSON files generated
- [ ] **Zero Configuration**: Works without any setup required

### Quality Requirements
- [ ] **No Dependencies**: Module has zero ace_tools dependencies
- [ ] **Backward Compatible**: Can switch back to standard reporters
- [ ] **Thread Safe**: Works with parallel test execution
- [ ] **Documentation**: Usage examples and configuration documented

### Integration Requirements
- [ ] **Test Helper Updated**: ace_tools uses new reporter by default
- [ ] **Gitignore Updated**: test-report/ directory ignored
- [ ] **Examples Created**: Sample outputs for different project types

## References

- Minitest reporters documentation
- Current test helper configuration at test/test_helper.rb
- ATOM architecture test organization plan