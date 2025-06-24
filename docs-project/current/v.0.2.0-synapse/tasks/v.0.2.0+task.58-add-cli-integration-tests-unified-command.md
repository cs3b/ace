---
id: v.0.2.0+task.58
status: done
priority: medium
estimate: 4h
dependencies: ["v.0.2.0+task.44", "v.0.2.0+task.53"]
---

# Add CLI Integration Tests for Unified LLM Query Command

## Objective / Problem

The consolidation of multiple `llm-*-query` executables into a single `llm-query` command with `provider:model` syntax is a significant change that lacks comprehensive CLI-level integration tests. While unit tests exist for the underlying components, we need integration tests that verify the new command syntax, option parsing, and end-to-end functionality across different providers.

## Directory Audit

```bash
tree -L 3 spec/integration | sed 's/^/    /'

    spec/integration
    ├── anthropic_query_integration_spec.rb
    ├── google_query_integration_spec.rb
    ├── lms_query_integration_spec.rb
    ├── mistral_query_integration_spec.rb
    ├── openai_query_integration_spec.rb
    └── together_query_integration_spec.rb
```

## Scope of Work

- Create comprehensive integration tests for the unified `llm-query` command
- Test provider:model syntax parsing across all providers
- Verify option handling and parameter passing
- Test error scenarios and edge cases
- Ensure backward compatibility with aliases

## Deliverables / Manifest

| File | Action | Purpose |
|------|--------|---------|
| `spec/integration/llm_query_integration_spec.rb` | Create | Main integration test file for unified command |
| `spec/cassettes/llm_query_integration/` | Create | VCR cassettes directory for test recordings |

## Phases

1. **Design** - Plan test scenarios and coverage
2. **Implementation** - Write comprehensive integration tests
3. **Recording** - Create VCR cassettes for API interactions
4. **Validation** - Ensure all providers and scenarios are covered

## Implementation Plan

### Planning Steps
* [x] Review existing provider-specific integration tests for patterns
* [x] Identify all command-line options and their combinations
* [x] Design test matrix covering providers × options × scenarios
* [x] Plan VCR cassette organization strategy

### Execution Steps
- [x] Create `spec/integration/llm_query_integration_spec.rb` with basic structure
- [x] Implement tests for basic provider:model syntax:
  - Tests exist for all 6 providers (google, anthropic, openai, mistral, together_ai, lmstudio)
  - Each provider has comprehensive test coverage including basic queries, JSON output, model selection
- [x] Add tests for default model selection (provider without :model)
- [x] Test all command-line options:
  - `--format json/text` ✓
  - `--temperature` ✓
  - `--max-tokens` ✓
  - `--system` ✓
  - `--output` ✓
  - `--debug` (tested via error scenarios)
- [x] Test file input handling:
  > TEST: File Input
  >   Type: Action Validation
  >   Assert: Command correctly reads prompts from files
  >   Command: bundle exec rspec spec/integration/llm_query_integration_spec.rb -e "file input"
- [x] Test alias support (gflash, csonet, gpro, o4mini)
- [x] Add error scenario tests:
  - Invalid provider names ✓
  - Malformed provider:model syntax ✓
  - Missing API keys ✓
  - Network failures (via VCR mocking) ✓
- [x] Test option combination scenarios
- [x] Add tests for output format consistency across providers
- [x] Verify metadata normalization works correctly
- [x] Test streaming vs non-streaming behavior (implicit in current tests)
- [x] Add performance benchmarks for command startup time
- [x] Create comprehensive VCR cassettes for all test scenarios

## Acceptance Criteria

- [x] All six providers have integration tests for the new syntax
- [x] Command-line option parsing is thoroughly tested
- [x] Error scenarios produce helpful error messages
- [x] Tests verify both success and failure paths
- [x] VCR cassettes exist for all API interactions
- [x] Tests pass in CI environment
- [x] Test coverage includes edge cases and option combinations

## Out of Scope

- Modifying existing provider-specific integration tests
- Testing provider-specific features beyond unified interface
- Performance optimization of the CLI itself
- Testing internal implementation details

## References & Risks

- Task 44: [Implement Unified LLM Query Entry Point](v.0.2.0+task.44-implement-unified-llm-query-entry-point.md)
- Task 53: [Verify Documentation Reflects Unified Command](v.0.2.0+task.53-verify-documentation-unified-llm-query-command.md)
- [Aruba Testing Framework](https://github.com/cucumber/aruba) - Consider for CLI testing
- Risk: VCR cassettes might become outdated - implement cassette refresh strategy
- Risk: Integration tests might be slow - use focused test runs in development