---
id: v.0.9.0+task.010
status: done
estimate: 8h
dependencies: []
---

# Create ace-test-runner Package for Test Execution and Reporting

## Behavioral Specification

### User Experience
- **Input**: Developers run `ace-test` command with optional flags (--format, --fail-fast, --filter)
- **Process**: System discovers and executes tests, provides real-time feedback, analyzes failures
- **Output**: Immediate test results on stdout plus detailed timestamped reports saved to disk

### Expected Behavior
The ace-test-runner provides a unified test execution experience that caters to both human developers and AI agents. When invoked, it automatically discovers test files, executes them with appropriate framework (Minitest), and provides dual-mode output:

1. **Immediate Feedback**: Concise, actionable summary displayed on stdout showing pass/fail status, failure count, and key metrics
2. **Persistent Reports**: Comprehensive test data saved to timestamped directories for historical analysis and debugging

The system intelligently adapts its output format based on the consumer (human vs AI) and use case (CI, development, analysis). It handles test failures gracefully, providing clear error messages and suggested fixes when possible.

### Interface Contract
```bash
# CLI Interface
ace-test [options]
  --format FORMAT        # Output format: ai (default), compact, json, markdown
  --report-dir DIR      # Report storage directory (default: test-reports/)
  --no-save             # Skip saving detailed reports
  --fail-fast           # Stop execution on first failure
  --fix-deprecations    # Auto-fix deprecated test patterns
  --filter PATTERN      # Run only tests matching pattern
  --verbose             # Show detailed test execution
  --help                # Display help information

# Expected outputs
# Success case (AI format):
✅ 150 passed, ❌ 0 failed, ⚠️ 1 skipped
Summary: All tests passed in 0.45s
Detailed reports: test-reports/2025-01-20-14-30-45/

# Failure case (AI format):
✅ 148 passed, ❌ 2 failed, ⚠️ 1 skipped
Failures:
  - test/foo_test.rb:42 - test_validation_error
  - test/bar_test.rb:15 - test_connection_timeout
Detailed reports: test-reports/2025-01-20-14-30-45/

# Compact format (CI-friendly):
..F.F.S...........
```

**Error Handling:**
- [No tests found]: Display warning "No test files found matching pattern" with exit code 0
- [Test framework missing]: Display error "Minitest not available. Run: bundle install" with exit code 1
- [Invalid format]: Display error "Unknown format 'xyz'. Valid formats: ai, compact, json, markdown" with exit code 1
- [Permission denied]: Display error "Cannot write to test-reports/. Check permissions" with exit code 1

**Edge Cases:**
- [Empty test suite]: Report "0 tests executed" with success status
- [All tests skipped]: Report warning about all tests being skipped
- [Circular dependencies]: Detect and report circular test dependencies
- [Timeout handling]: Kill long-running tests after configurable timeout

### Success Criteria
- [ ] **Test Discovery**: Automatically finds and executes all test files in standard locations
- [ ] **Dual Output**: Provides both immediate stdout feedback and persistent detailed reports
- [ ] **AI Integration**: AI formatter produces consumable output with clear structure
- [ ] **Report Storage**: Saves timestamped reports with summary, failures, metrics, and suggestions
- [ ] **Format Flexibility**: Supports multiple output formats for different use cases
- [ ] **Failure Analysis**: Provides actionable failure information with fix suggestions
- [ ] **Performance**: Executes test suite without significant overhead (<5% slower than direct execution)
- [ ] **Configuration**: Respects .ace/test.yml configuration with sensible defaults

### Validation Questions
- [ ] **Report Retention**: How long should test reports be kept? Should there be automatic cleanup?
- [ ] **Parallel Execution**: Should tests run in parallel for performance? What's the isolation strategy?
- [ ] **Coverage Integration**: Should code coverage be automatically calculated and reported?
- [ ] **Notification System**: Should there be hooks for test completion notifications?
- [ ] **Custom Formatters**: Should users be able to define custom output formatters?
- [ ] **Test Grouping**: How should tests be grouped (by file, by type, by speed)?

## Objective

Recreate the lost ace-test functionality as a standalone ace-test-runner gem that provides comprehensive test execution and reporting capabilities. This addresses the need for AI-friendly test output while maintaining human readability and CI compatibility.

