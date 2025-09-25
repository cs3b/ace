---
id: v.0.9.0+task.035
status: pending
priority: high
estimate: 2 weeks
dependencies: [v.0.9.0+task.021]
---

# Implement configuration-based provider architecture for ace-llm

## Behavioral Specification

### User Experience
- **Input**: Users create YAML configuration files in `.ace/llm/providers/` to define available LLM providers
- **Process**: ace-llm-query discovers and loads provider configurations dynamically, validating models and settings
- **Output**: Users can query any configured provider with full control over models, settings, and aliases

### Expected Behavior
Users should be able to add new LLM providers without modifying ace-llm code by creating provider configuration files. Each provider config defines the client class, available models, settings, and provider-specific aliases. The system should support both built-in providers and external gem-based providers. Configuration files give users full control over which providers are enabled, what models are available, and provider-specific settings like API endpoints and timeouts.

### Interface Contract
```yaml
# .ace/llm/providers/google.yml
name: google
enabled: true
class: "Ace::LLM::Organisms::GoogleClient"
gem: "ace-llm-google"  # Optional: auto-require if present

settings:
  base_url: "https://generativelanguage.googleapis.com"
  api_key_env: ["GEMINI_API_KEY", "GOOGLE_API_KEY"]
  timeout: 30

models:
  gemini-2.5-flash:
    default: true
    context_window: 1048576
    max_output: 8192
    supports_vision: true
    cost:
      input: 0.000075
      output: 0.0003

aliases:
  flash: "gemini-2.5-flash"
  pro: "gemini-2.5-pro"
```

**CLI remains unchanged**:
```bash
ace-llm-query google:gemini-2.5-flash "prompt"
ace-llm-query --list-providers
ace-llm-query --list-models google
```

### Success Criteria
- [ ] Provider configurations can be loaded from `.ace/llm/providers/*.yml`
- [ ] External gems can provide new providers via configuration
- [ ] Users can enable/disable providers via config
- [ ] Model availability and settings are configurable
- [ ] Provider-specific aliases work alongside global aliases
- [ ] Backward compatibility with existing hardcoded providers

## Objective

Transform ace-llm from a fixed set of hardcoded providers to a configuration-based system that allows users to control available providers, models, and settings through YAML files. This enables adding new providers (including coding agents and aggregate providers) without code changes and prepares for future where each provider is a separate gem.

## Scope of Work

### Phase 1: Provider Configuration Loading
- Create provider configuration schema
- Implement ProviderLoader to discover and load configs
- Enhance ProviderRegistry to work with configurations
- Maintain backward compatibility with existing providers

### Phase 2: Dynamic Provider Management
- Support external gem loading via config
- Implement model validation and discovery
- Add provider-specific settings override
- Create provider listing commands

### Phase 3: Future Preparation
- Design gem separation strategy
- Support aggregate providers (AnyLLM, etc.)
- Enable IDE/agent-specific providers

### Deliverables
- Provider configuration YAML schema
- ProviderLoader implementation
- Enhanced ProviderRegistry with config support
- Updated ace-llm-query to use configuration
- Example provider configurations
- Migration guide for users
- Documentation for adding new providers

## Technical Approach

### Architecture
```
.ace/llm/
├── providers/           # Provider configurations
│   ├── google.yml
│   ├── openai.yml
│   └── custom.yml
└── aliases.yml         # Global aliases (existing)
```

### Implementation Strategy
1. Start with configuration loading alongside hardcoded providers
2. Gradually migrate built-in providers to config files
3. Enable external gem loading
4. Support full provider separation in future

### Key Components

#### ProviderLoader
```ruby
module Ace::LLM
  class ProviderLoader
    def self.load_providers
      # Load from .ace/llm/providers/*.yml
      # Validate configuration schema
      # Register with ProviderRegistry
    end
  end
end
```

#### Enhanced ProviderRegistry
```ruby
class ProviderRegistry
  def self.register(name:, class:, settings:, models:, aliases:)
    # Store provider configuration
    # Validate class availability
    # Handle gem loading if needed
  end

  def self.create_client(provider, model)
    # Use configuration to instantiate client
    # Apply settings overrides
    # Validate model availability
  end
end
```

## Implementation Plan

### Planning Steps

* [ ] Research YAML schema design for provider configs
  - Review existing provider implementations for common patterns
  - Identify all configurable settings across providers
  - Design extensible schema for future needs

* [ ] Analyze gem loading strategies
  - Research Ruby's gem loading mechanisms
  - Design safe gem requirement pattern
  - Plan for missing gem handling

* [ ] Design migration strategy from hardcoded to config-based
  - Plan backward compatibility approach
  - Create migration timeline
  - Identify breaking changes to avoid

### Execution Steps

- [ ] Create provider configuration schema
  - Define YAML structure for provider configs
  - Document all configuration options
  - Create JSON schema for validation

- [ ] Implement ProviderLoader
  - Create loader to discover .ace/llm/providers/*.yml
  - Parse and validate configuration files
  - Handle missing/invalid configurations gracefully

- [ ] Enhance ProviderRegistry
  - Update to store configuration-based providers
  - Implement create_client with config support
  - Add provider querying methods (list, get_models, etc.)

- [ ] Update ace-llm-query executable
  - Integrate ProviderLoader on startup
  - Update create_client to use ProviderRegistry
  - Add --list-providers and --list-models commands

- [ ] Create default provider configurations
  - Convert existing providers to YAML configs
  - Place in ace-llm/.ace.example/llm/providers/
  - Include all current provider settings

- [ ] Implement model discovery
  - Add model listing from configurations
  - Validate requested models against available
  - Show model capabilities/costs when listing

- [ ] Add external gem support
  - Implement safe gem loading from config
  - Handle missing gems gracefully
  - Provide clear error messages

- [ ] Create provider examples
  - Example for Ollama (local provider)
  - Example for AnyLLM (aggregate provider)
  - Example for custom provider

- [ ] Write tests
  - Unit tests for ProviderLoader
  - Integration tests for config-based providers
  - Tests for gem loading functionality

- [ ] Create documentation
  - Provider configuration guide
  - How to add new providers
  - Migration guide from hardcoded providers

## Acceptance Criteria

- [ ] All existing providers work via configuration files
- [ ] New providers can be added without code changes
- [ ] External gems can provide providers via config
- [ ] Users can control models and settings per provider
- [ ] Provider discovery commands work correctly
- [ ] Backward compatibility maintained
- [ ] Clear documentation for adding providers
- [ ] Tests pass for all scenarios

## Risk Assessment

### Technical Risks
- **Gem loading security**: Loading arbitrary gems could be security risk
  - Mitigation: Require explicit gem names, warn users
- **Configuration complexity**: YAML files might become complex
  - Mitigation: Provide good examples and validation
- **Performance impact**: Dynamic loading might slow startup
  - Mitigation: Lazy loading, caching strategies

### Compatibility Risks
- **Breaking existing usage**: Current users might be affected
  - Mitigation: Full backward compatibility in Phase 1
- **Provider gem conflicts**: External gems might conflict
  - Mitigation: Clear naming conventions, dependency management

## References

- Current implementation: ace-llm/exe/ace-llm-query
- Provider examples: ace-llm/lib/ace/llm/organisms/*_client.rb
- Configuration pattern: ace-core configuration cascade
- Similar systems: Faraday adapters, OmniAuth strategies