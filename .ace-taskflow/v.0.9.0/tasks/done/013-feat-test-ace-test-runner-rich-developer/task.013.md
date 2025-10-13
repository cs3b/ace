---
id: v.0.9.0+task.013
status: done
estimate: 3-4 days
dependencies: []
---

# Enhance ace-test-runner with Rich Developer Experience Features

## Behavioral Specification

### User Experience
- **Input**: Developers provide test targets (atoms, molecules, unit), configuration files, and command-line options
- **Process**: Real-time grouped progress display with section headers, colored dots organized by test type, immediate feedback on test execution
- **Output**: Rich failure reports with code context, individual markdown files per failure, comprehensive debugging information, test group summaries

### Expected Behavior
The enhanced ace-test-runner will provide a rich developer experience while maintaining the current 6x performance improvement. Users will be able to:

1. **Target specific test groups** using simple command-line arguments like `ace-test atoms` or `ace-test unit`
2. **See organized progress display** with tests grouped by category (atoms, molecules, organisms) with visual section headers
3. **Get detailed failure analysis** with individual markdown reports containing code context, stack traces, and assertion details
4. **Configure test patterns** via `.ace/test-runner.yml` to define custom test groups and patterns
5. **Maintain performance** with all enhancements being opt-in and preserving the current execution speed

### Interface Contract

```bash
# CLI Interface
ace-test [target] [options]

# Targets (from configuration):
#   atoms       - Run atom tests only
#   molecules   - Run molecule tests only
#   unit        - Run all unit tests (atoms + molecules + organisms + models)
#   integration - Run integration tests
#   all         - Run all tests (default)
#   quick       - Run quick tests (atoms + molecules)

# Examples:
ace-test                           # Run all tests (default)
ace-test atoms                     # Run only atom tests
ace-test unit --format progress    # Run unit tests with progress display
ace-test --format compact          # CI-friendly compact output
ace-test test/foo_test.rb          # Run specific file

# Configuration Interface (.ace/test-runner.yml)
version: 1
patterns:
  atoms: 'test/unit/atoms/**/*_test.rb'
  molecules: 'test/unit/molecules/**/*_test.rb'
  organisms: 'test/unit/organisms/**/*_test.rb'
  models: 'test/unit/models/**/*_test.rb'
  integration: 'test/integration/**/*_test.rb'
groups:
  unit: [atoms, molecules, organisms, models]
  all: [unit, integration]
  quick: [atoms, molecules]
defaults:
  reporter: progress
  color: auto
  fail_fast: false
```

**Error Handling:**
- Invalid target: Show available targets from configuration
- Missing configuration: Use sensible defaults with warning
- No tests found: Clear message with pattern information

**Edge Cases:**
- Empty test groups: Skip with informational message
- Mixed file/target args: Support both simultaneously
- Nested group definitions: Recursive expansion supported

### Success Criteria
- [ ] **Target Selection**: Users can run specific test groups via simple command-line targets
- [ ] **Grouped Progress Display**: Tests show organized progress with category headers and visual grouping
- [ ] **Rich Failure Reports**: Each failure generates detailed markdown with code context and stack traces
- [ ] **Configuration Support**: `.ace/test-runner.yml` enables pattern and group customization
- [ ] **Performance Maintained**: All enhancements preserve the current 6x speed improvement
- [ ] **Backward Compatibility**: Existing usage patterns continue to work unchanged

### Validation Questions
- [ ] **Default Behavior**: Should running `ace-test` without args default to 'all' or require explicit target?
- [ ] **Progress Grouping**: Should progress dots be grouped per-file or per-category?
- [ ] **Failure Limit**: Should individual failure reports be limited to prevent overwhelming output?
- [ ] **Configuration Location**: Should config support both `.ace/test-runner.yml` and project root locations?

## Implementation Plan

### Technical Approach

#### Phase 1: Configuration and Target Selection
**Files to Create:**
- `lib/ace/test_runner/molecules/pattern_resolver.rb` - Resolve patterns to file lists
- `lib/ace/test_runner/molecules/config_loader.rb` - Load and merge configuration

**Files to Modify:**
- `lib/ace/test_runner/models/test_configuration.rb` - Extend with pattern support
- `exe/ace-test` - Add target argument parsing
- `lib/ace/test_runner/organisms/test_orchestrator.rb` - Use pattern resolver

