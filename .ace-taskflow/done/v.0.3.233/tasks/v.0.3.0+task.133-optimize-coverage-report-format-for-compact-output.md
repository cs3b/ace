---
id: v.0.3.0+task.133
status: done
priority: high
estimate: 6h
dependencies: [v.0.3.0+task.131]
---

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/molecules | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/tools/lib/coding_agent_tools/molecules
├── coverage_data_processor.rb
├── executable_wrapper.rb
├── file_analyzer.rb
├── method_coverage_mapper.rb
├── report_formatter.rb
└── ... (other molecule files)
```

## Objective

Dramatically reduce coverage report file sizes (currently 3.1MB+ with 162K+ lines) by implementing compact line range formatting. Replace verbose individual line listings with compact range notation (e.g., "11..13,22,23,25..28") while maintaining all essential information for targeted testing.

## Scope of Work

- Create compact range formatter utility to convert arrays of line numbers into compact string ranges
- Update JSON report structure to use compact format instead of verbose arrays
- Implement backward compatibility with optional verbose mode via CLI flag
- Update text reports to display compact ranges for readability
- Test with real large coverage files to verify size reduction and functionality
- Maintain all essential information developers need for targeted testing

### Deliverables

#### Create

- `lib/coding_agent_tools/atoms/compact_range_formatter.rb` - Utility for converting line arrays to compact ranges
- Tests for compact range formatter with various edge cases

#### Modify

- `lib/coding_agent_tools/molecules/report_formatter.rb` - Update JSON and text formatting to use compact ranges
- `lib/coding_agent_tools/models/method_coverage.rb` - Add compact range methods
- `lib/coding_agent_tools/models/coverage_result.rb` - Add compact range methods
- `lib/coding_agent_tools/cli/commands/coverage/analyze.rb` - Add --compact/--verbose flags
- Related test files to verify compact format functionality

## Phases

1. Design compact range formatter with comprehensive edge case handling
2. Implement formatter utility with thorough testing
3. Update models to support compact range output
4. Modify report formatters to use compact format
5. Add CLI flags for format control
6. Test with real coverage data and verify size reduction

## Implementation Plan

### Planning Steps

- [x] Analyze current report format and identify optimization opportunities
  > TEST: Format Analysis Complete
  > Type: Pre-condition Check
  > Assert: Current verbose format is documented and size impact measured
  > Command: Already completed - current format is 3.1MB+ with individual line arrays
- [ ] Research optimal compact range notation and edge cases
  > TEST: Range Format Design
  > Type: Design Validation
  > Assert: Compact format handles all edge cases (single lines, consecutive ranges, mixed patterns)
  > Command: Manual verification of format examples: "5", "11..13", "11..13,22,23,25..28"
- [ ] Design backward compatibility strategy for existing integrations

### Execution Steps

- [ ] Create CompactRangeFormatter atom with comprehensive functionality
  > TEST: Formatter Implementation
  > Type: Unit Test Validation
  > Assert: Formatter correctly converts various line number patterns to compact ranges
  > Command: bin/test --check lib/coding_agent_tools/atoms/compact_range_formatter_spec.rb
- [ ] Update MethodCoverage model to include compact range methods
- [ ] Update CoverageResult model to include compact range methods
- [ ] Modify ReportFormatter to use compact format for JSON output
  > TEST: JSON Format Validation
  > Type: Integration Test
  > Assert: JSON reports use compact ranges and are significantly smaller
  > Command: bin/test --check JSON report size is <10% of original
- [ ] Update text report formatting to display compact ranges
- [ ] Add CLI flags (--compact default, --verbose for old format) to coverage analyze command
- [ ] Test with real SimpleCov data to verify size reduction and functionality
  > TEST: Real Data Validation
  > Type: Integration Test
  > Assert: Reports maintain essential information while achieving 90%+ size reduction
  > Command: coverage-analyze coverage/.resultset.json --compact

## Acceptance Criteria

- [ ] Coverage reports reduced by 90%+ in file size while maintaining essential information
- [ ] Compact range format correctly handles all edge cases (single lines, ranges, mixed patterns)
- [ ] Backward compatibility maintained via --verbose flag for existing integrations
- [ ] All existing tests pass with compact format as default
- [ ] Text reports display readable compact ranges for developer guidance
- [ ] JSON structure uses compact format for programmatic consumption

## Out of Scope

- ❌ Changing core coverage calculation logic or data structures
- ❌ Modifying SimpleCov input processing or file filtering
- ❌ Altering method detection or visibility analysis functionality
- ❌ Performance optimizations beyond format compactness

## References

- Example format comparison in `.ace/tools/coverage_analysis/example-a-vs-b.txt`
- Current ReportFormatter implementation in `lib/coding_agent_tools/molecules/report_formatter.rb`
- Related task v.0.3.0+task.131 which implemented the coverage analysis tool
