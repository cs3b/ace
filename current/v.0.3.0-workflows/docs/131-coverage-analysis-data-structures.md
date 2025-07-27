# Coverage Analysis Tool - Data Structures Design

## SimpleCov Format Analysis

Based on examination of existing .resultset.json files, the format is:

```json
{
  "RSpec": {
    "coverage": {
      "/path/to/file.rb": {
        "lines": [
          null,    // index 0 - not used
          1,       // line 1 - executed 1 time  
          null,    // line 2 - not executable
          0,       // line 3 - not covered
          5        // line 4 - executed 5 times
        ],
        "branches": {}
      }
    },
    "timestamp": 1753633829
  }
}
```

## Designed Data Structures

### Core Models

```ruby
# models/coverage_result.rb
class CoverageResult
  attr_reader :file_path, :total_lines, :covered_lines, :coverage_percentage, :methods

  def initialize(file_path:, total_lines:, covered_lines:, coverage_percentage:, methods: [])
    @file_path = file_path
    @total_lines = total_lines
    @covered_lines = covered_lines
    @coverage_percentage = coverage_percentage
    @methods = methods
  end

  def under_threshold?(threshold)
    coverage_percentage < threshold
  end
end

# models/method_coverage.rb  
class MethodCoverage
  attr_reader :name, :start_line, :end_line, :total_lines, :covered_lines, :coverage_percentage

  def initialize(name:, start_line:, end_line:, total_lines:, covered_lines:, coverage_percentage:)
    @name = name
    @start_line = start_line
    @end_line = end_line
    @total_lines = total_lines
    @covered_lines = covered_lines
    @coverage_percentage = coverage_percentage
  end

  def under_threshold?(threshold)
    coverage_percentage < threshold
  end

  def line_range
    start_line..end_line
  end
end

# models/coverage_analysis_result.rb
class CoverageAnalysisResult
  attr_reader :files, :threshold, :analysis_timestamp

  def initialize(files:, threshold:, analysis_timestamp: Time.now)
    @files = files
    @threshold = threshold
    @analysis_timestamp = analysis_timestamp
  end

  def under_covered_files
    files.select { |file| file.under_threshold?(threshold) }
  end

  def under_covered_methods
    files.flat_map(&:methods).select { |method| method.under_threshold?(threshold) }
  end

  def total_files
    files.length
  end

  def total_methods
    files.sum { |file| file.methods.length }
  end

  def overall_coverage_percentage
    return 0.0 if total_executable_lines.zero?
    
    (total_covered_lines.to_f / total_executable_lines * 100).round(2)
  end

  private

  def total_executable_lines
    files.sum(&:total_lines)
  end

  def total_covered_lines  
    files.sum(&:covered_lines)
  end
end
```

### Internal Data Structures

```ruby
# Internal use for processing
class SimpleCovData
  attr_reader :test_suite, :files_data, :timestamp

  def initialize(test_suite:, files_data:, timestamp:)
    @test_suite = test_suite
    @files_data = files_data  # Hash of file_path => { lines: [...], branches: {} }
    @timestamp = timestamp
  end
end

class RubyMethodDefinition
  attr_reader :name, :start_line, :end_line, :type

  def initialize(name:, start_line:, end_line:, type: :def)
    @name = name
    @start_line = start_line
    @end_line = end_line
    @type = type  # :def, :defs, :class, :module
  end

  def line_range
    start_line..end_line
  end
end
```

## CLI Output Format Specifications

### Text Format (Default)
```
Coverage Analysis Report
========================
Threshold: 85%
Files analyzed: 156
Methods analyzed: 1,205

Under-covered Files (12):
-------------------------
lib/atoms/coverage_file_reader.rb: 67.8% (102/150 lines)
lib/molecules/coverage_processor.rb: 72.1% (98/136 lines)

Under-covered Methods (34):
----------------------------
lib/atoms/coverage_file_reader.rb:
  - parse_json_file (lines 25-45): 40.0% (8/20 lines)
  - validate_structure (lines 47-62): 75.0% (12/16 lines)

lib/molecules/coverage_processor.rb:
  - process_coverage_data (lines 18-89): 69.4% (50/72 lines)

Summary:
--------
Overall coverage: 87.3%
Files under threshold: 12/156 (7.7%)
Methods under threshold: 34/1,205 (2.8%)
```

### JSON Format
```json
{
  "threshold": 85,
  "analysis_timestamp": "2025-01-27T10:30:00Z",
  "summary": {
    "total_files": 156,
    "total_methods": 1205,
    "overall_coverage_percentage": 87.3,
    "under_covered_files_count": 12,
    "under_covered_methods_count": 34
  },
  "under_covered_files": [
    {
      "file_path": "lib/atoms/coverage_file_reader.rb",
      "coverage_percentage": 67.8,
      "total_lines": 150,
      "covered_lines": 102,
      "methods": [
        {
          "name": "parse_json_file",
          "start_line": 25,
          "end_line": 45,
          "coverage_percentage": 40.0,
          "total_lines": 20,
          "covered_lines": 8
        }
      ]
    }
  ]
}
```

### CSV Format
```csv
Type,File,Method,Coverage,Covered Lines,Total Lines,Start Line,End Line
file,lib/atoms/coverage_file_reader.rb,,67.8,102,150,,
method,lib/atoms/coverage_file_reader.rb,parse_json_file,40.0,8,20,25,45
method,lib/atoms/coverage_file_reader.rb,validate_structure,75.0,12,16,47,62
```

## Implementation Notes

1. **Coverage Calculation**: Lines marked as `null` are not executable and should not count toward coverage
2. **Method Detection**: Use Parser gem to extract method definitions with accurate line ranges
3. **File Filtering**: Support filtering by file patterns (e.g., exclude spec files, include only lib files)
4. **Performance**: Process files in parallel where possible for large codebases
5. **Error Handling**: Graceful handling of malformed JSON, unparseable Ruby files, and missing files