---
id: v.0.2.0+task.11
status: pending
priority: medium
estimate: 4h
dependencies: [v.0.2.0+task.8, v.0.2.0+task.9]
---

# Fix Gemini Client API Response Handling Issues

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 lib/coding_agent_tools/organisms | sed 's/^/    /'
```

_Result excerpt:_

```
lib/coding_agent_tools/organisms
├── gemini_client.rb
└── prompt_processor.rb
```

## Objective

Fix the multiple API response handling failures in `CodingAgentTools::Organisms::GeminiClient`. The failures indicate issues with parsing API responses, handling various error scenarios, and managing edge cases in the response structure. These issues affect the reliability of the Gemini API integration and error reporting.

## Scope of Work

- Fix API response parsing for various response structures
- Improve error handling for malformed responses
- Handle edge cases in candidate and content field parsing
- Fix safety filter and finish reason handling
- Ensure robust error reporting and messaging
- Fix token counting and model info response handling

### Deliverables

#### Modify

- lib/coding_agent_tools/organisms/gemini_client.rb
- spec/coding_agent_tools/organisms/gemini_client_spec.rb (if test expectations need adjustment)

## Phases

1. Audit current response handling implementation
2. Analyze specific failure scenarios and edge cases
3. Implement robust response parsing with error handling
4. Fix API error response handling
5. Verify all Gemini client tests pass

## Implementation Plan

### Planning Steps

* [ ] Analyze all failing Gemini client test scenarios to understand response handling issues
  > TEST: Response Handling Issues Documented
  > Type: Pre-condition Check
  > Assert: All response parsing failure scenarios are identified and categorized
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb --format documentation
* [ ] Review current response parsing implementation for structural issues
  > TEST: Current Implementation Analyzed
  > Type: Pre-condition Check
  > Assert: Current response parsing logic is understood and documented
  > Command: grep -A 20 "def.*response\|parse.*response" lib/coding_agent_tools/organisms/gemini_client.rb
* [ ] Examine API response structure requirements and edge cases
* [ ] Plan robust error handling strategy for malformed responses

### Execution Steps

- [ ] Fix response parsing when 'candidates' field is missing or not an array
  > TEST: Candidates Field Handling Fixed
  > Type: Action Validation
  > Assert: Client handles missing or malformed candidates field gracefully
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "candidates"
- [ ] Fix candidate content field parsing (missing, not Hash, empty)
  > TEST: Content Field Parsing Fixed
  > Type: Action Validation
  > Assert: Client handles various content field scenarios correctly
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "content"
- [ ] Fix content.parts array handling (missing, not Array, empty)
  > TEST: Parts Array Handling Fixed
  > Type: Action Validation
  > Assert: Client handles content.parts field variations correctly
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "parts"
- [ ] Fix text content extraction and validation (missing, nil, invalid)
  > TEST: Text Extraction Fixed
  > Type: Action Validation
  > Assert: Client handles text field variations and provides meaningful errors
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "text"
- [ ] Fix HTTP error response handling (400, 401, 429, non-JSON responses)
  > TEST: HTTP Error Handling Fixed
  > Type: Action Validation
  > Assert: Client handles various HTTP error scenarios with proper error messages
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "error"
- [ ] Fix safety filter and finish reason handling
  > TEST: Safety Filter Handling Fixed
  > Type: Action Validation
  > Assert: Client properly handles safety-filtered responses
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "safety"
- [ ] Fix token counting response parsing
  > TEST: Token Counting Fixed
  > Type: Action Validation
  > Assert: Token counting API responses are parsed correctly
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "token"
- [ ] Fix model info response handling
  > TEST: Model Info Fixed
  > Type: Action Validation
  > Assert: Model info API responses are handled correctly
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb -e "model_info"
- [ ] Implement comprehensive error messaging for debugging
- [ ] Run all Gemini client tests to verify all fixes
  > TEST: All Gemini Client Tests Pass
  > Type: Action Validation
  > Assert: All Gemini client tests pass successfully
  > Command: bin/test spec/coding_agent_tools/organisms/gemini_client_spec.rb

## Acceptance Criteria

- [ ] AC 1: Client handles missing or malformed 'candidates' field gracefully
- [ ] AC 2: Client properly parses candidate content and parts fields with error handling
- [ ] AC 3: Client extracts text content reliably with meaningful error messages
- [ ] AC 4: Client handles various HTTP error responses (400, 401, 429) correctly
- [ ] AC 5: Client processes safety-filtered responses appropriately
- [ ] AC 6: Token counting and model info APIs work correctly
- [ ] AC 7: All error scenarios provide clear, actionable error messages
- [ ] AC 8: All Gemini client unit tests pass without failures

## Out of Scope

- ❌ Adding new API endpoints or methods
- ❌ Changing the underlying HTTP client implementation
- ❌ Modifying API request structure or parameters
- ❌ Adding new response features beyond current test requirements
- ❌ Performance optimization of response parsing

## References

- Failed test scenarios: ~25 failures in gemini_client_spec.rb
- Key failure areas: response parsing, error handling, field validation
- API response structure: candidates, content, parts, text fields
- Error scenarios: HTTP errors, malformed JSON, missing fields
- [Gemini API Response Documentation](https://ai.google.dev/docs)
- [Ruby JSON Parsing Best Practices](https://ruby-doc.org/stdlib/libdoc/json/rdoc/JSON.html)