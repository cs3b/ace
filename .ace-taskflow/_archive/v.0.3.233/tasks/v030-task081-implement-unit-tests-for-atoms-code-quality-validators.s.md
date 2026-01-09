---
id: v.0.3.0+task.081
status: done
priority: high
estimate: 5h
dependencies: [v.0.3.0+task.079, v.0.3.0+task.080]
---

# Implement unit tests for Atoms Code Quality validators

## Objective

Implement comprehensive unit tests for 8 code quality validation atoms that handle linting, format validation, error distribution, and content analysis. These components are critical for code quality enforcement and require thorough testing with realistic scenarios.

**Target Coverage**: 95% for each component
**Estimated Effort**: 5 hours
**Files to Test**: 8 files (542 relevant lines total)

## Scope of Work

### Files to Test

#### Code Quality Validators (6 files)
- `lib/coding_agent_tools/atoms/code_quality/cassettes_validator.rb` (68 lines) - VCR cassette validation
- `lib/coding_agent_tools/atoms/code_quality/error_distributor.rb` (65 lines) - Error categorization and distribution
- `lib/coding_agent_tools/atoms/code_quality/kramdown_formatter.rb` (68 lines) - Markdown formatting with Kramdown
- `lib/coding_agent_tools/atoms/code_quality/markdown_link_validator.rb` (77 lines) - Validate markdown links
- `lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb` (111 lines) - StandardRB linting integration
- `lib/coding_agent_tools/atoms/code_quality/task_metadata_validator.rb` (147 lines) - Validate task file metadata

#### Specialized Validators (2 files)
- `lib/coding_agent_tools/atoms/code_quality/path_resolver.rb` (61 lines) - Path resolution for linting contexts
- `lib/coding_agent_tools/atoms/code_quality/template_embedding_validator.rb` (83 lines) - Validate embedded templates

## Implementation Plan

### Planning Steps

- [ ] Analyze validation logic and error handling patterns for each component
- [ ] Create test fixtures for various code quality scenarios (valid/invalid code, links, metadata)
- [ ] Design mocking strategies for external tools (StandardRB, file system, HTTP requests)
- [ ] Plan realistic test data representing actual usage scenarios

### Execution Steps

#### Phase 1: Format and Content Validators (2h)

- [ ] Implement comprehensive tests for `kramdown_formatter.rb`
  - Test markdown parsing and formatting with various structures
  - Test handling of code blocks, tables, links, and special characters
  - Test error handling for malformed markdown
  - Test output format consistency and options
  - Mock file I/O operations for content processing

- [ ] Implement comprehensive tests for `markdown_link_validator.rb`
  - Test validation of internal and external links
  - Test handling of relative and absolute URLs
  - Test detection of broken links and invalid references
  - Test performance with large documents containing many links
  - Mock HTTP requests for external link validation

- [ ] Implement comprehensive tests for `template_embedding_validator.rb`
  - Test validation of XML template syntax
  - Test detection of missing or malformed template markers
  - Test handling of nested templates and complex structures
  - Test synchronization validation between templates and content

#### Phase 2: Code Analysis and Linting (2h)

- [ ] Implement comprehensive tests for `standard_rb_validator.rb`
  - Test StandardRB integration with various Ruby code samples
  - Test handling of configuration files and custom rules
  - Test error reporting and formatting
  - Test autofix functionality and validation
  - Mock StandardRB command execution for controlled testing

- [ ] Implement comprehensive tests for `cassettes_validator.rb`
  - Test VCR cassette file validation and size checking
  - Test detection of oversized or corrupted cassettes
  - Test handling of various cassette formats and structures
  - Test cleanup recommendations and automated fixes
  - Mock file system operations for cassette inspection

- [ ] Implement comprehensive tests for `task_metadata_validator.rb`
  - Test validation of YAML frontmatter in task files
  - Test required field validation and format checking
  - Test dependency validation and circular dependency detection
  - Test status transition validation and business rules
  - Test handling of malformed metadata and edge cases

#### Phase 3: Error Management and Path Resolution (1h)

- [ ] Implement comprehensive tests for `error_distributor.rb`
  - Test error categorization by type and severity
  - Test distribution algorithms for balanced error reporting
  - Test filtering and prioritization logic
  - Test aggregation of errors across multiple files
  - Test performance with large error datasets

- [ ] Implement comprehensive tests for `path_resolver.rb`
  - Test path resolution in various project contexts
  - Test handling of absolute and relative paths
  - Test security validation and path traversal prevention
  - Test integration with project structure detection
  - Test caching and performance optimization

## Testing Patterns and Requirements

### External Tool Mocking
```ruby
# Mock StandardRB execution
before do
  mock_system_command("standardrb --format json", 
    success: true, 
    output: json_lint_results
  )
end

# Mock HTTP requests for link validation
before do
  stub_request(:get, "https://example.com")
    .to_return(status: 200, body: "OK")
end
```

### Validation Testing Patterns
```ruby
# Test both valid and invalid scenarios
context "with valid input" do
  it "returns success result" do
    result = validator.validate(valid_input)
    expect(result[:valid]).to be true
    expect(result[:errors]).to be_empty
  end
end

context "with invalid input" do
  it "returns detailed error information" do
    result = validator.validate(invalid_input)
    expect(result[:valid]).to be false
    expect(result[:errors]).to include("specific error message")
  end
end
```

### Performance Testing
- Test with large files and datasets
- Test timeout handling for external tool execution
- Test memory usage with extensive validation operations
- Test concurrent validation scenarios

### Error Handling Testing
- Test malformed input handling
- Test external tool failures and fallback behavior
- Test network connectivity issues for link validation
- Test file permission and access errors

## Deliverables

### Test Files to Create (8 files)
- `spec/coding_agent_tools/atoms/code_quality/cassettes_validator_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/error_distributor_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/kramdown_formatter_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/markdown_link_validator_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/path_resolver_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/standard_rb_validator_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/task_metadata_validator_spec.rb`
- `spec/coding_agent_tools/atoms/code_quality/template_embedding_validator_spec.rb`

### Test Data and Fixtures
- Sample Ruby code files with various linting issues
- Valid and invalid markdown files with different link types
- Sample VCR cassettes of various sizes and formats
- Task metadata files with valid and invalid YAML frontmatter
- Template files with various embedding scenarios

## Acceptance Criteria

- [ ] All 8 code quality validator atoms have comprehensive unit tests with 95%+ coverage
- [ ] All external tool dependencies (StandardRB, HTTP requests) are properly mocked
- [ ] Security validation is thoroughly tested (path traversal, injection attacks)
- [ ] Performance edge cases are covered (large files, many errors, timeouts)
- [ ] Error conditions and boundary cases are comprehensively tested
- [ ] All tests follow established ATOM testing patterns with proper isolation
- [ ] Integration with existing shared helpers and factories is seamless
- [ ] Test execution is fast and reliable in CI environment

## Dependencies

- **task.79**: Infrastructure and shared helpers must be completed
- **task.80**: Core foundation atoms may be dependencies for some validators
- **WebMock gem**: For HTTP request mocking in link validation tests
- **Realistic test data**: Representative code samples and configurations

## Success Metrics

- **Coverage Target**: 95% line coverage for all 8 components
- **Test Count**: 20-30 test cases per component (160-240 total)
- **Performance**: Test suite completes in < 25 seconds
- **External Dependencies**: All external tool calls properly mocked
- **Reliability**: Consistent behavior across different development environments