---
id: v.0.2.0+task.51
status: pending
priority: medium
estimate: 5h
dependencies: [v.0.2.0+task.45]
---

# Extend MetadataNormalizer with Token/Usage Parsing for All Providers

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*metadata*" -o -name "*normalizer*" -type f | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/molecules/metadata_normalizer.rb
./spec/coding_agent_tools/molecules/metadata_normalizer_spec.rb
```

## Objective

Extend the `MetadataNormalizer` to parse token usage and cost information from all LLM provider responses, providing consistent metadata extraction across different API formats. This addresses Subsequent Enhancement #9 from the code review findings and enables usage tracking and cost monitoring capabilities across all supported providers.

## Scope of Work

- Analyze token/usage response formats from all supported providers
- Extend MetadataNormalizer with provider-specific parsing logic
- Add support for input tokens, output tokens, and total token counts
- Implement cost calculation based on provider pricing models
- Add request timing and performance metadata extraction
- Ensure consistent metadata format across all providers

### Deliverables

#### Create

- `lib/coding_agent_tools/models/usage_metadata.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/lm_studio_usage_parser.rb`
- `spec/coding_agent_tools/models/usage_metadata_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/lm_studio_usage_parser_spec.rb`

#### Modify

- `lib/coding_agent_tools/molecules/metadata_normalizer.rb` (add usage parsing)
- `spec/coding_agent_tools/molecules/metadata_normalizer_spec.rb` (enhance tests)
- `lib/coding_agent_tools/organisms/gemini_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- None

## Phases

1. Analyze provider response formats for usage information
2. Design consistent usage metadata structure
3. Implement provider-specific usage parsers
4. Extend MetadataNormalizer with usage parsing capabilities
5. Update clients to utilize enhanced metadata
6. Add comprehensive testing and validation

## Implementation Plan

### Planning Steps

* [ ] Analyze API response formats from all providers to identify usage patterns
  > TEST: Usage Analysis Complete
  > Type: Pre-condition Check
  > Assert: Provider usage formats documented and parsing strategy defined
  > Command: test -f docs/provider-usage-analysis.md
* [ ] Design consistent usage metadata structure across providers
* [ ] Research provider pricing models for cost calculation
* [ ] Plan extensible architecture for future provider additions

### Execution Steps

- [ ] Create `UsageMetadata` model with consistent fields for all providers
  > TEST: Usage Metadata Model
  > Type: Action Validation
  > Assert: UsageMetadata model compiles and provides expected interface
  > Command: ruby -c lib/coding_agent_tools/models/usage_metadata.rb
- [ ] Implement `GoogleUsageParser` for Gemini API response format
  > TEST: Google Usage Parser
  > Type: Action Validation
  > Assert: GoogleUsageParser correctly extracts token counts from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser_spec.rb
- [ ] Implement `LMStudioUsageParser` for LM Studio response format
  > TEST: LM Studio Usage Parser
  > Type: Action Validation
  > Assert: LMStudioUsageParser correctly extracts usage from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/lm_studio_usage_parser_spec.rb
- [ ] Extend `MetadataNormalizer` with usage parsing capabilities
- [ ] Add provider detection logic to route to appropriate usage parser
- [ ] Implement cost calculation based on provider pricing models
- [ ] Add request timing and performance metadata extraction
  > TEST: Enhanced Metadata Normalizer
  > Type: Action Validation
  > Assert: MetadataNormalizer provides consistent usage data across providers
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/metadata_normalizer_spec.rb
- [ ] Update `GeminiClient` to utilize enhanced metadata extraction
- [ ] Update `LMStudioClient` to utilize enhanced metadata extraction
- [ ] Add comprehensive test coverage for all usage parsing scenarios
  > TEST: Usage Parsing Coverage
  > Type: Action Validation
  > Assert: All usage parsing scenarios have >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/ --format json | jq '.summary.coverage_percent'
- [ ] Create integration tests with real API response fixtures
- [ ] Validate metadata consistency across different providers

## Acceptance Criteria

- [ ] AC 1: `MetadataNormalizer` extracts token usage from all provider responses
- [ ] AC 2: Usage metadata includes input tokens, output tokens, and total counts
- [ ] AC 3: Cost calculation works for providers with available pricing models
- [ ] AC 4: Consistent `UsageMetadata` format across all providers
- [ ] AC 5: Request timing and performance data included in metadata
- [ ] AC 6: Provider-specific parsers handle edge cases and malformed responses
- [ ] AC 7: All existing functionality maintained with enhanced metadata
- [ ] AC 8: Extensible architecture allows easy addition of new providers

## Out of Scope

- ❌ Real-time cost tracking or billing integration
- ❌ Usage analytics or reporting dashboard
- ❌ Complex cost optimization recommendations
- ❌ Historical usage data storage or persistence

## References

- [Code Review Task 39 - Subsequent Enhancement #9](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Molecules Layer](../../../../docs/architecture.md#molecules-composition-layer)
- [Google Gemini API Usage Documentation](https://ai.google.dev/pricing)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)