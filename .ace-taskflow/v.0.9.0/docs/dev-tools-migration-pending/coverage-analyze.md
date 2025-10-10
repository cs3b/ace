# coverage-analyze - SimpleCov Coverage Analysis Tool

## Overview

`coverage-analyze` is a comprehensive coverage analysis tool that processes SimpleCov `.resultset.json` files and generates detailed reports with recommendations. It provides adaptive threshold detection, multiple output formats, and integration with development workflows.

## Purpose

The tool was created to:
- Analyze test coverage data from SimpleCov
- Identify under-covered files and methods
- Generate actionable recommendations for improving coverage
- Support multiple analysis modes (quick, focused, comprehensive)
- Integrate with create-path workflow for automated test generation
- Provide adaptive threshold detection based on project maturity

## Location

- **Executable**: `/dev-tools/exe/coverage-analyze`
- **Command Implementation**: `/dev-tools/lib/coding_agent_tools/cli/commands/coverage/analyze.rb`
- **Workflow Ecosystem**: `/dev-tools/lib/coding_agent_tools/ecosystems/coverage_analysis_workflow.rb`

## API Reference

### Basic Command

```bash
coverage-analyze <input_file> [options]
```

### Required Arguments

| Argument | Description |
|----------|-------------|
| `input_file` | Path to SimpleCov `.resultset.json` file |

### Core Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--threshold` | string | auto | Coverage threshold: percentage (0-100) or 'auto' for adaptive |
| `--output-dir` | string | ./coverage_analysis | Output directory for reports |
| `--format` | string | text,json | Output formats (comma-separated: text,json,csv) |

