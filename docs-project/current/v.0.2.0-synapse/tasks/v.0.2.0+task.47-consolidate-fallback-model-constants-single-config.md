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
grep -r "fallback\|default.*model" . --include="*.rb" | grep -v spec | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/organisms/gemini_client.rb:    DEFAULT_MODEL = 'gemini-1.5-flash'
./lib/coding_agent_tools/organisms/lm_studio_client.rb:    DEFAULT_MODEL = 'llama-3.2-3b-instruct'
./lib/coding_agent_tools/cli/commands/llm/gemini_query.rb:      fallback_model = 'gemini-1.5-flash'
./lib/coding_agent_tools/cli/commands/lms/studio_query.rb:      fallback_model = 'llama-3.2-3b-instruct'
```

## Objective

Consolidate scattered fallback model constants into a single, centralized configuration source to eliminate duplication and provide a single source of truth for default model selections. This addresses Priority 2 requirement #5 from the code review findings and ensures consistent fallback behavior across all components.

## Scope of Work

- Create centralized configuration class for default models
- Extract hardcoded fallback constants from multiple locations
- Implement provider-specific default model mapping
- Update all clients and commands to use centralized configuration
- Add configuration validation and error handling
- Ensure backward compatibility with existing behavior

### Deliverables

#### Create

- `lib/coding_agent_tools/models/default_model_config.rb`
- `spec/coding_agent_tools/models/default_model_config_spec.rb`
- `config/default_models.yml` (optional configuration file)

#### Modify

- `lib/coding_agent_tools/organisms/gemini_client.rb` (remove hardcoded constant)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (remove hardcoded constant)
- `lib/coding_agent_tools/cli/commands/llm/gemini_query.rb` (use centralized config)
- `lib/coding_agent_tools/cli/commands/lms/studio_query.rb` (use centralized config)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- Hardcoded DEFAULT_MODEL constants from individual classes

## Phases

1. Audit all locations with fallback/default model constants
2. Design centralized configuration structure
3. Implement configuration class with provider mapping
4. Refactor existing classes to use centralized config
5. Add validation and comprehensive testing
6. Verify no behavioral changes

## Implementation Plan

### Planning Steps

* [ ] Audit all locations where default/fallback models are defined
  > TEST: Audit Complete
  > Type: Pre-condition Check
  > Assert: All hardcoded model constants are catalogued
  > Command: grep -r "DEFAULT_MODEL\|fallback.*model" . --include="*.rb" | wc -l
* [ ] Design configuration structure with provider-specific mappings
* [ ] Plan migration strategy to avoid breaking existing functionality
* [ ] Design validation rules for model configuration

### Execution Steps

- [ ] Create `DefaultModelConfig` class with provider-to-model mapping
  > TEST: Config Class Creation
  > Type: Action Validation
  > Assert: DefaultModelConfig compiles and provides expected interface
  > Command: ruby -c lib/coding_agent_tools/models/default_model_config.rb
- [ ] Implement methods to retrieve default models by provider
- [ ] Add configuration validation to ensure all providers have defaults
- [ ] Create optional YAML configuration file for easy customization
- [ ] Update `GeminiClient` to use centralized configuration
  > TEST: Gemini Client Update
  > Type: Action Validation
  > Assert: GeminiClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/gemini_client_spec.rb
- [ ] Update `LMStudioClient` to use centralized configuration
  > TEST: LM Studio Client Update
  > Type: Action Validation
  > Assert: LMStudioClient uses centralized config and maintains same default behavior
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
- [ ] Update CLI commands to use centralized configuration
- [ ] Remove hardcoded DEFAULT_MODEL constants from all classes
- [ ] Add comprehensive tests for configuration class
  > TEST: Configuration Test Coverage
  > Type: Action Validation
  > Assert: DefaultModelConfig has >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/models/default_model_config_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Update library requires and ensure proper loading order
- [ ] Validate all existing functionality works with centralized config

## Acceptance Criteria

- [ ] AC 1: Single `DefaultModelConfig` class provides all fallback models
- [ ] AC 2: All hardcoded DEFAULT_MODEL constants removed from individual classes
- [ ] AC 3: Gemini client uses same default model as before ('gemini-1.5-flash')
- [ ] AC 4: LM Studio client uses same default model as before ('llama-3.2-3b-instruct')
- [ ] AC 5: CLI commands maintain identical fallback behavior
- [ ] AC 6: Configuration validates that all providers have default models
- [ ] AC 7: All existing tests pass without modification
- [ ] AC 8: New configuration is easily extensible for additional providers

## Out of Scope

- ❌ Implementing user-customizable configuration (beyond optional YAML)
- ❌ Adding new providers or changing existing default model selections
- ❌ Runtime model discovery or dynamic defaults
- ❌ Complex configuration management features

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Models Layer](../../../../docs/architecture.md#models-data-layer)
- [Configuration Management Patterns](../../../../docs-dev/guides/coding-standards.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)