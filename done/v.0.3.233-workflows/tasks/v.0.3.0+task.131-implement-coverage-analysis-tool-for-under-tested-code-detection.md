---
id: v.0.3.0+task.131
status: done
priority: medium
estimate: 16h
dependencies: []
---

# Implement Coverage Analysis Tool for Under-tested Code Detection

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/tools/lib/coding_agent_tools
├── atoms
├── cli
├── ecosystems
├── middlewares
├── models
├── molecules
├── organisms
└── version.rb
```

## Objective

Create a CLI tool `coverage-analyze` that parses SimpleCov coverage reports (.resultset.json) to identify files and methods with coverage below a configurable threshold (default 85%). This tool will help developers prioritize testing efforts by providing actionable insights about under-tested code areas.

## Scope of Work

- Implement complete ATOM architecture components for coverage analysis
- Parse SimpleCov .resultset.json format for accurate coverage data
- Extract method-level coverage by mapping coverage lines to Ruby method definitions
- Generate reports in multiple formats (text, JSON, CSV)
- Provide configurable threshold and filtering options
- Support method-level and file-level analysis modes

### Deliverables

#### Create

- `.ace/tools/lib/coding_agent_tools/atoms/coverage_file_reader.rb`
- `.ace/tools/lib/coding_agent_tools/atoms/ruby_method_parser.rb`
- `.ace/tools/lib/coding_agent_tools/atoms/coverage_calculator.rb`
- `.ace/tools/lib/coding_agent_tools/atoms/threshold_validator.rb`
- `.ace/tools/lib/coding_agent_tools/molecules/coverage_data_processor.rb`
- `.ace/tools/lib/coding_agent_tools/molecules/method_coverage_mapper.rb`
- `.ace/tools/lib/coding_agent_tools/molecules/file_analyzer.rb`
- `.ace/tools/lib/coding_agent_tools/molecules/report_formatter.rb`
- `.ace/tools/lib/coding_agent_tools/organisms/coverage_analyzer.rb`
- `.ace/tools/lib/coding_agent_tools/organisms/undercovered_items_extractor.rb`
- `.ace/tools/lib/coding_agent_tools/organisms/coverage_report_generator.rb`
- `.ace/tools/lib/coding_agent_tools/ecosystems/coverage_analysis_workflow.rb`
- `.ace/tools/lib/coding_agent_tools/cli/coverage_analyze_command.rb`
- `.ace/tools/exe/coverage-analyze`
- `.ace/tools/spec/atoms/coverage_file_reader_spec.rb`
- `.ace/tools/spec/atoms/ruby_method_parser_spec.rb`
- `.ace/tools/spec/atoms/coverage_calculator_spec.rb`
- `.ace/tools/spec/atoms/threshold_validator_spec.rb`
- `.ace/tools/spec/molecules/coverage_data_processor_spec.rb`
- `.ace/tools/spec/molecules/method_coverage_mapper_spec.rb`
- `.ace/tools/spec/molecules/file_analyzer_spec.rb`
- `.ace/tools/spec/molecules/report_formatter_spec.rb`
- `.ace/tools/spec/organisms/coverage_analyzer_spec.rb`
- `.ace/tools/spec/organisms/undercovered_items_extractor_spec.rb`
- `.ace/tools/spec/organisms/coverage_report_generator_spec.rb`
- `.ace/tools/spec/ecosystems/coverage_analysis_workflow_spec.rb`
- `.ace/tools/spec/cli/coverage_analyze_command_spec.rb`
- `.ace/tools/spec/fixtures/coverage_samples/sample.resultset.json`
- `.ace/tools/spec/fixtures/coverage_samples/sample_ruby_file.rb`

#### Modify

- `.ace/tools/lib/coding_agent_tools.rb` (add requires for new components)
- `.ace/tools/lib/coding_agent_tools/cli.rb` (register new command)
- `.ace/tools/coding_agent_tools.gemspec` (update dependencies if needed)

## Phases

1. **Atoms Development** - Basic utilities for file reading, parsing, and calculation
2. **Molecules Development** - Composed operations for data processing and formatting
3. **Organisms Development** - Business logic for analysis and extraction
4. **Ecosystems & CLI** - Complete workflow orchestration and command interface
5. **Testing & Validation** - Comprehensive test suite and real-world validation

## Implementation Plan

### Planning Steps

- [x] Analyze SimpleCov .resultset.json format structure in detail
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: JSON structure and line coverage mapping format understood
  > **COMPLETED**: Analysis shows nested structure with test framework keys, coverage arrays with null/integer values, empty branches objects, and unix timestamps
- [x] Research Ruby AST parsing options for method extraction (Parser gem, Ripper)
  > **COMPLETED**: Parser gem (v3.3.9.0) is available in project and suitable for AST parsing
- [x] Design data structures for coverage analysis results
  > **COMPLETED**: See `docs/131-coverage-analysis-data-structures.md` for complete design
- [ ] Plan CLI interface and output format specifications
- [ ] Create realistic test fixtures with sample coverage data instead of aspirational commands
- [ ] Verify Parser gem dependency is properly listed in gemspec

### Execution Steps

- [ ] **Phase 1: Setup and Models**
  - [ ] Create Model classes: `CoverageResult`, `MethodCoverage`, `CoverageAnalysisResult`
  - [ ] Create `spec/fixtures/coverage_samples/` directory with realistic test data
  - [ ] Verify Parser gem dependency in Gemfile (already confirmed available)
  > TEST: Basic Infrastructure
  > Type: Unit Tests
  > Assert: Model classes instantiate correctly and have expected interfaces
  > Command: cd .ace/tools && bundle exec rspec spec/models/coverage*_spec.rb

- [ ] **Phase 2: Implement Core Atoms**
  - [ ] Create `CoverageFileReader` with JSON parsing, validation, and error handling for malformed files
  - [ ] Create `RubyMethodParser` using Parser gem to extract method definitions with line ranges
  - [ ] Create `CoverageCalculator` for percentage calculations handling null values correctly
  - [ ] Create `ThresholdValidator` for input validation (0-100 range)
  > TEST: Atoms Functionality
  > Type: Unit Tests
  > Assert: Each atom handles valid inputs correctly and fails gracefully on invalid inputs
  > Command: cd .ace/tools && bundle exec rspec spec/atoms/coverage_*_spec.rb

- [ ] **Phase 3: Implement Data Processing Molecules**
  - [ ] Create `CoverageDataProcessor` to transform SimpleCov JSON into internal format, handling multiple test frameworks
  - [ ] Create `MethodCoverageMapper` to map coverage line arrays to method line ranges
  - [ ] Create `FileAnalyzer` for individual file coverage analysis with file filtering options
  - [ ] Create `ReportFormatter` supporting text, JSON, CSV formats with proper escaping
  > TEST: Molecules Integration
  > Type: Integration Tests
  > Assert: Molecules correctly process real SimpleCov data and produce expected internal formats
  > Command: cd .ace/tools && bundle exec rspec spec/molecules/coverage_*_spec.rb

- [ ] **Phase 4: Implement Business Logic Organisms**
  - [ ] Create `CoverageAnalyzer` for main analysis orchestration with performance optimization
  - [ ] Create `UndercoveredItemsExtractor` for threshold-based filtering with configurable criteria
  - [ ] Create `CoverageReportGenerator` for comprehensive reporting with summary statistics
  > TEST: Business Logic Validation
  > Type: Integration Tests
  > Assert: Complex analysis workflows produce accurate results matching expected coverage calculations
  > Command: cd .ace/tools && bundle exec rspec spec/organisms/coverage_*_spec.rb

- [ ] **Phase 5: Implement Ecosystem & CLI Interface**
  - [ ] Create `CoverageAnalysisWorkflow` ecosystem coordinating all components
  - [ ] Create `CoverageAnalyzeCommand` CLI interface with comprehensive options and help
  - [ ] Create `coverage-analyze` executable following existing patterns
  - [ ] Add command registration to CLI module and update requires
  > TEST: End-to-End CLI Functionality
  > Type: CLI Integration Tests with Aruba
  > Assert: Complete CLI workflow processes real coverage data and outputs expected formats
  > Command: cd .ace/tools && bundle exec rspec spec/cli/coverage_analyze_command_spec.rb

- [ ] **Phase 6: Comprehensive Testing & Performance Validation**
  - [ ] Test with edge cases: empty files, 100%/0% coverage, malformed JSON, missing files
  - [ ] Validate performance with large coverage files (>1MB) and many files (>200)
  - [ ] Test integration with actual .ace/tools coverage data
  - [ ] Verify all output formats with complex scenarios
  > TEST: Production Readiness
  > Type: Integration & Performance Tests
  > Assert: Tool handles real-world coverage data efficiently (<10s for 200+ files) and accurately
  > Command: cd .ace/tools && bundle exec rspec && time exe/coverage-analyze --coverage-path coverage

## Acceptance Criteria

- [ ] AC 1: Tool correctly parses SimpleCov .resultset.json files
- [ ] AC 2: Accurately calculates file-level and method-level coverage percentages
- [ ] AC 3: Identifies files and methods below configurable threshold (default 85%)
- [ ] AC 4: Supports multiple output formats (text, JSON, CSV)
- [ ] AC 5: CLI interface provides comprehensive options and help
- [ ] AC 6: All ATOM architecture components follow established patterns
- [ ] AC 7: Comprehensive test coverage (>90%) for all new components
- [ ] AC 8: Performance is acceptable for large codebases (handles 200+ files)
- [ ] AC 9: Tool integrates seamlessly with existing .ace/tools ecosystem

## Technical Implementation Details

### SimpleCov Format Analysis (Completed)

Based on examination of `.ace/tools/coverage/.resultset.json`:

**Structure:**
```json
{
  "TestFrameworkName": {
    "coverage": {
      "/absolute/path/file.rb": {
        "lines": [null, 1, 0, 5, null, ...],
        "branches": {}
      }
    },
    "timestamp": 1753633829
  }
}
```

**Key Insights:**
- Multiple test frameworks can be present ("RSpec", "Unknown Test Framework")
- Line values: `null` (not executable), `0` (uncovered), `N` (executed N times)
- Branch coverage currently empty but structure exists for future support
- 418+ files tracked with execution counts ranging from 0 to 800+
- Unix timestamps track when coverage was collected

### CLI Interface
```bash
coverage-analyze [OPTIONS]

