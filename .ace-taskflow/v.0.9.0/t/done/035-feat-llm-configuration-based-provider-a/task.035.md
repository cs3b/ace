---
id: v.0.9.0+task.035
status: done
estimate: 2 days
dependencies: [task.021]
---

# Implement configuration-based provider architecture for ace-llm

## Description

Implement a configuration-based provider registration system for ace-llm that allows providers to be defined via YAML configuration files. This replaces the hardcoded case statement in the executable with a dynamic, extensible system that supports gem-based provider plugins and custom providers.

## Behavioral Specification

The system will use YAML files in `.ace/llm/providers/` to define provider configurations, enabling dynamic loading and registration of LLM providers without modifying the core code.

### Provider Configuration Format

```yaml
# .ace/llm/providers/google.yml
name: google
class: Ace::LLM::Organisms::GoogleClient
gem: ace-llm  # Gem that provides this class
models:
  - gemini-2.5-flash
  - gemini-2.5-pro
api_key:
  env: GEMINI_API_KEY
  required: true
capabilities:
  - text_generation
  - streaming
  - function_calling
default_options:
  temperature: 1.0
  max_tokens: 8192
```

### Custom Provider Support

```yaml
# .ace/llm/providers/custom-local.yml
name: custom-local
class: CustomProviders::LocalLLM
gem: custom-llm-provider  # External gem
endpoint: http://localhost:8080
models:
  - llama-3.2
  - mistral-7b
api_key:
  required: false
```

## Acceptance Criteria

- [x] ClientRegistry class created to manage provider registration
- [x] YAML configuration loader implemented
- [x] Default provider configurations created
- [x] Dynamic gem loading support added
- [x] Backward compatibility maintained with existing code
- [x] Provider discovery from multiple directories (.ace/llm/providers/, ~/.config/ace-llm/providers/)
- [x] Validation of provider configurations on load
- [x] Clear error messages for missing gems or invalid configs
- [x] Tests for configuration loading and provider instantiation

## Planning Steps

* [x] Design ClientRegistry interface
* [x] Define provider configuration schema
* [x] Plan gem loading strategy
* [x] Design error handling approach

## Execution Steps

### Phase 1: Core Registry Implementation

- [x] Create `ace-llm/lib/ace/llm/molecules/client_registry.rb`
  - Load provider configurations from YAML
  - Validate configuration schema
  - Cache loaded configurations
  - Provide lookup interface

- [x] Create `ace-llm/lib/ace/llm/atoms/provider_config_validator.rb`
  - Validate required fields (name, class, gem)
  - Validate model lists
  - Validate API key requirements
  - Return validation errors

- [x] Create `ace-llm/lib/ace/llm/molecules/provider_loader.rb`
  - Attempt to require provider gem
  - Load provider class dynamically
  - Handle missing gems gracefully
  - Support optional dependencies

### Phase 2: Default Configurations

- [x] Create default provider configurations
  - `.ace/llm/providers/google.yml`
  - `.ace/llm/providers/openai.yml`
  - `.ace/llm/providers/anthropic.yml`
  - `.ace/llm/providers/mistral.yml`
  - `.ace/llm/providers/togetherai.yml`
  - `.ace/llm/providers/lmstudio.yml`

- [x] Create provider template
  - `.ace/llm/providers/template.yml.example`
  - Document all available options
  - Provide examples for custom providers

### Phase 3: Integration

- [x] Refactor `ace-llm/exe/ace-llm-query`
  - Replace hardcoded case statement with ClientRegistry
  - Load registry on startup
  - Use registry.get_client(provider, model)
  - Handle provider not found errors

- [x] Update ProviderModelParser
  - Integrate with ClientRegistry for validation
  - Check if provider exists in registry
  - Validate model against provider's model list

- [x] Add provider listing capability
  - `ace-llm-query --list-providers`
  - Show available providers and their models
  - Indicate which gems are missing

### Phase 4: Testing and Documentation

- [x] Add tests for ClientRegistry
  - Test configuration loading
  - Test provider instantiation
  - Test error handling
  - Test gem loading

- [x] Update documentation
  - Document provider configuration format
  - Add examples for custom providers
  - Document gem-based provider creation
  - Migration guide from hardcoded providers

## Implementation Notes

This architecture enables:
1. **Extensibility**: New providers can be added without code changes
2. **Modularity**: Providers can be packaged as separate gems
3. **Configuration**: Provider settings can be customized via YAML
4. **Discovery**: System can auto-discover available providers
5. **Validation**: Configurations are validated on load

The implementation maintains backward compatibility while enabling future growth through:
- Support for provider gems (ace-llm-openai, ace-llm-anthropic)
- Custom provider definitions for internal/experimental LLMs
- Configuration cascade for user overrides
- Clear separation between core and provider code

## Related Tasks

- task.021: Extract llm-query from dev-tools to ace-llm gem (completed)
- Future: Create separate provider gems (ace-llm-google, ace-llm-openai, etc.)