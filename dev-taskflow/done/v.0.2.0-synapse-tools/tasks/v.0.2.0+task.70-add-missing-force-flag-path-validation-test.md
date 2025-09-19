---
id: v.0.2.0+task.70
status: done
priority: medium
estimate: 1-2 hours
dependencies: []
created: 2025-06-26
reviewed: false
test_mode: false
---

# Add Missing Test Scenario: Force Flag with Path Validation

## Objective

Add an integration test to verify that the `--force` flag does not bypass path validation for denied paths in the LLM query integration, addressing a gap identified in the test review report.

## Directory Audit

Current integration test structure:
```
spec/
├── integration/
│   └── llm_query_integration_spec.rb  # Contains security validation tests
└── support/
    └── shared_examples/
        └── path_traversal_attacks.rb  # Shared security test patterns
```

## Scope of Work

Add a specific integration test to `spec/integration/llm_query_integration_spec.rb` within the existing "security validation" context to ensure proper interaction between `--force` flag and path validation security layers.

## Deliverables

### Files to Modify
- `spec/integration/llm_query_integration_spec.rb`
  - Add test case for `--force` flag with denied paths in the existing security validation context (around line 606-701)

### Expected Test Case
```ruby
it "blocks writing to a denied path even when --force is used" do
  denied_path = "/etc/test_denied.txt"
  
  _, stderr, status = execute_gem_executable(exe_name,
    ["google", "test prompt", "--output", denied_path, "--force"],
    env: {"GOOGLE_API_KEY" => google_api_key})
  
  expect(status.exitstatus).to eq(1)
  expect(stderr).to match(/Path validation failed|denied pattern/i)
end
```

## Implementation Plan

### Execution Steps
- [x] Locate the existing "security validation" context in `spec/integration/llm_query_integration_spec.rb`
- [x] Add the new test case within that context
- [x] Ensure the test uses a denied path pattern that will trigger path validation failure
- [x] Verify the test expects proper error exit code (1) and error message format
- [x] Run the specific test to confirm it passes: `bundle exec rspec spec/integration/llm_query_integration_spec.rb -e "blocks writing to a denied path even when --force is used"`
- [x] Run the full integration test suite to ensure no regressions

## Acceptance Criteria

- [x] New test case added to existing security validation context
- [x] Test verifies that `--force` flag does not bypass path validation for denied paths
- [x] Test expects appropriate exit code (1) and error message pattern
- [x] Test passes when run individually and as part of the full suite
- [x] No existing tests are broken by the addition
- [x] Test follows the same pattern as other security validation tests in the same context

## Out of Scope

- Modifying the actual security validation logic (this is testing existing behavior)
- Adding tests for other combinations of flags
- Changing the error message format or exit codes
- Adding new shared examples or test helpers

## References

- Test Review Report: `docs-project/current/v.0.2.1-synapse/test_review/changes-20250626-110300/tr-report-gpro.md` (Section 6: Missing Test Scenarios)
- Existing security tests: `spec/integration/llm_query_integration_spec.rb` lines 606-701
- Path traversal shared examples: `spec/support/shared_examples/path_traversal_attacks.rb`

## Risk Assessment

**Low Risk**: This is a straightforward addition of a test case to verify existing security behavior. The test follows established patterns and should not affect application functionality.