Options:
  --threshold N          Coverage threshold percentage (default: 85)
  --format FORMAT        Output format: text|json|csv (default: text)
  --methods-only         Show only method-level analysis
  --files-only           Show only file-level analysis
  --output-title TITLE   Create new document with title using create-path
  --coverage-path PATH   Path to coverage directory (default: ./coverage)
  --include PATTERN      Include files matching pattern (default: lib/**)
  --exclude PATTERN      Exclude files matching pattern (default: spec/**)
  --help                 Show help message
```

**File Filtering (User Requirements):**
- **Default**: Analyze only `lib/` files (exclude spec files by default)
- **Override**: Allow custom patterns via --include/--exclude flags
- **Focus**: Prioritize files with coverage below threshold for faster processing

### Enhanced Error Handling

**File Processing Errors:**
- Malformed JSON: Graceful failure with specific error message
- Missing files: Skip with warning, continue processing other files
- Unparseable Ruby files: Log warning, exclude from method analysis
- Permission denied: Clear error message with suggested fixes

**Performance Optimizations (User Requirements):**
- **Large file handling**: Optimize for JSON files with 70k+ lines using streaming JSON parser
- **Fast filtering**: Quickly identify files below threshold before detailed analysis
- **Line-by-line focus**: Efficiently identify uncovered lines for targeted testing priorities
- **Memory efficiency**: Process files incrementally to avoid memory issues
- **Priority processing**: Handle under-covered files first for faster feedback

**Implementation Scope (User Requirements):**
- **Branch coverage**: Defer to future version - focus on uncovered lines (empty coverage)
- **Output handling**: Use create-path integration instead of direct file overwriting
- **Testing scope**: Target current SimpleCov version only
- **File focus**: Default to lib/ files with override capability

### Data Structures

**Coverage Result Model:**
```ruby
class CoverageResult
  attr_reader :file_path, :coverage_percentage, :methods

  def initialize(file_path:, coverage_percentage:, methods: [])
    @file_path = file_path
    @coverage_percentage = coverage_percentage
    @methods = methods
  end
end

class MethodCoverage
  attr_reader :name, :start_line, :end_line, :coverage_percentage

  def initialize(name:, start_line:, end_line:, coverage_percentage:)
    @name = name
    @start_line = start_line
    @end_line = end_line
    @coverage_percentage = coverage_percentage
  end
end
```

### ATOM Components Detail

**Atoms:**
- `CoverageFileReader`: Read and validate .resultset.json files
- `RubyMethodParser`: Extract method definitions using Parser gem
- `CoverageCalculator`: Calculate coverage percentages from line data
- `ThresholdValidator`: Validate threshold inputs (0-100)

**Molecules:**
- `CoverageDataProcessor`: Transform SimpleCov data to internal format
- `MethodCoverageMapper`: Map coverage arrays to method line ranges
- `FileAnalyzer`: Analyze individual files for coverage metrics
- `ReportFormatter`: Format results in different output formats

**Organisms:**
- `CoverageAnalyzer`: Main analysis coordination and workflow
- `UndercoveredItemsExtractor`: Filter results by threshold
- `CoverageReportGenerator`: Generate comprehensive analysis reports

**Ecosystem:**
- `CoverageAnalysisWorkflow`: Complete end-to-end coverage analysis

## Out of Scope

- ❌ Integration with coverage tools other than SimpleCov
- ❌ Real-time coverage monitoring or continuous integration
- ❌ Visual coverage reports or HTML generation
- ❌ Coverage trend analysis over time
- ❌ Automatic test generation for under-covered areas
- ❌ Integration with external coverage services (Codecov, Coveralls)

## References

- SimpleCov JSON format documentation
- Parser gem documentation for Ruby AST parsing
- Existing ATOM architecture patterns in .ace/tools
- CLI command patterns in .ace/tools/lib/coding_agent_tools/cli/
