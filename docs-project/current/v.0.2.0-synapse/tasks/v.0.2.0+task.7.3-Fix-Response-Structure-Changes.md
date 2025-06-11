---
id: v.0.2.0+task.7.3
status: to-do
priority: high
estimate: 4h
dependencies: ["v.0.2.0+task.7.2"]
parent_task: v.0.2.0+task.7
---

# Fix Response Structure Changes

## Problem Analysis

After implementing code quality improvements in task v.0.2.0+task.7, several test failures are occurring due to changes in the response structure returned by HTTP request methods. The refactoring altered how responses are parsed and what data is included in the response hash.

### Root Cause

The refactoring changed the response structure by:
1. Removing the `:raw_body` field from response hashes
2. Modifying JSON parsing behavior due to Faraday middleware changes
3. Changing how response bodies are processed and returned

### Failing Tests

```
1) CodingAgentTools::Molecules::HTTPRequestBuilder#json_request with GET request makes a GET request with JSON headers
   Failure/Error: expect(result[:raw_body]).to eq('{"users": [{"id": 1, "name": "John"}]}')
   
   expected: "{\"users\": [{\"id\": 1, \"name\": \"John\"}]}"
        got: nil

2) CodingAgentTools::Molecules::HTTPRequestBuilder private methods #parse_response parses JSON response when content-type is JSON
   Failure/Error: expect(result[:body]).to eq({key: "value"})
   
   expected: {key: "value"}
        got: "{\"key\": \"value\"}"
```

### Analysis of Specific Issues

1. **Missing `:raw_body` field**:
   - Tests expect both `:body` (parsed) and `:raw_body` (string) in response
   - Current implementation only returns `:body`

2. **JSON parsing not working**:
   - Tests expect parsed JSON objects `{key: "value"}`
   - Getting raw JSON strings `"{\"key\": \"value\"}"`
   - Suggests Faraday JSON middleware isn't parsing responses

3. **Response structure inconsistency**:
   - Some tests expect specific response format
   - Refactored code returns different structure

## Objective

Restore the expected response structure while maintaining the benefits of the Faraday middleware refactor. Ensure backward compatibility with existing test expectations and external consumers.

## Scope of Work

### Files to Investigate and Fix

1. **HTTPRequestBuilder** (`lib/coding_agent_tools/molecules/http_request_builder.rb`)
   - `parse_response` method
   - Response structure returned by `json_request`

2. **HTTPClient** (`lib/coding_agent_tools/atoms/http_client.rb`)
   - Faraday middleware configuration
   - JSON parsing middleware setup

3. **Test Files** (`spec/coding_agent_tools/molecules/http_request_builder_spec.rb`)
   - Verify test expectations are reasonable
   - Update tests if new structure is intentionally different

## Detailed Investigation

### Current `parse_response` Method
```ruby
def parse_response(response, json: true)
  {
    status: response.status,
    headers: response.headers.to_h,
    success: response.success?,
    body: response.body  # May be parsed or raw depending on middleware
  }
end
```

### Expected Response Structure (Based on Tests)
```ruby
{
  status: 200,
  headers: {...},
  success: true,
  body: {parsed: "json_object"},     # Parsed JSON
  raw_body: "{\"parsed\":\"json_object\"}"  # Original JSON string
}
```

### Current Faraday Middleware Setup
```ruby
# In HTTPClient
faraday.response :json, parser_options: {symbolize_names: true}
```

## Root Cause Analysis

### Issue 1: Missing `:raw_body`
The refactor removed `:raw_body` from the response hash, but tests and possibly external consumers expect it.

**Solution Options**:
- **Option A**: Restore `:raw_body` by capturing raw response before parsing
- **Option B**: Update tests to not expect `:raw_body` (breaking change)

### Issue 2: JSON Not Being Parsed
The Faraday JSON middleware should parse responses automatically, but it's not working.

**Potential Causes**:
- Middleware ordering issues
- Content-Type not matching expected patterns
- Parser configuration problems
- WebMock stubbing not setting correct headers

**Investigation Steps**:
1. Check if Content-Type headers in WebMock stubs are correct
2. Verify Faraday JSON middleware is properly configured
3. Test with real HTTP responses vs WebMock stubs

## Implementation Plan

### Phase 1: Diagnose JSON Parsing Issues

1. **Test Faraday JSON middleware directly**:
```ruby
# Test script
conn = Faraday.new do |f|
  f.response :json, parser_options: {symbolize_names: true}
  f.adapter Faraday.default_adapter
end

# Should return parsed JSON
response = conn.get('https://httpbin.org/json')
puts response.body.class  # Should be Hash, not String
```

