---
id: v.0.3.0+task.223
status: completed
priority: high
estimate: 3h
dependencies: []
completed_at: 2025-07-29T06:59:00Z
---

# Refactor coverage calculation to eliminate duplicate logic and fix percentage discrepancy

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 .ace/tools/lib/coding_agent_tools | grep -E "(coverage|analyzer)" | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── atoms/
    │   ├── coverage_calculator.rb
    │   └── coverage_file_reader.rb
    ├── molecules/
    │   └── coverage_data_processor.rb
    ├── organisms/
    │   ├── coverage_analyzer.rb
    │   ├── coverage_report_generator.rb
    │   └── undercovered_items_extractor.rb
```

## Objective

Fix the coverage percentage discrepancy where the JSON output shows 8.78% while SimpleCov reports 16.09% for the same file. This occurs because there are two separate coverage calculation pipelines with different logic:

1. **Main Pipeline**: `CoverageDataProcessor` → `CoverageCalculator.calculate_combined_coverage()` (produces JSON output)
2. **Adaptive Threshold Pipeline**: `CoverageAnalyzer.extract_coverage_data()` (duplicate calculation logic)

The duplicate logic in `extract_coverage_data()` creates inconsistency and maintenance burden. We need to unify both pipelines to use the same `CoverageCalculator` atom.

## Scope of Work

- Remove duplicate coverage calculation logic from `CoverageAnalyzer.extract_coverage_data()` method
- Replace with calls to existing `CoverageCalculator.calculate_file_coverage()` method  
- Ensure both main pipeline and adaptive threshold calculation produce identical coverage percentages
- Verify the fix resolves the 8.78% vs 16.09% discrepancy

### Deliverables

#### Modify

- `lib/coding_agent_tools/organisms/coverage_analyzer.rb` (lines 230-234 in `extract_coverage_data()` method)

#### Verify

- Coverage percentages match between JSON output and SimpleCov values
- Adaptive threshold calculation uses correct coverage data
- Both pipelines produce identical results

## Phases

1. **Audit**: Confirm current duplicate calculation logic and its location
2. **Refactor**: Replace duplicate logic with `CoverageCalculator` calls
3. **Test**: Verify unified calculation produces correct percentages
4. **Validate**: Confirm adaptive threshold works with accurate data

## Implementation Plan

### Planning Steps

- [ ] Analyze current `extract_coverage_data()` method to confirm duplicate logic location
  > TEST: Code Analysis Check
  > Type: Pre-condition Check  
  > Assert: Duplicate coverage calculation identified at lines 230-234
  > Command: grep -n "executable_lines.*count.*nil" .ace/tools/lib/coding_agent_tools/organisms/coverage_analyzer.rb

- [ ] Verify `CoverageCalculator` dependency is available in `CoverageAnalyzer`
  > TEST: Dependency Check
  > Type: Architecture Validation
  > Assert: CoverageAnalyzer has access to CoverageCalculator instance
  > Command: grep -n "calculator.*CoverageCalculator" .ace/tools/lib/coding_agent_tools/organisms/coverage_analyzer.rb

### Execution Steps

- [ ] Replace duplicate calculation logic in `extract_coverage_data()` method (lines 230-234)
  - Remove: `executable_lines = line_data.count { |line| !line.nil? }`
  - Remove: `covered_lines = line_data.count { |line| line.is_a?(Integer) && line > 0 }`  
  - Remove: `coverage_percentage = (covered_lines.to_f / executable_lines * 100).round(2)`
  - Add: `coverage_result = @calculator.calculate_file_coverage(line_data)`
  - Add: `coverage_percentage = coverage_result[:coverage_percentage]`

- [ ] Ensure `CoverageAnalyzer` has proper `CoverageCalculator` dependency injection
  > TEST: Dependency Injection Check
  > Type: Architecture Validation
  > Assert: CoverageAnalyzer constructor accepts and uses CoverageCalculator
  > Command: grep -A 10 "def initialize" .ace/tools/lib/coding_agent_tools/organisms/coverage_analyzer.rb

- [ ] Test unified calculation with real SimpleCov data
  > TEST: Coverage Calculation Accuracy
  > Type: Integration Test
  > Assert: JSON output coverage percentage matches SimpleCov values (16.09% not 8.78%)
  > Command: bundle exec exe/coverage-analyze coverage.resultset.json --format json | grep "coverage_percentage"

- [ ] Verify adaptive threshold algorithm works with corrected coverage data
  > TEST: Adaptive Threshold Validation
  > Type: Algorithm Test
  > Assert: Adaptive threshold can now find 6+ files when coverage distribution allows
  > Command: bundle exec exe/coverage-analyze coverage.resultset.json --threshold auto

## Acceptance Criteria

- [ ] AC 1: Duplicate coverage calculation logic removed from `extract_coverage_data()` method
- [ ] AC 2: Both main pipeline and adaptive threshold use same `CoverageCalculator` atom  
- [ ] AC 3: JSON output coverage percentages match SimpleCov values (no more 8.78% vs 16.09% discrepancy)
- [ ] AC 4: Adaptive threshold algorithm receives accurate coverage data and can prefer 6+ files
- [ ] AC 5: All existing coverage analyzer tests continue to pass

## Out of Scope

- ❌ Modifying the core `CoverageCalculator` atom logic (it's already correct)
- ❌ Changing the SimpleCov data format or structure
- ❌ Refactoring other coverage-related components beyond `CoverageAnalyzer`
- ❌ Adding new coverage calculation features or algorithms

## References

- **Root Issue**: Coverage percentage mismatch (8.78% vs 16.09%)
- **Architecture**: ATOM pattern - reuse existing `CoverageCalculator` atom
- **Files**: `lib/coding_agent_tools/organisms/coverage_analyzer.rb` (extract_coverage_data method)
- **Testing**: Use real SimpleCov resultset.json for validation