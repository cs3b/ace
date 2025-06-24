---
id: v.0.2.0+task.47
status: pending
priority: medium
estimate: 2h
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

## Current State Analysis ✅

**Unified Architecture**: The project already has a unified LLM query system implemented in task 44:
- ✅ Single command: `lib/coding_agent_tools/cli/commands/llm/query.rb` handles all providers
- ✅ Provider-only syntax: Already supported via `ProviderModelParser` 
- ✅ Only 3 executables: `exe/llm-query`, `exe/llm-models`, `exe/coding_agent_tools`

**Partial Implementation Found**: `DefaultModelConfig` class has been created but:
- ❌ **Not integrated** - No existing code uses it yet
- ❌ **Wrong values** - Contains incorrect default models that don't match current system
- ❌ **Duplicates still exist** - Original constants haven't been removed

**Default Model Discrepancies**:
- `DefaultModelConfig` has: `anthropic => "claude-3-5-sonnet-20241022"` 
- `AnthropicClient` has: `"claude-3-5-haiku-20241022"` ← **CURRENT SYSTEM**
- `DefaultModelConfig` has: `mistral => "mistral-large-latest"`
- `MistralClient` has: `"open-mistral-nemo"` ← **CURRENT SYSTEM**  
- `DefaultModelConfig` has: `together_ai => "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo"`
- `TogetherAIClient` has: `"mistralai/Mistral-7B-Instruct-v0.3"` ← **CURRENT SYSTEM**

## Objective (Completion & Integration)

Complete the partially implemented `DefaultModelConfig` class and integrate it throughout the system to eliminate duplication and provide a single source of truth for default model selections. This addresses Priority 2 requirement #5 from the code review findings and ensures consistent fallback behavior across all 6 providers.

**Current Status**: The `DefaultModelConfig` class exists but has incorrect values and isn't integrated anywhere.

**Note**: Provider-only syntax and unified command architecture are already implemented and working correctly.

## Scope of Work (Completion & Integration)

- Fix incorrect default model values in existing `DefaultModelConfig` class
- Integrate `DefaultModelConfig` into organism client classes (replace `DEFAULT_MODEL` constants)
- Update `ProviderModelParser` to use centralized configuration instead of hardcoded hash
- Update `llm/models.rb` command to use centralized configuration
- Ensure all components use the same centralized source
- Maintain backward compatibility with existing behavior across all providers
- Preserve all current default model values (fix config to match current system)

### Deliverables

#### Create

- `spec/coding_agent_tools/models/default_model_config_spec.rb` (comprehensive tests)

#### Modify

- `lib/coding_agent_tools/models/default_model_config.rb` (fix incorrect default model values)
- `lib/coding_agent_tools/organisms/google_client.rb` (replace `DEFAULT_MODEL` with config call)
- `lib/coding_agent_tools/organisms/anthropic_client.rb` (replace `DEFAULT_MODEL` with config call)
- `lib/coding_agent_tools/organisms/openai_client.rb` (replace `DEFAULT_MODEL` with config call)
- `lib/coding_agent_tools/organisms/mistral_client.rb` (replace `DEFAULT_MODEL` with config call)
- `lib/coding_agent_tools/organisms/together_ai_client.rb` (replace `DEFAULT_MODEL` with config call)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (replace `DEFAULT_MODEL` with config call)
- `lib/coding_agent_tools/molecules/provider_model_parser.rb` (use centralized config instead of `DEFAULT_MODELS` hash)
- `lib/coding_agent_tools/cli/commands/llm/models.rb` (use centralized config)
- `lib/coding_agent_tools.rb` (ensure proper requires)

#### Delete

- Hardcoded `DEFAULT_MODEL` constants from organism client classes
- `DEFAULT_MODELS` hash from `ProviderModelParser`

## Phases

1. Audit all locations with default model constants across all 6 providers
2. Design centralized configuration structure with all provider mappings
3. Implement configuration class with all provider mappings and validation
4. Refactor existing clients and parser to use centralized config
5. Update models command to use centralized config
6. Add comprehensive testing and validation
7. Verify no behavioral changes across all providers

## Implementation Plan

### Planning Steps

* [x] Audit all locations where default models are defined across all 6 providers ✅
  > **COMPLETED**: Found constants in 6 organism clients + ProviderModelParser + models command
  > Current defaults: google(gemini-2.0-flash-lite), anthropic(claude-3-5-haiku-20241022), openai(gpt-4o-mini), mistral(open-mistral-nemo), together_ai(mistralai/Mistral-7B-Instruct-v0.3), lmstudio(mistralai/devstral-small-2505)
* [x] Design configuration structure with all 6 provider-specific mappings ✅
  > **COMPLETED**: `DefaultModelConfig` class exists with proper structure
* [x] Plan migration strategy to avoid breaking existing functionality across all providers ✅
  > **PLAN**: Replace constants with method calls, maintain same return values