### File Filtering Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--include-patterns` | string | **/lib/**/*.rb | File patterns to include (comma-separated) |
| `--exclude-patterns` | string | **/spec/**,**/test/** | File patterns to exclude (comma-separated) |
| `--focus` | string | - | Focus on specific file patterns (comma-separated) |

### Analysis Modes

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--quick` | boolean | false | Quick analysis mode (faster, less detailed) |
| `--detailed` | boolean | false | Include method-level analysis |
| `--comprehensive` | boolean | false | Generate comprehensive report with all sections |
| `--recommend` | boolean | false | Only analyze and provide recommendations (no full analysis) |

### Advanced Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--max-files` | integer | 20 | Maximum number of files to analyze in detail |
| `--create-path` | boolean | false | Enable create-path workflow integration |
| `--compact` | boolean | true | Use compact range format for uncovered lines |
| `--verbose` | boolean | false | Use verbose format with full uncovered line arrays |

## How It Works

### Architecture (ATOM + Ecosystem)

The coverage analysis system uses ATOM architecture with an Ecosystem orchestrator:

#### Atoms
- **SimpleCovParser**: Parse `.resultset.json` files
- **ThresholdDetector**: Detect adaptive thresholds based on coverage distribution
- **CoverageCalculator**: Calculate coverage percentages and statistics
- **PatternMatcher**: Match file patterns for filtering

#### Molecules
- **FileAnalyzer**: Analyze individual file coverage
- **ReportGenerator**: Generate reports in multiple formats
- **RecommendationEngine**: Generate improvement recommendations
- **CreatePathIntegrator**: Integrate with create-path workflow

#### Organisms
- **CoverageAnalyzer**: Orchestrate full coverage analysis
- **QuickAnalyzer**: Fast analysis for CI pipelines
- **FocusedAnalyzer**: Targeted analysis for specific areas

#### Ecosystem
- **CoverageAnalysisWorkflow**: Top-level workflow orchestration
  - Coordinates analysis modes
  - Manages report generation
  - Handles workflow integration

### Execution Flow

```
SimpleCov .resultset.json
        ↓
SimpleCovParser (parse coverage data)
        ↓
ThresholdDetector (auto or fixed threshold)
        ↓
FileAnalyzer (analyze each file)
        ↓
RecommendationEngine (generate suggestions)
        ↓
ReportGenerator (multiple formats)
        ↓
CreatePathIntegrator (optional workflow)
        ↓
Output: Reports + Recommendations
```

### Analysis Modes

#### 1. Recommend Mode (`--recommend`)
**Fastest - Just recommendations**

```bash
coverage-analyze coverage.resultset.json --recommend
```

Output:
- File validation results
- Suggested threshold
- Recommended analysis approach
- Estimated analysis time
- Workflow suggestions

#### 2. Quick Mode (`--quick`)
**Fast CI/CD analysis**

```bash
coverage-analyze coverage.resultset.json --quick
```

Features:
- Overall coverage percentage
- Files under threshold count
- Top 5 critical files
- Quick recommendations

#### 3. Focused Mode (`--focus`)
**Targeted analysis**

```bash
coverage-analyze coverage.resultset.json --focus "**/models/**,**/services/**"
```

Features:
- Analysis limited to specified patterns
- Coverage distribution for focused area
- Detailed statistics for matched files

#### 4. Full Mode (default)
**Comprehensive analysis**

```bash
coverage-analyze coverage.resultset.json
```

Features:
- Complete file-by-file analysis
- Uncovered line ranges
- Priority recommendations
- Optional create-path integration

#### 5. Comprehensive Mode (`--comprehensive`)
**Most detailed analysis**

```bash
coverage-analyze coverage.resultset.json --detailed --comprehensive
```

Features:
- Method-level coverage analysis
- All report sections
- Detailed uncovered line information
- Complete recommendations

### Adaptive Threshold Detection

When `--threshold auto` (default), the tool detects an appropriate threshold:

1. **Analyze coverage distribution**:
   - Calculate mean and median coverage
   - Identify coverage clusters
   - Detect outliers

2. **Determine project maturity**:
   - High coverage (>80%): Strict threshold (90%)
   - Medium coverage (60-80%): Moderate threshold (75%)
   - Low coverage (<60%): Relaxed threshold (60%)

3. **Apply threshold**:
   - Use detected threshold for analysis
   - Report threshold in output

### Report Formats

#### Text Format (Human-readable)
```
Coverage Analysis Report
========================

Overall Coverage: 87.5%
Threshold: 80.0% (auto-detected)
Status: 🟢 Excellent

Files Under Threshold: 3/45

Critical Files:
  1. lib/ace/parser.rb: 45.2% (127 uncovered lines)
     Priority: HIGH - Core functionality with low coverage
     Recommendation: Add test cases for parsing edge cases
```

#### JSON Format (Machine-readable)
```json
{
  "overall_coverage": 87.5,
  "threshold": 80.0,
  "status": "excellent",
  "files_under_threshold": 3,
  "total_files": 45,
  "undercovered_files": [
    {
      "path": "lib/ace/parser.rb",
      "coverage": 45.2,
      "uncovered_lines": [10, 15, 23, "..."],
      "uncovered_ranges": "10-15, 23-45, 67-89",
      "priority": "high"
    }
  ]
}
```

#### CSV Format (Spreadsheet)
```csv
file,coverage,uncovered_lines,uncovered_count,priority,recommendation
lib/ace/parser.rb,45.2,"10-15, 23-45, 67-89",127,high,"Add test cases for parsing edge cases"
lib/ace/config.rb,65.8,"5-8, 34-42",15,medium,"Test configuration edge cases"
```

### Create-Path Integration

With `--create-path` flag, generates structured output for automated test generation:

```bash
coverage-analyze coverage.resultset.json --create-path
```

Output: `coverage_analysis/create_path_integration.json`

```json
{
  "workflow": "create-test-cases",
  "items": [
    {
      "type": "test_case",
      "source_file": "lib/ace/parser.rb",
      "uncovered_lines": [10, 15, 23],
      "priority": "high",
      "template": "test/ace/parser_test.rb"
    }
  ],
  "action_required": true,
  "critical_items_count": 3
}
```

## Usage Examples

### Basic Analysis

```bash
# Default analysis with auto threshold
coverage-analyze coverage/.resultset.json

# Fixed threshold
coverage-analyze coverage/.resultset.json --threshold 90

# Custom output directory
coverage-analyze coverage/.resultset.json --output-dir reports/coverage
```

### Quick Analysis for CI

```bash
# Fast analysis for CI pipelines
coverage-analyze coverage/.resultset.json --quick

# Just get recommendations
coverage-analyze coverage/.resultset.json --recommend
```

### Focused Analysis

```bash
# Focus on specific directories
coverage-analyze coverage/.resultset.json --focus "**/lib/ace/core/**"

# Multiple focus patterns
coverage-analyze coverage/.resultset.json --focus "**/models/**,**/services/**"
```

### Comprehensive Analysis

```bash
# Full detailed analysis
coverage-analyze coverage/.resultset.json --detailed --comprehensive

# With create-path integration
coverage-analyze coverage/.resultset.json --comprehensive --create-path
```

### Custom Formats

```bash
# JSON only
coverage-analyze coverage/.resultset.json --format json

# All formats
coverage-analyze coverage/.resultset.json --format text,json,csv

# Verbose line arrays instead of ranges
coverage-analyze coverage/.resultset.json --verbose
```

## Output Examples

### Recommend Mode Output
```
🔍 Analyzing SimpleCov file for recommendations...

📋 File Validation Results:
  Status: ✅ Valid SimpleCov file
  Frameworks: RSpec
  Total files: 45
  Library files: 38
  Test files: 7

💡 Analysis Recommendations:
  Suggested threshold: 85%
  Recommended approach: Focused analysis on core modules
  Estimated time: 2-3 seconds
  Suggested formats: text, json

⚙️  Workflow Suggestions:
  Include method analysis: ✅
  Enable create-path: ✅
  Suggested focus patterns:
    - **/lib/ace/core/**
    - **/lib/ace/taskflow/**
```

### Quick Mode Output
```
⚡ Executing quick coverage analysis...

📊 Quick Analysis Results:
  Overall Coverage: 87.5%
  Threshold: 85.0% (auto-detected)
  Status: 🟢 Excellent
  Files under threshold: 3/45

🚨 Critical Files (Top 5):
  1. lib/ace/parser.rb: 45.2% (127 uncovered lines)
  2. lib/ace/config.rb: 65.8% (15 uncovered lines)
  3. lib/ace/validator.rb: 72.3% (8 uncovered lines)

📝 Quick Recommendations:
  • Focus on lib/ace/parser.rb - lowest coverage in core functionality
  • Add edge case tests for configuration handling
  • Consider integration tests for validator workflows
```

### Full Analysis Output
```
🔄 Executing full coverage analysis...

✅ Full Analysis Complete!
  Execution time: 2.3s
  Output directory: ./coverage_analysis

📊 Analysis Summary:
  Overall Coverage: 87.5%
  Threshold: 85.0% (auto-detected)
  Status: 🟢 Excellent
  Files analyzed: 45
  Files under threshold: 3

📄 Generated Reports:
  TEXT: ./coverage_analysis/report.txt
  JSON: ./coverage_analysis/report.json
  CSV: ./coverage_analysis/report.csv

🚨 Priority Summary:
  Critical files: 1
  High priority files: 2
  Total recommendations: 8

🎉 Analysis complete! Check the generated reports for detailed information.
```

## Integration with ace-* Architecture

### Current Status

`coverage-analyze` is a **complex ecosystem within dev-tools** that could be migrated to a focused gem.

### Migration Options

#### Option 1: ace-coverage (Standalone)
Create dedicated coverage analysis gem:

```ruby
# Future: ace-coverage
module Ace::Coverage
  module Atoms
    class SimpleCovParser
    class ThresholdDetector
  end

  module Molecules
    class FileAnalyzer
    class ReportGenerator
  end

  module Organisms
    class CoverageAnalyzer
  end
end

# CLI
ace-coverage analyze coverage/.resultset.json
ace-coverage analyze --quick
ace-coverage analyze --recommend
```

**Pros**:
- Focused scope
- Reusable in CI/CD
- Clear responsibility

**Cons**:
- Another gem to maintain
- Coverage is testing-adjacent, not standalone

#### Option 2: ace-test-runner Integration
Integrate coverage analysis into test runner:

```ruby
# Future: ace-test integration
ace-test --coverage                    # Run tests + generate coverage
ace-test --coverage-analyze            # Run tests + analyze coverage
ace-test --coverage-report text,json   # Custom report formats
```

**Pros**:
- Natural pairing with test execution
- Single workflow for test + coverage
- Shared infrastructure

**Cons**:
- Couples testing and analysis
- ace-test-runner becomes larger

#### Option 3: Hybrid Approach
```bash
# ace-test-runner: Generate coverage
ace-test --coverage

# ace-coverage: Analyze coverage
ace-coverage analyze coverage/.resultset.json
```

**Pros**:
- Separation of concerns
- Flexible workflow
- Reusable analysis

**Cons**:
- Two tools for related tasks
- Requires coordination

### Recommended Migration Path

**Recommended: Option 2 (ace-test-runner Integration)**

Rationale:
- Coverage is inherently part of testing workflow
- Developers want single command for test + coverage
- Simplifies CI/CD configuration
- ace-test-runner already handles test execution

### Migration Tasks

1. **Extract analysis logic** to ATOM layers in ace-test-runner
2. **Add coverage subcommands** to ace-test:
   ```bash
   ace-test --coverage                    # Run + generate
   ace-test coverage analyze [file]       # Analyze existing
   ace-test coverage report [options]     # Generate reports
   ```
3. **Integrate SimpleCov configuration** with ace-test config
4. **Migrate create-path integration**
5. **Deprecate coverage-analyze** with redirect to ace-test
6. **Update documentation**

## Configuration

### Current Configuration

No dedicated config file. Options passed via CLI flags.

### Future Configuration (ace-test integration)

```yaml
# .ace/test/config.yml
ace:
  test:
    coverage:
      enabled: true
      threshold: 85  # or "auto"
      output_dir: coverage_analysis
      formats:
        - text
        - json
        - csv
      analysis:
        detailed: true
        max_files: 20
        include_patterns:
          - "**/lib/**/*.rb"
        exclude_patterns:
          - "**/spec/**"
          - "**/test/**"
      create_path:
        enabled: true
        workflow: "create-test-cases"
