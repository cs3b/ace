---
id: v.0.3.0+task.148
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Improve test coverage for LLM Models CLI command - provider integration and model discovery

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Implement comprehensive test coverage for LLM::Models CLI command focusing on provider integration, model discovery, caching, and output formatting. Address uncovered line ranges from coverage analysis: lines 42-45, 47-54, 61, 63-69, 75-81, and extensive method implementations (8.78% coverage).

## Prerequisites

* Read the dev-tools technical architecture guide: `dev-tools/docs/architecture-tools.md`
* Understanding of ATOM architecture pattern (Atoms, Molecules, Organisms, Ecosystems)
* Familiarity with Ruby/RSpec testing patterns and VCR cassette management
* Understanding of LLM provider APIs and model discovery patterns

## Scope of Work

- Add missing test scenarios for uncovered methods in LLM::Models CLI command
- Implement edge case testing for provider validation and model fetching
- Add error condition testing for API failures and caching scenarios
- Follow Ruby/RSpec/VCR testing standards and ATOM architecture patterns
- Ensure meaningful test coverage beyond just exercising code

### Deliverables

#### Create

- spec/coding_agent_tools/cli/commands/llm/models_spec.rb

#### Modify

- None (new test file)

#### Delete

- None

## Implementation Plan

### Planning Steps
* [ ] Analyze source code for LLM::Models CLI command (lib/coding_agent_tools/cli/commands/llm/models.rb)
* [ ] Review existing CLI test patterns in the codebase
* [ ] Design test scenarios for uncovered methods: call, filter_models, output_models, handle_error, get_available_models, fetch_models_from_api, fetch_*_models methods, format_*_model_name methods, cache management methods
* [ ] Plan edge case scenarios and error conditions for provider integration

### Execution Steps
- [ ] Implement happy path tests for call method with different providers
- [ ] Add edge case tests for filter_models with various filter patterns
- [ ] Implement error condition tests for invalid provider validation
- [ ] Add integration tests for model fetching with VCR cassettes
- [ ] Test cache management scenarios (cache exists, cache miss, cache refresh)
- [ ] Add boundary condition tests for output formatting (text vs JSON)
- [ ] Test provider-specific model fetching methods with API errors
- [ ] Implement error handling tests for network failures and timeouts
- [ ] Test model name formatting across different providers
- [ ] Verify test isolation and cleanup procedures
- [ ] Run full test suite to ensure no regressions
  > TEST: Verify test suite passes
  > Type: Regression Check
  > Assert: All existing tests continue to pass after adding new tests
  > Command: cd dev-tools && bin/test

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] All uncovered methods have meaningful test scenarios
- [ ] Edge cases and error conditions are properly tested
- [ ] Tests follow RSpec best practices and VCR testing patterns
- [ ] VCR cassettes used for external LLM provider API interactions
- [ ] Test execution completes without errors
- [ ] Coverage analysis shows improved meaningful coverage for LLM::Models

## Out of Scope

- ❌ Testing with actual API keys (use VCR cassettes only)
- ❌ Performance benchmarking (focus on correctness)
- ❌ Integration with paid LLM services in tests

## Test Scenarios

### Uncovered Methods (Major Groups)
- call (lines 42-45, 47-54)
- filter_models (lines 61, 63-69)
- output_models (lines 75-81)
- handle_error (lines 87-95)
- get_available_models (lines 117-124)
- fetch_models_from_api (lines 128-142, 144-146)
- Provider-specific fetch methods:
  - fetch_google_models (lines 150-151, 154-156, 159-161, 164-165, 167-176)
  - fetch_lmstudio_models (lines 180-181, 183, 185-186, 189-190, 192-201)
  - fetch_openai_models (lines 205-206, 209-211, 213, 215-224)
  - fetch_anthropic_models (lines 228-229, 231, 233-242)
  - fetch_mistral_models (lines 246-247, 249, 251-260)
  - fetch_together_ai_models (lines 264-265, 268, 270, 272-281)
- Model name formatting methods (lines 285, 288-290, 292-293, 298, 301-303, 308-324, 329-343, 348-364, 369-385)
- Cache management (lines 485-486, 489-490, 493-494, 497-510, 512-513, 516-517, 519-529)
- Output formatting (lines 533-537, 539-540, 542-546, 548-551, 553-561, 563-566, 568-574, 576-579, 581-585, 587-590, 592-596, 598-601, 603-607, 609-612, 614-617, 621-623, 625-630, 632-647, 649-650)
- Context size extraction (lines 659-660, 663-680, 687-688, 691-704, 711-712, 715-728, 735-736, 740-742)

### Edge Cases to Test
- [ ] Provider validation (invalid providers, case sensitivity, typos)
- [ ] Model filtering (empty filters, regex patterns, no matches)
- [ ] API failures (network errors, authentication failures, rate limits)
- [ ] Cache scenarios (corrupted cache, permission errors, disk space)
- [ ] Output formatting (empty model lists, malformed model data, large datasets)
- [ ] Provider-specific edge cases (API response variations, model availability)

### Integration Scenarios
- [ ] CLI command execution with different option combinations
- [ ] VCR cassette integration for provider API calls
- [ ] Cache lifecycle management across test runs

## References
- Coverage analysis: coverage_analysis/coverage_analysis.json
- Testing standards: dev-tools/docs/development/guides/testing-with-vcr.md
- ATOM architecture: docs/architecture-tools.md
- Source file: lib/coding_agent_tools/cli/commands/llm/models.rb
- CLI testing patterns: existing spec/coding_agent_tools/cli/ files
- VCR testing patterns: existing spec/integration/ files