* [x] Design validation rules to ensure all providers have default models configured ✅
  > **COMPLETED**: Validation exists in `DefaultModelConfig` class
* [ ] Fix incorrect default model values in existing `DefaultModelConfig` class
  > TEST: Model Values Fixed
  > Type: Pre-condition Check
  > Assert: DefaultModelConfig values match current system defaults
  > Command: ruby -e "require_relative 'lib/coding_agent_tools/models/default_model_config'; puts CodingAgentTools::Models::DefaultModelConfig.default.default_model_for('anthropic')" | grep -q "claude-3-5-haiku-20241022"

### Execution Steps

- [ ] Fix incorrect default model values in existing `DefaultModelConfig` class
  > TEST: Model Values Fixed
  > Type: Action Validation
  > Assert: DefaultModelConfig values match current system defaults exactly
  > Command: ruby -c lib/coding_agent_tools/models/default_model_config.rb && ruby -e "require_relative 'lib/coding_agent_tools/models/default_model_config'; config = CodingAgentTools::Models::DefaultModelConfig.default; puts config.default_model_for('anthropic'); puts config.default_model_for('mistral'); puts config.default_model_for('together_ai')"
- [ ] Update `ProviderModelParser` to use centralized config instead of `DEFAULT_MODELS` hash
  > TEST: Parser Config Integration
  > Type: Action Validation
  > Assert: Parser uses centralized config and maintains same behavior
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_model_parser_spec.rb
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
- [ ] Update `OpenAIClient` to use centralized configuration
  > TEST: OpenAI Client Update
  > Type: Action Validation
  > Assert: OpenAIClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/openai_client_spec.rb
- [ ] Update `MistralClient` to use centralized configuration
  > TEST: Mistral Client Update
  > Type: Action Validation
  > Assert: MistralClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/mistral_client_spec.rb
- [ ] Update `TogetherAIClient` to use centralized configuration
  > TEST: Together AI Client Update
  > Type: Action Validation
  > Assert: TogetherAIClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/together_ai_client_spec.rb
- [ ] Update `LMStudioClient` to use centralized configuration
  > TEST: LM Studio Client Update
  > Type: Action Validation
  > Assert: LMStudioClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
- [ ] Update `llm/models.rb` command to use centralized configuration
  > TEST: Models Command Update
  > Type: Action Validation
  > Assert: Models command uses centralized config and maintains same output
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/models_spec.rb
- [ ] Remove hardcoded `DEFAULT_MODEL` constants from organism client classes
- [ ] Remove `DEFAULT_MODELS` hash from `ProviderModelParser`
- [ ] Add comprehensive tests for configuration class
  > TEST: Configuration Test Coverage
  > Type: Action Validation
  > Assert: DefaultModelConfig has >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/models/default_model_config_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Update library requires and ensure proper loading order
- [ ] Validate all existing functionality works with centralized config across all 6 providers

## Acceptance Criteria

- [ ] AC 1: Single `DefaultModelConfig` class provides all fallback models for all 6 providers
- [ ] AC 2: All hardcoded `DEFAULT_MODEL` constants replaced with centralized config calls
- [ ] AC 3: Google client uses same default model as before ('gemini-2.0-flash-lite')
- [ ] AC 4: Anthropic client uses same default model as before ('claude-3-5-haiku-20241022') 
- [ ] AC 5: OpenAI client uses same default model as before ('gpt-4o-mini')
- [ ] AC 6: Mistral client uses same default model as before ('open-mistral-nemo')
- [ ] AC 7: Together AI client uses same default model as before ('mistralai/Mistral-7B-Instruct-v0.3')
- [ ] AC 8: LM Studio client uses same default model as before ('mistralai/devstral-small-2505')
- [ ] AC 9: Provider-only syntax continues to work: `llm-query google "prompt"` uses default model
- [ ] AC 10: Provider:model syntax continues to work: `llm-query google:gemini-pro "prompt"`
- [ ] AC 11: Configuration validates that all 6 providers have default models
- [ ] AC 12: `ProviderModelParser` uses centralized config instead of hardcoded hash
- [ ] AC 13: Models command uses centralized config for default model identification  
- [ ] AC 14: All existing functionality preserved with reduced duplication
- [ ] AC 15: `DefaultModelConfig` has correct values matching current system (not the incorrect ones currently in the class)
- [ ] AC 16: New configuration is easily extensible for additional providers

## Out of Scope

- ❌ Implementing user-customizable configuration files
- ❌ Adding new providers beyond the existing 6
- ❌ Changing existing default model selections (maintain current values)
- ❌ Runtime model discovery or dynamic defaults
- ❌ Complex configuration management features
- ❌ Model availability validation or API health checks
- ❌ Provider command consolidation (already completed in task 44)
- ❌ Executable cleanup (unified architecture already implemented)

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Models Layer](../../../../docs/architecture.md#models-data-layer)
- [Configuration Management Patterns](../../../../docs-dev/guides/coding-standards.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)