```

## Exit Codes

- `0` - Analysis successful
- `1` - Analysis failed or error occurred

## Limitations

1. **SimpleCov Only**: Only supports SimpleCov format, not other coverage tools
2. **Ruby Focus**: Designed for Ruby projects, not multi-language
3. **Line Coverage**: Reports line coverage, not branch coverage
4. **Static Analysis**: No mutation testing or quality metrics
5. **Manual Integration**: create-path integration requires manual follow-up

## Future Enhancements

### For ace-test-runner Integration

1. **Automatic Coverage**: Run coverage by default in test suite
2. **Coverage Gates**: Fail tests if coverage drops below threshold
3. **Diff Coverage**: Analyze coverage for changed files only
4. **Trend Analysis**: Track coverage changes over time
5. **Multi-format Support**: Support other coverage tools (Codecov, Coveralls)
6. **Branch Coverage**: Report branch/condition coverage
7. **Mutation Testing**: Integrate with mutation testing tools

## Related Tools

- **SimpleCov**: Coverage data generation
- **ace-test-runner**: Test execution (future integration point)
- **create-path**: File creation workflow
- **ace-taskflow**: Could create coverage improvement tasks

## Historical Context

Developed to support:
- Data-driven test improvement
- CI/CD coverage enforcement
- Automated test case generation via create-path
- Coverage quality gates

The adaptive threshold feature emerged from the need to set realistic goals based on project maturity rather than arbitrary percentages.

## Migration Timeline

- **Current**: Available as `coverage-analyze` in dev-tools
- **v0.10.0**: Begin integration into `ace-test-runner`
- **v0.11.0**: Deprecation warning for standalone `coverage-analyze`
- **v0.12.0**: Remove from dev-tools, use `ace-test coverage analyze`
- **v1.0.0**: Full integration, standalone tool removed

## See Also

- SimpleCov documentation: https://github.com/simplecov-ruby/simplecov
- ace-test-runner: Future integration point
- Testing patterns: `docs/testing-patterns.md`
- Create-path workflow: `docs/create-path.md`
