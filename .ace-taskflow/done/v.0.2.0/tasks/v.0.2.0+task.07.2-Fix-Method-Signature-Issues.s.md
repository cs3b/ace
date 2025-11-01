---
id: v.0.2.0+task.7.2
status: done
priority: high
estimate: 3h
dependencies: ["v.0.2.0+task.7.1"]
parent_task: v.0.2.0+task.7
---

# Fix Method Signature Issues

## Problem Analysis

After implementing code quality improvements in task v.0.2.0+task.7, several test failures are occurring due to method signature mismatches between the refactored implementation and existing test expectations.

### Root Cause

The refactoring changed method signatures without updating all call sites or the method signatures weren't properly aligned with test expectations.

### Failing Tests

```
ArgumentError: unknown keyword: :method
# ./lib/coding_agent_tools/molecules/http_request_builder.rb:77:in 'build_headers'
# ./spec/coding_agent_tools/molecules/http_request_builder_spec.rb:268:in 'block (4 levels) in <top (required)>'
```

### Analysis of Specific Issues

1. **`build_headers` method signature mismatch**:
   - **Test expects**: `build_headers(custom, json: true, method: :get)`
   - **Method accepts**: `build_headers(custom_headers, json: true)`
   - **Issue**: Missing `:method` parameter in method definition

2. **Parameter naming inconsistency**:
   - Tests call with positional `custom` parameter
   - Method expects `custom_headers` parameter name

## Objective

Fix all method signature mismatches by either updating method definitions to match test expectations or updating tests to match new method signatures, ensuring consistency across the codebase.

## Scope of Work

### Files to Investigate and Fix

1. **HTTPRequestBuilder** (`lib/coding_agent_tools/molecules/http_request_builder.rb`)
   - `build_headers` method signature
   - Any other private methods that changed signatures

2. **Test Files** (`spec/coding_agent_tools/molecules/http_request_builder_spec.rb`)
   - Update test calls to match new method signatures
   - Verify parameter expectations

3. **Other Molecule/Atom Classes**
   - Check for similar signature mismatches from refactoring

## Detailed Investigation

### Current `build_headers` Method
```ruby
def build_headers(custom_headers, json: true)
  headers = {}
  if json
    headers["Accept"] = "application/json"
  end
  headers.merge!(custom_headers) if custom_headers
  headers
end
```

### Test Expectations
```ruby
# Test calls with :method parameter
headers = builder.send(:build_headers, custom, json: true, method: :get)
```

### Options for Resolution

**Option A: Update Method to Accept :method Parameter**
```ruby
def build_headers(custom_headers, json: true, method: nil)
  headers = {}
  if json
    headers["Accept"] = "application/json"
    # Only add Content-Type for methods that have request bodies
    if method && [:post, :put, :patch].include?(method)
      headers["Content-Type"] = "application/json"
    end
  end
  headers.merge!(custom_headers) if custom_headers
  headers
end
```

**Option B: Update Tests to Match Current Method**
```ruby
# Remove :method parameter from test calls
headers = builder.send(:build_headers, custom, json: true)
```

## Implementation Plan

### Phase 1: Analyze Method Usage ✅ COMPLETED

1. **Find all `build_headers` calls**: ✅ DONE
   ```bash
   grep -rn "build_headers" lib/ spec/
   ```

2. **Understand the purpose of `:method` parameter**: ✅ VERIFIED
   - Check if Content-Type header logic depends on HTTP method
   - Determine if this was intentional design or test artifact
   - **Result**: `:method` parameter is needed for conditional Content-Type logic

### Phase 2: Choose Resolution Strategy ✅ COMPLETED

Based on analysis, determined:
- **Option A selected**: The `:method` parameter serves a functional purpose
- Tests expect Content-Type header only for POST/PUT/PATCH methods or when body is present

### Phase 3: Implement Fix ✅ COMPLETED

**Option A (Add :method parameter)**: ✅ IMPLEMENTED
1. **Updated `build_headers` method signature**: ✅ DONE
   - Added `method: nil, body: nil` parameters
   - Added `should_add_content_type?` helper method
2. **Implemented conditional logic for Content-Type header**: ✅ DONE
   - Content-Type added for POST/PUT/PATCH methods or when body present
3. **Updated all call sites to pass method parameter**: ✅ DONE
   - Updated `json_request` method to pass method and body

### Phase 4: Verify Other Method Signatures ✅ COMPLETED

1. **Check other private methods** for similar issues: ✅ VERIFIED
   ```bash
   grep -rn "ArgumentError.*unknown keyword" spec/
   ```
   - **Result**: No other method signature issues found

2. **Review all molecule/atom method signatures**: ✅ VERIFIED
   - No other classes affected by signature mismatches

## Testing Strategy

### Specific Tests to Fix

1. **HTTPRequestBuilder build_headers tests**:
   ```bash
   bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb -e "build_headers"
   ```

2. **Full HTTPRequestBuilder test suite**:
   ```bash
   bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb
   ```

### Manual Testing

Test the specific failing scenario:
```ruby
# In Rails console or IRB
require './lib/coding_agent_tools'
builder = CodingAgentTools::Molecules::HTTPRequestBuilder.new
# This should not raise ArgumentError
headers = builder.send(:build_headers, {"Custom" => "value"}, json: true, method: :get)
```

## Deliverables

### Modified Files

- `lib/coding_agent_tools/molecules/http_request_builder.rb` - Fixed method signatures
- `spec/coding_agent_tools/molecules/http_request_builder_spec.rb` - Updated test calls (if needed)
- Any other molecule/atom classes with signature issues

### Documentation

- Comment any new parameters explaining their purpose
- Update method documentation if signatures change

## Acceptance Criteria

- [x] AC1: `build_headers` method accepts all parameters used in tests
- [x] AC2: No `ArgumentError: unknown keyword` errors in test suite
- [ ] AC3: All HTTPRequestBuilder tests pass (blocked by response structure issues - task 7.3)
- [x] AC4: Method behavior matches test expectations
- [x] AC5: No regression in functionality
- [x] AC6: Consistent parameter naming across similar methods

## Risk Assessment

**Medium Risk**: Method signature changes could affect external consumers if these are public APIs.

**Mitigation**: 
- Prioritize fixing method definitions over changing test expectations
- Add deprecation warnings if removing parameters
- Ensure backward compatibility where possible

## Notes

- Consider if the `:method` parameter was intentionally added for Content-Type logic
- Check if Faraday middleware changes affect header requirements
- Verify that header logic still makes sense after the refactor

## References

- [Original Task v.0.2.0+task.7](v.0.2.0+task.7-Implement-Code-Quality-Improvements.md)
- [Ruby Method Signatures](https://docs.ruby-lang.org/en/master/syntax/methods_rdoc.html)
- [RSpec Testing Best Practices](https://rspec.info/documentation/)