## Scope of Work

- **User Experience Scope**: Test execution, result reporting, failure analysis, report persistence
- **System Behavior Scope**: Test discovery, Minitest integration, multi-format output, timestamped storage
- **Interface Scope**: CLI command (ace-test), configuration file (.ace/test.yml), report directory structure

### Deliverables

#### Behavioral Specifications
- Test execution flow with real-time feedback
- Multi-format output system design
- Report storage and retrieval patterns
- Failure analysis and suggestion generation

#### Validation Artifacts
- Test suite for the runner itself
- Example test reports in each format
- Performance benchmarks vs direct execution
- Integration tests with ace-* gems

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby class structures, module organization
- ❌ **Technology Decisions**: Specific testing libraries beyond Minitest
- ❌ **Performance Optimization**: Caching strategies, parallel execution implementation
- ❌ **Future Enhancements**: Test coverage tools, mutation testing, test generation

## References

- Lost ace-test functionality documentation: dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/docs/lost/dev-tools-changes.md
- Existing ace-* gem patterns: ace-core, ace-context, ace-test-support
- Original test_reporter components (242 lines agent_reporter, various formatters)
- ATOM architecture pattern for gem structure

## Implementation Plan

### Architecture Decisions

**ATOM Pattern Adoption**: Following the established pattern from other ace-* gems with clear separation:
- **Atoms**: Basic utilities (test_detector, command_builder, result_parser, timestamp_generator)
- **Molecules**: Composed operations (test_executor, failure_analyzer, report_storage)
- **Organisms**: Business logic (test_orchestrator, report_generator, agent_reporter)
- **Models**: Pure data structures (test_result, test_failure, test_report)

**Dependency Strategy**: Minimal dependencies leveraging ace-core for configuration and ace-test-support for Minitest integration

**Report Storage Architecture**: Timestamped directories with symlink to latest, supporting multiple formats per run

### Tool Selection

- **Test Framework**: Minitest (already in ace-test-support)
- **Configuration**: ace-core's cascade config system
- **File Operations**: Ruby stdlib (FileUtils, File, Dir)
- **Process Management**: Open3 for test execution
- **JSON Handling**: Ruby stdlib JSON
- **YAML Processing**: Ruby stdlib YAML

### Files to Create

#### Gem Structure
- `ace-test-runner/ace-test-runner.gemspec` - Gem specification
- `ace-test-runner/README.md` - Documentation
- `ace-test-runner/Rakefile` - Build tasks
- `ace-test-runner/LICENSE.txt` - License file
- `ace-test-runner/.gitignore` - Git ignore patterns

#### Executable
- `ace-test-runner/exe/ace-test` - Main CLI executable

#### Library Core
- `ace-test-runner/lib/ace/test_runner.rb` - Main module
- `ace-test-runner/lib/ace/test_runner/version.rb` - Version constant

#### Atoms (Basic Components)
- `ace-test-runner/lib/ace/test_runner/atoms/test_detector.rb` - Find test files
- `ace-test-runner/lib/ace/test_runner/atoms/command_builder.rb` - Build test commands
- `ace-test-runner/lib/ace/test_runner/atoms/result_parser.rb` - Parse test output
- `ace-test-runner/lib/ace/test_runner/atoms/timestamp_generator.rb` - Generate timestamps

#### Molecules (Composed Operations)
- `ace-test-runner/lib/ace/test_runner/molecules/test_executor.rb` - Execute tests
- `ace-test-runner/lib/ace/test_runner/molecules/failure_analyzer.rb` - Analyze failures
- `ace-test-runner/lib/ace/test_runner/molecules/deprecation_fixer.rb` - Fix deprecations
- `ace-test-runner/lib/ace/test_runner/molecules/report_storage.rb` - Save reports

#### Organisms (Business Logic)
- `ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb` - Coordinate execution
- `ace-test-runner/lib/ace/test_runner/organisms/report_generator.rb` - Generate reports
- `ace-test-runner/lib/ace/test_runner/organisms/agent_reporter.rb` - AI-friendly reporting

