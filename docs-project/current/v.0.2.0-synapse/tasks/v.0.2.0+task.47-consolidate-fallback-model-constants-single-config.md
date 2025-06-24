---
id: v.0.2.0+task.47
status: pending
priority: high
estimate: 4h
dependencies: [v.0.2.0+task.45]
---

# Consolidate Fallback Model Constants into Single Configuration Source

## 0. Directory Audit ✅

_Command run:_

```bash
grep -r "DEFAULT_MODEL\|default.*model" . --include="*.rb" | grep -v spec | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/organisms/google_client.rb:    DEFAULT_MODEL = "gemini-2.0-flash-lite"
./lib/coding_agent_tools/cli/commands/google/query.rb:          option :model, type: :string, default: "gemini-2.0-flash-lite",
./lib/coding_agent_tools/cli/commands/anthropic/query.rb:          option :model, type: :string, default: "claude-3-5-sonnet-20241022",
./lib/coding_agent_tools/cli/commands/openai/query.rb:          option :model, type: :string, default: "gpt-4o-mini",
./lib/coding_agent_tools/cli/commands/mistral/query.rb:          option :model, type: :string, default: "mistral-large-latest",
./lib/coding_agent_tools/cli/commands/together_ai/query.rb:          option :model, type: :string, default: "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
./lib/coding_agent_tools/cli/commands/lms/query.rb:          option :model, type: :string, default: "llama-3.2-3b-instruct",
```

## Objective

Consolidate scattered fallback model constants into a single, centralized configuration source to eliminate duplication and provide a single source of truth for default model selections. This addresses Priority 2 requirement #5 from the code review findings and ensures consistent fallback behavior across all 6 providers (google, anthropic, openai, mistral, together_ai, lmstudio). All providers must have default models configured.

## Scope of Work

- Create centralized configuration class for default models across all 6 providers
- Extract hardcoded fallback constants from multiple locations (clients and CLI commands)
- Implement provider-specific default model mapping for all providers
- Ensure every provider has a default model configured
- Update all clients and commands to use centralized configuration
- Add configuration validation and error handling for all providers
- Ensure backward compatibility with existing behavior across all providers

### Deliverables

#### Create

- `lib/coding_agent_tools/models/default_model_config.rb`
- `spec/coding_agent_tools/models/default_model_config_spec.rb`
- `config/default_models.yml` (optional configuration file)

#### Modify

- `lib/coding_agent_tools/organisms/google_client.rb` (remove hardcoded constant)
- `lib/coding_agent_tools/organisms/anthropic_client.rb` (use centralized config)
- `lib/coding_agent_tools/organisms/openai_client.rb` (use centralized config)
- `lib/coding_agent_tools/organisms/mistral_client.rb` (use centralized config)
- `lib/coding_agent_tools/organisms/together_ai_client.rb` (use centralized config)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/google/query.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/anthropic/query.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/openai/query.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/mistral/query.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/together_ai/query.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/lms/query.rb` (use centralized config)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- Hardcoded DEFAULT_MODEL constants and default model options from individual classes

## Phases

1. Audit all locations with fallback/default model constants across all 6 providers
2. Design centralized configuration structure with all provider mappings
3. Implement configuration class with all provider mappings and validation
4. Refactor existing clients and commands to use centralized config
5. Add validation and comprehensive testing for all providers
6. Verify no behavioral changes across all providers

## Implementation Plan

### Planning Steps

* [ ] Audit all locations where default/fallback models are defined across all 6 providers
  > TEST: Audit Complete
  > Type: Pre-condition Check
  > Assert: All hardcoded model constants are catalogued for all providers
  > Command: grep -r "DEFAULT_MODEL\|default.*model" . --include="*.rb" | wc -l
* [ ] Design configuration structure with all 6 provider-specific mappings
* [ ] Plan migration strategy to avoid breaking existing functionality across all providers
* [ ] Design validation rules to ensure all providers have default models configured

### Execution Steps

- [ ] Create `DefaultModelConfig` class with all 6 provider-to-model mappings
  > TEST: Config Class Creation
  > Type: Action Validation
  > Assert: DefaultModelConfig compiles and provides expected interface for all providers
  > Command: ruby -c lib/coding_agent_tools/models/default_model_config.rb
- [ ] Implement methods to retrieve default models by provider for all 6 providers
- [ ] Add configuration validation to ensure all 6 providers have defaults
- [ ] Create optional YAML configuration file for easy customization of all provider defaults
- [ ] Update `GoogleClient` to use centralized configuration
  > TEST: Google Client Update
  > Type: Action Validation
  > Assert: GoogleClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/google_client_spec.rb
- [ ] Update `AnthropicClient` to use centralized configuration
  > TEST: Anthropic Client Update
  > Type: Action Validation
  > Assert: AnthropicClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/anthropic_client_spec.rb
- [ ] Update `OpenaiClient` to use centralized configuration
  > TEST: OpenAI Client Update
  > Type: Action Validation
  > Assert: OpenaiClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/openai_client_spec.rb
- [ ] Update `MistralClient` to use centralized configuration
  > TEST: Mistral Client Update
  > Type: Action Validation
  > Assert: MistralClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/mistral_client_spec.rb
- [ ] Update `TogetherAiClient` to use centralized configuration
  > TEST: Together AI Client Update
  > Type: Action Validation
  > Assert: TogetherAiClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/together_ai_client_spec.rb
- [ ] Update `LMStudioClient` to use centralized configuration
  > TEST: LM Studio Client Update
  > Type: Action Validation
  > Assert: LMStudioClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
- [ ] Update all 6 provider CLI commands to use centralized configuration
- [ ] Remove hardcoded DEFAULT_MODEL constants and default options from all classes
- [ ] Add comprehensive tests for configuration class
  > TEST: Configuration Test Coverage
  > Type: Action Validation
  > Assert: DefaultModelConfig has >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/models/default_model_config_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Update library requires and ensure proper loading order
- [ ] Validate all existing functionality works with centralized config across all 6 providers

## Acceptance Criteria

- [ ] AC 1: Single `DefaultModelConfig` class provides all fallback models for all 6 providers
- [ ] AC 2: All hardcoded DEFAULT_MODEL constants and default options removed from individual classes
- [ ] AC 3: Google client uses same default model as before ('gemini-2.0-flash-lite')
- [ ] AC 4: Anthropic client uses appropriate default model
- [ ] AC 5: OpenAI client uses appropriate default model
- [ ] AC 6: Mistral client uses appropriate default model
- [ ] AC 7: Together AI client uses appropriate default model
- [ ] AC 8: LM Studio client uses same default model as before ('llama-3.2-3b-instruct')
- [ ] AC 9: All CLI commands maintain identical fallback behavior
- [ ] AC 10: Configuration validates that all 6 providers have default models
- [ ] AC 11: All existing tests pass without modification
- [ ] AC 12: New configuration is easily extensible for additional providers

## Out of Scope

- ❌ Implementing user-customizable configuration (beyond optional YAML)
- ❌ Adding new providers beyond the existing 6 or changing existing default model selections
- ❌ Runtime model discovery or dynamic defaults
- ❌ Complex configuration management features
- ❌ Model availability validation or API health checks

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Models Layer](../../../../docs/architecture.md#models-data-layer)
- [Configuration Management Patterns](../../../../docs-dev/guides/coding-standards.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)