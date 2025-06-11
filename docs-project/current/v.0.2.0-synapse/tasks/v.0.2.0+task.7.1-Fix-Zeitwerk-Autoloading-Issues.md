---
id: v.0.2.0+task.7.1
status: done
priority: high
estimate: 2h
dependencies: ["v.0.2.0+task.7"]
parent_task: v.0.2.0+task.7
---

# Fix Zeitwerk Autoloading Issues

## Problem Analysis

After implementing Zeitwerk autoloading in task v.0.2.0+task.7, several test failures are occurring due to class naming convention mismatches. Zeitwerk expects specific naming conventions where file names in snake_case map to class names in PascalCase.

### Root Cause

The main issue is that files like `http_request_builder.rb` define classes named `HTTPRequestBuilder` but Zeitwerk expects `HttpRequestBuilder` based on the file name. Zeitwerk follows strict naming conventions:
- `http_request_builder.rb` → `HttpRequestBuilder` (not `HTTPRequestBuilder`)
- Acronyms should only have the first letter capitalized in class names when using Zeitwerk

### Failing Tests

```
Zeitwerk::NameError:
  expected file /Users/.../http_request_builder.rb to define constant CodingAgentTools::Molecules::HttpRequestBuilder, but didn't
```

## Objective

Fix all Zeitwerk autoloading issues by ensuring class names follow Zeitwerk's naming conventions while maintaining backward compatibility where possible.

## Scope of Work

### Files to Investigate and Fix

1. **HTTPRequestBuilder** (`lib/coding_agent_tools/molecules/http_request_builder.rb`)
   - Current: `class HTTPRequestBuilder`  
   - Expected by Zeitwerk: `class HttpRequestBuilder`

2. **HTTPClient** (`lib/coding_agent_tools/atoms/http_client.rb`)
   - Current: `class HTTPClient`
   - Expected by Zeitwerk: `class HttpClient`

3. **JSONFormatter** (if exists - `lib/coding_agent_tools/atoms/json_formatter.rb`)
   - Current: `class JSONFormatter`  
   - Expected by Zeitwerk: `class JsonFormatter`

4. **Any other classes with acronyms in ALL CAPS**

### Potential Solutions

**Option A: Rename Classes (Breaking Change)**
- Rename all classes to follow Zeitwerk conventions
- Update all references throughout the codebase
- Update all tests
- Update any external documentation

**Option B: Configure Zeitwerk Inflections (Recommended)**
- Configure Zeitwerk to handle our existing acronym conventions
- Maintain existing class names
- No breaking changes for consumers

**Option C: Hybrid Approach**
- Configure Zeitwerk inflections for backward compatibility
- Gradually migrate to standard conventions in future versions

## Implementation Plan

### Phase 1: Configure Zeitwerk Inflections (Quick Fix) ✅ COMPLETED

1. **Update Zeitwerk configuration** in `lib/coding_agent_tools.rb`: ✅ DONE
   ```ruby
   loader.inflector.inflect(
     "http_client" => "HTTPClient",
     "http_request_builder" => "HTTPRequestBuilder", 
     "json_formatter" => "JSONFormatter"
   )
   ```

2. **Test the configuration**: ✅ VERIFIED
   ```bash
   ruby -e "require './lib/coding_agent_tools'; puts CodingAgentTools::Molecules::HTTPRequestBuilder.inspect"
   ```

### Phase 2: Verify All Autoloading Works ✅ COMPLETED

1. **Run focused tests** to verify classes load correctly: ✅ VERIFIED
   ```bash
   bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb --format documentation
   ```
   Note: Classes now load correctly. Remaining test failures are method signature issues (task 7.2).

2. **Check all classes can be autoloaded**: ✅ VERIFIED
   ```bash
   ruby -e "require './lib/coding_agent_tools'; puts [
     CodingAgentTools::Atoms::HTTPClient,
     CodingAgentTools::Molecules::HTTPRequestBuilder,
     CodingAgentTools::Atoms::JSONFormatter
   ].map(&:name)"
   ```

### Phase 3: Long-term Planning (Future Task)

Document the decision to either:
- Keep current naming with inflections
- Plan migration to standard Zeitwerk conventions in v0.3.0

## Testing Strategy

### Manual Tests

1. **Basic autoloading test**:
   ```bash
   ruby -e "require './lib/coding_agent_tools'; puts CodingAgentTools::Molecules::HTTPRequestBuilder.new.class"
   ```

2. **All atoms/molecules load test**:
   ```bash
   ruby -e "require './lib/coding_agent_tools'; Dir['lib/coding_agent_tools/{atoms,molecules}/*.rb'].each { |f| puts File.basename(f, '.rb') }"
   ```

### Automated Tests

Run the failing test to verify the fix:
```bash
bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb
```

## Deliverables

### Modified Files

- `lib/coding_agent_tools.rb` - Updated Zeitwerk configuration with inflections

### Tests

- All existing tests should pass without modification
- No new tests needed for this fix (it's infrastructure)

## Acceptance Criteria

- [x] AC1: All classes with acronyms (HTTP, JSON, etc.) can be autoloaded via Zeitwerk
- [x] AC2: Test `CodingAgentTools::Molecules::HTTPRequestBuilder` loads without error
- [x] AC3: Test `CodingAgentTools::Atoms::HTTPClient` loads without error  
- [ ] AC4: All existing unit tests for molecules/atoms pass (blocked by method signature issues - task 7.2)
- [x] AC5: No breaking changes for external consumers
- [x] AC6: `require 'coding_agent_tools'` successfully loads all classes

## Risk Assessment

**Low Risk**: This is a configuration change that maintains existing public API.

**Mitigation**: If inflections don't work, we can quickly revert and rename classes as Plan B.

## References

- [Zeitwerk Documentation - Inflections](https://github.com/fxn/zeitwerk#inflections)
- [Ruby Naming Conventions](https://rubystyle.guide/#naming-conventions) 
- [Original Task v.0.2.0+task.7](v.0.2.0+task.7-Implement-Code-Quality-Improvements.md)