2. **Check WebMock stub configuration**:
```ruby
stub_request(:get, "#{test_url}/users")
  .with(headers: {"Accept" => "application/json"})
  .to_return(
    status: 200,
    body: '{"users": [{"id": 1, "name": "John"}]}',
    headers: {"Content-Type" => "application/json"}  # Ensure this is set
  )
```

### Phase 2: Fix Response Structure

**Option A: Restore `:raw_body` (Recommended)**
```ruby
def parse_response(response, json: true)
  # Capture raw body before any processing
  raw_body = response.body.is_a?(String) ? response.body : response.body.to_json
  
  {
    status: response.status,
    headers: response.headers.to_h,
    success: response.success?,
    body: response.body,      # Parsed by Faraday middleware
    raw_body: raw_body        # Original string representation
  }
end
```

**Option B: Fix Faraday Setup for Proper Parsing**
```ruby
# In HTTPClient connection setup
faraday.response :json, 
  content_type: /\bjson$/,
  parser_options: {symbolize_names: true}
```

### Phase 3: Handle Edge Cases

1. **Non-JSON responses**:
   - Ensure `:raw_body` is populated for all response types
   - Handle cases where body is already parsed

2. **Error responses**:
   - Ensure structure is consistent for error cases
   - Test with various HTTP status codes

### Phase 4: Test and Verify

1. **Unit tests for response structure**:
```bash
bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb -e "parse_response"
```

2. **Integration tests**:
```bash
bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb -e "json_request"
```

## Testing Strategy

### Mock Response Testing
Create test helper to verify response structure:
```ruby
def expect_valid_response_structure(response)
  expect(response).to include(:status, :headers, :success, :body)
  expect(response).to include(:raw_body) if json_response
  expect(response[:status]).to be_a(Integer)
  expect(response[:success]).to be_in([true, false])
end
```

### WebMock Configuration
Ensure all WebMock stubs include proper Content-Type headers:
```ruby
RSpec.shared_examples "proper JSON response stub" do |url, response_body|
  before do
    stub_request(:get, url)
      .to_return(
        status: 200,
        body: response_body.to_json,
        headers: {
          "Content-Type" => "application/json; charset=utf-8"
        }
      )
  end
end
```

## Deliverables

### Modified Files

- `lib/coding_agent_tools/molecules/http_request_builder.rb` - Updated `parse_response` method
- `lib/coding_agent_tools/atoms/http_client.rb` - Fixed Faraday middleware configuration
- `spec/coding_agent_tools/molecules/http_request_builder_spec.rb` - Updated WebMock stubs if needed

### Tests

- All response structure tests pass
- JSON parsing works correctly
- `:raw_body` is available when expected

## Acceptance Criteria

- [ ] AC1: Response hash includes `:raw_body` field for JSON responses
- [ ] AC2: JSON responses are properly parsed into Ruby objects in `:body` field
- [ ] AC3: Non-JSON responses return string body with `:raw_body` copy
- [ ] AC4: All HTTPRequestBuilder tests pass
- [ ] AC5: Response structure is consistent across all HTTP methods
- [ ] AC6: WebMock stubs properly simulate JSON content-type headers
- [ ] AC7: No regression in response parsing functionality
- [ ] AC8: Error responses maintain consistent structure

## Risk Assessment

**Medium Risk**: Response structure changes could affect external consumers.

**Mitigation**: 
- Maintain backward compatibility by restoring expected fields
- Add comprehensive tests for response structure
- Document any intentional changes in structure

## Debugging Commands

```bash
# Test specific failing examples
bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb:48
bundle exec rspec spec/coding_agent_tools/molecules/http_request_builder_spec.rb:346

# Debug response structure
ruby -e "
require './lib/coding_agent_tools'
require 'webmock/rspec'
WebMock.enable!
stub_request(:get, 'http://example.com/test')
  .to_return(body: '{\"test\": true}', headers: {'Content-Type' => 'application/json'})
builder = CodingAgentTools::Molecules::HTTPRequestBuilder.new
result = builder.json_request(:get, 'http://example.com/test')
pp result
"
```

## References

- [Faraday JSON Middleware Documentation](https://lostisland.github.io/faraday/middleware/json)
- [WebMock Usage](https://github.com/bblimke/webmock)
- [Original Task v.0.2.0+task.7](v.0.2.0+task.7-Implement-Code-Quality-Improvements.md)