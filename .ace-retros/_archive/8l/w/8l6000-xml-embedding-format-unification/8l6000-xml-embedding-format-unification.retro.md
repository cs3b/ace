---
id: 8l6000
title: 'Retro: XML Embedding Format Unification in ace-context'
type: conversation-analysis
tags: []
created_at: '2025-10-07 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8l6000-xml-embedding-format-unification.md"
---

# Retro: XML Embedding Format Unification in ace-context

**Date**: 2025-10-07
**Context**: Fixing formatter inconsistency between protocol and preset loading in ace-context
**Author**: Development Team
**Type**: Conversation Analysis

## What Went Well

- Rapid issue identification through user-provided test cases (clear examples of both formats)
- Comprehensive understanding achieved quickly by reading both `context_loader.rb` and `output_formatter.rb`
- All 53 existing tests continued to pass without modification
- Pre-1.0 status allowed breaking change without backward compatibility burden
- Clear separation of concerns in ATOM architecture made the fix straightforward

## What Could Be Improved

- The inconsistency existed because two different code paths (`load_template()` vs `load_preset()`) had diverged
- No integration test comparing output formats between loading methods
- Documentation didn't clearly specify which format would be used in different scenarios
- The `format_embedded_source()` trigger condition (`data[:content]` presence) was implicit rather than explicit

## Key Learnings

- **Code Path Divergence**: When multiple paths produce similar outputs, they need explicit tests to ensure consistency
- **Format Selection Logic**: The decision to use XML vs markdown formatting was based on `data[:content]` presence, which was not immediately obvious
- **Pre-1.0 Benefits**: Breaking changes are acceptable and even encouraged to remove technical debt before 1.0
- **User Feedback Value**: Direct comparison examples (`grep "<file"` vs `grep "## docs"`) made the issue crystal clear

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Format Inconsistency Between Loading Methods**: Different output formats for same `embed_document_source: true` configuration
  - Occurrences: Affected all preset loading with embedded sources
  - Impact: Inconsistent parsing logic needed, LLM agents confused by different formats
  - Root Cause: `load_from_preset_config()` didn't set `context.content`, preventing XML formatter from triggering

#### Medium Impact Issues

- **Implicit Format Selection Logic**: Format choice based on presence of `data[:content]` rather than explicit configuration
  - Occurrences: Throughout `OutputFormatter` class
  - Impact: Required code reading to understand format selection behavior
  - Root Cause: Dual-purpose formatter with implicit decision point

### Improvement Proposals

#### Process Improvements

- Add integration tests comparing output formats across different loading methods
- Create explicit format selection tests for each loading path
- Document format selection logic in README and CHANGELOG
- Add validation that all loading paths with same config produce same format

#### Tool Enhancements

- Consider explicit `format` parameter validation before processing
- Add debug logging for format selection decisions
- Create format comparison utility for testing

#### Communication Protocols

- When reporting formatting bugs, include both expected and actual output examples
- Use `grep` or similar tools to highlight specific format differences
- Provide before/after comparisons for breaking changes

## Action Items

### Stop Doing

- Relying on implicit conditions for format selection without documentation
- Allowing code paths to diverge without integration tests
- Accepting inconsistent output formats across similar operations

### Continue Doing

- Making breaking changes pre-1.0 to avoid technical debt
- Using ATOM architecture for clear separation of concerns
- Comprehensive testing with 53 tests ensuring reliability
- Clear CHANGELOG documentation of breaking changes

### Start Doing

- Add cross-loading-method integration tests for format consistency
- Document format selection logic explicitly in code comments
- Create format validation utilities for testing
- Use explicit format configuration rather than implicit triggers where possible

## Technical Details

### Files Modified

1. **context_loader.rb** (lines 345-353, 53-56):
   - Added `context.content = preset[:body]` when `embed_document_source: true`
   - Changed default format to `markdown-xml` for embedded sources

2. **version.rb**: Bumped 0.11.3 → 0.11.4

3. **CHANGELOG.md**: Documented breaking change with migration notes

4. **README.md**: Added XML format examples

### Format Selection Logic

The fix leveraged existing `OutputFormatter` logic:

```ruby
# In format_markdown() and format_markdown_xml()
if data[:content] && !data[:content].to_s.empty?
  return format_embedded_source(data)  # XML format
end
```

Previously, only protocol loading set `data[:content]`, now preset loading also sets it when `embed_document_source: true`.

### Testing Results

- All 53 tests passed (133 assertions)
- No test modifications required
- Verified consistency: Both loading methods now produce identical XML format

## Additional Context

**Commit**: 03d6514a feat(context): Unify XML embedding format for presets and protocols

**User Insight**: "we should use only xml for embeding results, as resutls can be markdownd file on itself and we break nesting, and the xml tags make it more clear for llm agents where the file stards and ends"

This retro captures the efficient resolution of a format inconsistency bug through clear problem identification, targeted fix, and comprehensive documentation.