**Implementation Steps:**
1. Create ConfigLoader to read `.ace/test-runner.yml`
2. Implement PatternResolver to expand groups and patterns
3. Update exe/ace-test to accept target arguments
4. Modify TestOrchestrator to use resolved file lists

#### Phase 2: Rich Failure Reporting
**Files to Modify:**
- `lib/ace/test_runner/formatters/markdown_formatter.rb` - Add individual failure generation
- `lib/ace/test_runner/molecules/failure_analyzer.rb` - Add code context extraction
- `lib/ace/test_runner/organisms/report_generator.rb` - Coordinate failure reports

**New Methods:**
- `extract_code_context(file, line, radius=5)` - Get surrounding code
- `generate_failure_report(failure)` - Create individual markdown file
- `format_backtrace(backtrace)` - Clean and format stack traces

**Implementation Steps:**
1. Enhance FailureAnalyzer with code context extraction
2. Add individual failure report generation to MarkdownFormatter
3. Create failure subdirectory in report storage
4. Update ReportGenerator to coordinate all reports

#### Phase 3: Group-Aware Progress Display
**Files to Modify:**
- `lib/ace/test_runner/atoms/test_detector.rb` - Add group classification
- `lib/ace/test_runner/formatters/progress_formatter.rb` - Group-aware display
- `lib/ace/test_runner/models/test_group.rb` - Add display formatting

**Implementation Steps:**
1. Enhance TestDetector to classify tests by group
2. Modify ProgressFormatter to show section headers
3. Add group totals and summaries to output
4. Preserve real-time dot display within groups

### File Operations

#### Create Files:
- `lib/ace/test_runner/molecules/pattern_resolver.rb` - Pattern and group resolution logic
- `lib/ace/test_runner/molecules/config_loader.rb` - Configuration file loading
- `test/unit/molecules/pattern_resolver_test.rb` - Pattern resolver tests
- `test/unit/molecules/config_loader_test.rb` - Config loader tests
- `test/fixtures/test-runner.yml` - Test configuration fixture

#### Modify Files:
- `exe/ace-test` - Add target argument support
- `lib/ace/test_runner/models/test_configuration.rb` - Pattern configuration
- `lib/ace/test_runner/organisms/test_orchestrator.rb` - Use patterns
- `lib/ace/test_runner/formatters/markdown_formatter.rb` - Individual failures
- `lib/ace/test_runner/molecules/failure_analyzer.rb` - Code context
- `lib/ace/test_runner/formatters/progress_formatter.rb` - Grouped display
- `lib/ace/test_runner/atoms/test_detector.rb` - Group detection

### Testing Strategy

#### Unit Tests:
- PatternResolver: Group expansion, pattern matching, recursive resolution
- ConfigLoader: YAML parsing, default values, cascade merging
- FailureAnalyzer: Code extraction, backtrace formatting
- TestDetector: Group classification logic

#### Integration Tests:
- End-to-end target selection with various patterns
- Configuration file loading and override behavior
- Failure report generation with real test failures
- Progress display with grouped output

#### Performance Tests:
- Verify target selection doesn't impact startup time
- Ensure failure reporting doesn't slow execution
- Validate grouped progress has minimal overhead

## Objective

Enable developers to have a rich, organized test execution experience with detailed failure analysis while maintaining the excellent performance characteristics of the current implementation. Restore valuable features from the previous implementation in a way that enhances rather than compromises the current design.

## Scope of Work

- **User Experience Scope**: Test target selection, grouped progress visualization, detailed failure analysis
- **System Behavior Scope**: Configuration loading, pattern resolution, enhanced reporting
- **Interface Scope**: CLI arguments, configuration file format, report output structure

### Deliverables

#### Behavioral Specifications
- Target selection interface and behavior
- Grouped progress display format
- Failure report structure and content

#### Implementation Artifacts
- Pattern resolver and configuration loader
- Enhanced formatters with grouping and detail
- Test coverage for all new functionality

#### Validation Artifacts
- Performance benchmarks comparing before/after
- Example configurations for common scenarios
- Sample failure reports demonstrating enhancement

## Out of Scope

- ❌ **Parallel Execution**: True parallel test execution (future enhancement)
- ❌ **Test Profiling**: Detailed performance profiling (future enhancement)
- ❌ **Watch Mode**: Automatic test re-running on file changes
- ❌ **Coverage Integration**: Test coverage reporting integration

## References

- Previous implementation analysis in lost/recovered files
- Current ace-test-runner architecture and performance characteristics
- Comparison document of old vs new implementations