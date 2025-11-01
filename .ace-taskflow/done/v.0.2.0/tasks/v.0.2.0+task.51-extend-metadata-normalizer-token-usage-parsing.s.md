---
id: v.0.2.0+task.51
status: done
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

Extend the `MetadataNormalizer` to parse token usage information from all 6 LLM provider responses, providing consistent metadata extraction across different API formats. This addresses Subsequent Enhancement #9 from the code review findings and enables usage tracking capabilities across all supported providers (Google, LMStudio, Anthropic, OpenAI, Mistral, TogetherAI). Cost calculation will be handled separately in task 40.

## Scope of Work

- Analyze token/usage response formats from all 6 supported providers
- Extend MetadataNormalizer with provider-specific parsing logic
- Add support for input tokens, output tokens, and total token counts
- Add request timing and performance metadata extraction
- Ensure consistent metadata format across all 6 providers
- Focus on token/usage parsing (cost calculation deferred to task 40)

### Deliverables

#### Create

- `lib/coding_agent_tools/models/usage_metadata.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/lmstudio_usage_parser.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/anthropic_usage_parser.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/openai_usage_parser.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/mistral_usage_parser.rb`
- `lib/coding_agent_tools/molecules/provider_usage_parsers/togetherai_usage_parser.rb`
- `spec/coding_agent_tools/models/usage_metadata_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/lmstudio_usage_parser_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/anthropic_usage_parser_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/openai_usage_parser_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/mistral_usage_parser_spec.rb`
- `spec/coding_agent_tools/molecules/provider_usage_parsers/togetherai_usage_parser_spec.rb`

#### Modify

- `lib/coding_agent_tools/molecules/metadata_normalizer.rb` (add usage parsing)
- `spec/coding_agent_tools/molecules/metadata_normalizer_spec.rb` (enhance tests)
- `lib/coding_agent_tools/organisms/google_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools/organisms/lmstudio_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools/organisms/anthropic_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools/organisms/openai_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools/organisms/mistral_client.rb` (use enhanced metadata)
- `lib/coding_agent_tools/organisms/togetherai_client.rb` (use enhanced metadata)
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

* [ ] Analyze API response formats from all 6 providers to identify usage patterns
  > TEST: Usage Analysis Complete
  > Type: Pre-condition Check
  > Assert: Provider usage formats documented and parsing strategy defined
  > Command: test -f docs/provider-usage-analysis.md
* [ ] Design consistent usage metadata structure across all 6 providers
* [ ] Plan extensible architecture for future provider additions
* [ ] Verify existing Google/LMStudio parsers as reference implementation

### Execution Steps

- [ ] Create `UsageMetadata` model with consistent fields for all providers
  > TEST: Usage Metadata Model
  > Type: Action Validation
  > Assert: UsageMetadata model compiles and provides expected interface
  > Command: ruby -c lib/coding_agent_tools/models/usage_metadata.rb
- [ ] Implement `GoogleUsageParser` for Google API response format
  > TEST: Google Usage Parser
  > Type: Action Validation
  > Assert: GoogleUsageParser correctly extracts token counts from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/google_usage_parser_spec.rb
- [ ] Implement `LMStudioUsageParser` for LM Studio response format
  > TEST: LM Studio Usage Parser
  > Type: Action Validation
  > Assert: LMStudioUsageParser correctly extracts usage from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/lmstudio_usage_parser_spec.rb
- [ ] Implement `AnthropicUsageParser` for Anthropic API response format
  > TEST: Anthropic Usage Parser
  > Type: Action Validation
  > Assert: AnthropicUsageParser correctly extracts token counts from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/anthropic_usage_parser_spec.rb
- [ ] Implement `OpenaiUsageParser` for OpenAI API response format
  > TEST: OpenAI Usage Parser
  > Type: Action Validation
  > Assert: OpenaiUsageParser correctly extracts token counts from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/openai_usage_parser_spec.rb
- [ ] Implement `MistralUsageParser` for Mistral API response format
  > TEST: Mistral Usage Parser
  > Type: Action Validation
  > Assert: MistralUsageParser correctly extracts token counts from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/mistral_usage_parser_spec.rb
- [ ] Implement `TogetheraiUsageParser` for TogetherAI API response format
  > TEST: TogetherAI Usage Parser
  > Type: Action Validation
  > Assert: TogetheraiUsageParser correctly extracts token counts from responses
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/togetherai_usage_parser_spec.rb
- [ ] Extend `MetadataNormalizer` with usage parsing capabilities
- [ ] Add provider detection logic to route to appropriate usage parser
- [ ] Add request timing and performance metadata extraction
  > TEST: Enhanced Metadata Normalizer
  > Type: Action Validation
  > Assert: MetadataNormalizer provides consistent usage data across providers
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/metadata_normalizer_spec.rb
- [ ] Update `GoogleClient` to utilize enhanced metadata extraction
- [ ] Update `LMStudioClient` to utilize enhanced metadata extraction
- [ ] Update `AnthropicClient` to utilize enhanced metadata extraction
- [ ] Update `OpenaiClient` to utilize enhanced metadata extraction
- [ ] Update `MistralClient` to utilize enhanced metadata extraction
- [ ] Update `TogetheraiClient` to utilize enhanced metadata extraction
- [ ] Add comprehensive test coverage for all usage parsing scenarios
  > TEST: Usage Parsing Coverage
  > Type: Action Validation
  > Assert: All usage parsing scenarios have >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_usage_parsers/ --format json | jq '.summary.coverage_percent'
- [ ] Create integration tests with real API response fixtures
- [ ] Validate metadata consistency across different providers

## Acceptance Criteria

- [x] AC 1: `MetadataNormalizer` extracts token usage from all provider responses
- [x] AC 2: Usage metadata includes input tokens, output tokens, and total counts
- [x] AC 4: Consistent `UsageMetadata` format across all providers
- [x] AC 5: Request timing and performance data included in metadata
- [x] AC 6: Provider-specific parsers handle edge cases and malformed responses
- [x] AC 7: All existing functionality maintained with enhanced metadata
- [x] AC 8: Extensible architecture allows easy addition of new providers

## Out of Scope

- ❌ Cost calculation and pricing models (handled in task 40)
- ❌ Real-time cost tracking or billing integration
- ❌ Usage analytics or reporting dashboard
- ❌ Complex cost optimization recommendations
- ❌ Historical usage data storage or persistence

## References

- [Code Review Task 39 - Subsequent Enhancement #9](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Molecules Layer](../../../../docs/architecture.md#molecules-composition-layer)
- [Google Gemini API Usage Documentation](https://ai.google.dev/pricing)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)