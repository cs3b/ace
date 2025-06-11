---
id: v.0.2.0+task.9
status: pending
priority: high
estimate: 2h
dependencies: [v.0.2.0+task.8]
---

# Fix HTTP Client Method Signature Issues

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 lib/coding_agent_tools/atoms | sed 's/^/    /'
```

_Result excerpt:_

```
lib/coding_agent_tools/atoms
├── env_reader.rb
├── http_client.rb
└── json_formatter.rb
```

## Objective

Fix the method signature mismatches in `CodingAgentTools::Atoms::HTTPClient` that are causing ArgumentError exceptions. The `get` and `post` methods are receiving the wrong number of arguments compared to what the tests expect, indicating a mismatch between method definitions and test calls.

## Scope of Work

- Fix HTTPClient#get method signature to properly handle headers parameter
- Fix HTTPClient#post method signature to properly handle headers parameter
- Ensure backward compatibility with existing method calls
- Update method documentation to reflect correct usage

### Deliverables

#### Modify

- lib/coding_agent_tools/atoms/http_client.rb
- spec/coding_agent_tools/atoms/http_client_spec.rb (if test calls need adjustment)

## Phases

1. Audit current method signatures and test expectations
2. Analyze the specific argument errors
3. Fix method signatures to match expected usage
4. Verify all HTTP client tests pass

## Implementation Plan

### Planning Steps

* [ ] Analyze the current HTTPClient method signatures in detail
  > TEST: Current Signatures Documented
  > Type: Pre-condition Check
  > Assert: Current get/post method signatures are clearly understood
  > Command: grep -A 10 "def get\|def post" lib/coding_agent_tools/atoms/http_client.rb
* [ ] Examine failing test calls to understand expected method signatures
  > TEST: Test Expectations Documented
  > Type: Pre-condition Check
  > Assert: Expected method call patterns are identified from test failures
  > Command: grep -A 5 -B 5 "client\.get\|client\.post" spec/coding_agent_tools/atoms/http_client_spec.rb
* [ ] Determine if the issue is in method definition or test calls
* [ ] Plan approach to fix signatures while maintaining backward compatibility

### Execution Steps

- [ ] Fix HTTPClient#get method to properly handle the headers parameter
  > TEST: Get Method Signature Fixed
  > Type: Action Validation
  > Assert: The get method can be called with URL and headers hash
  > Command: ruby -e "require_relative 'lib/coding_agent_tools/atoms/http_client'; puts 'Signature OK'"
- [ ] Fix HTTPClient#post method to properly handle body and headers parameters
  > TEST: Post Method Signature Fixed
  > Type: Action Validation
  > Assert: The post method can be called with URL, body, and headers hash
  > Command: ruby -e "require_relative 'lib/coding_agent_tools/atoms/http_client'; puts 'Signature OK'"
- [ ] Update method documentation to reflect correct parameter usage
- [ ] Run HTTPClient-specific tests to verify fixes
  > TEST: HTTP Client Tests Pass
  > Type: Action Validation
  > Assert: All HTTPClient unit tests pass without ArgumentError
  > Command: bin/test spec/coding_agent_tools/atoms/http_client_spec.rb
- [ ] Run full test suite to ensure no regressions
  > TEST: No Regressions Introduced
  > Type: Action Validation
  > Assert: Other tests are not broken by signature changes
  > Command: bin/test --exclude integration

## Acceptance Criteria

- [ ] AC 1: HTTPClient#get method accepts URL and headers parameters without ArgumentError
- [ ] AC 2: HTTPClient#post method accepts URL, body, and headers parameters without ArgumentError
- [ ] AC 3: All HTTPClient unit tests pass successfully
- [ ] AC 4: Method documentation accurately reflects parameter usage
- [ ] AC 5: No regression in other parts of the codebase

## Out of Scope

- ❌ Adding new HTTP methods (PUT, DELETE, etc.)
- ❌ Changing the underlying Faraday configuration
- ❌ Modifying the middleware stack
- ❌ Refactoring the connection method

## References

- Error: "ArgumentError: wrong number of arguments (given 2, expected 1)" for get method
- Error: "ArgumentError: wrong number of arguments (given 3, expected 2)" for post method
- Files: `lib/coding_agent_tools/atoms/http_client.rb`, `spec/coding_agent_tools/atoms/http_client_spec.rb`
- [Faraday Documentation](https://lostisland.github.io/faraday/)