#### Models (Data Structures)
- `ace-test-runner/lib/ace/test_runner/models/test_result.rb` - Test result data
- `ace-test-runner/lib/ace/test_runner/models/test_failure.rb` - Failure information
- `ace-test-runner/lib/ace/test_runner/models/test_configuration.rb` - Config data
- `ace-test-runner/lib/ace/test_runner/models/test_report.rb` - Report structure

#### Formatters
- `ace-test-runner/lib/ace/test_runner/formatters/base_formatter.rb` - Abstract base
- `ace-test-runner/lib/ace/test_runner/formatters/ai_formatter.rb` - AI-optimized output
- `ace-test-runner/lib/ace/test_runner/formatters/compact_formatter.rb` - CI-friendly
- `ace-test-runner/lib/ace/test_runner/formatters/json_formatter.rb` - Machine-readable
- `ace-test-runner/lib/ace/test_runner/formatters/markdown_formatter.rb` - Human-readable

#### Configuration
- `ace-test-runner/config/default.yml` - Default configuration

#### Tests
- `ace-test-runner/test/test_helper.rb` - Test setup
- `ace-test-runner/test/ace/test_runner/*_test.rb` - Unit tests for each component

### Test Planning

#### Happy Path Scenarios
- Execute all tests successfully
- Generate reports in specified format
- Save reports to timestamped directory
- Display correct summary statistics

#### Edge Cases
- No tests found in project
- All tests skipped
- Mix of passing/failing/skipped tests
- Invalid command line options
- Non-existent filter patterns

#### Error Conditions
- Missing Minitest dependency
- Permission denied on report directory
- Invalid output format specified
- Test execution timeout
- Malformed test files

#### Integration Points
- ace-core configuration loading
- ace-test-support test helpers
- Minitest framework execution
- File system operations
- Process spawning and management

### Implementation Steps

1. **Initialize gem structure** (30 min)
   - Create ace-test-runner directory
   - Initialize gemspec with dependencies
   - Set up basic directory structure
   - Create README and LICENSE

2. **Implement core atoms** (1.5 hrs)
   - TestDetector: Find test files using patterns
   - CommandBuilder: Build minitest execution commands
   - ResultParser: Parse test output into structured data
   - TimestampGenerator: Create consistent timestamps

3. **Build molecules layer** (2 hrs)
   - TestExecutor: Run tests with Open3, capture output
   - FailureAnalyzer: Extract failure details and patterns
   - ReportStorage: Save reports to timestamped directories
   - DeprecationFixer: Identify and suggest deprecation fixes

4. **Create formatters** (1.5 hrs)
   - BaseFormatter: Abstract interface for all formatters
   - AiFormatter: Dual output with basic stdout and detailed saves
   - CompactFormatter: Minimal dots/F/S output
   - JsonFormatter: Structured JSON output
   - MarkdownFormatter: Human-readable markdown reports

5. **Implement organisms** (1.5 hrs)
   - TestOrchestrator: Main coordination logic
   - ReportGenerator: Combine results into reports
   - AgentReporter: AI-optimized report generation

6. **Create CLI executable** (1 hr)
   - Parse command line options
   - Load configuration from ace-core
   - Initialize and run orchestrator
   - Handle errors and exit codes

7. **Add configuration support** (30 min)
   - Create default.yml configuration
   - Integrate with ace-core cascade
   - Support environment variable overrides

8. **Write tests** (1 hr)
   - Unit tests for atoms and molecules
   - Integration tests for orchestrator
   - CLI tests for executable
   - Formatter output validation

9. **Documentation and examples** (30 min)
   - Update README with usage examples
   - Add inline documentation
   - Create example test reports
   - Document configuration options

### Validation Steps

- [ ] Gem installs successfully
- [ ] ace-test command is available in PATH
- [ ] Tests execute with all formatters
- [ ] Reports save to correct directories
- [ ] AI formatter produces dual output
- [ ] Configuration cascade works correctly
- [ ] Error handling provides clear messages
- [ ] Integration with ace-* gems functions

### Risk Mitigation

- **Minitest compatibility**: Test with different Minitest versions
- **Performance overhead**: Profile and optimize critical paths
- **Report disk usage**: Implement automatic cleanup options
- **Format extensibility**: Design formatter interface for future additions