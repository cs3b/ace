---
id: v.0.2.0+task.54
title: Refactor build_client Method to Use Factory Pattern
created_at: '2025-06-24T20:04:00Z'
updated_at: '2025-06-24T20:04:00Z'
release: v.0.2.0
status: done
priority: medium
tags: [refactoring, design-pattern, factory, scalability]
owner: TBD
estimate: 3-4h
dependencies: [task.44, task.45]
note: |
  As identified in the code review from gpro (commits-after-1361d77-20250624-205941/cr-report-gpro.md),
  the current case statement approach in build_client method works well for 6 providers but may become
  a maintenance bottleneck as more providers are added.
---

# Task: Refactor build_client Method to Use Factory Pattern

## Objective

Replace the case statement in `lib/coding_agent_tools/cli/commands/llm/query.rb`'s `build_client` method with a factory pattern or registry to improve long-term maintainability and scalability as new LLM providers are added.

## Directory Audit

```bash
# Current structure
lib/coding_agent_tools/
├── cli/
│   └── commands/
│       └── llm/
│           └── query.rb  # Contains build_client method with case statement
├── organisms/
│   ├── base_client.rb
│   ├── base_chat_completion_client.rb
│   ├── google_client.rb
│   ├── anthropic_client.rb
│   ├── openai_client.rb
│   ├── mistral_client.rb
│   ├── together_ai_client.rb
│   └── lm_studio_client.rb
└── molecules/
    └── provider_model_parser.rb
```

## Scope of Work

Refactor the `build_client` method to use a more scalable pattern that:
1. Eliminates the need to modify the method when adding new providers
2. Maintains type safety and clear error messages
3. Follows ATOM architecture principles
4. Preserves existing functionality and error handling

## Deliverables

### Files to Modify
- [ ] `lib/coding_agent_tools/cli/commands/llm/query.rb` - Refactor build_client method
- [ ] `lib/coding_agent_tools/organisms/base_client.rb` - Add provider registration mechanism

### Files to Create
- [ ] `lib/coding_agent_tools/molecules/client_factory.rb` - New factory class for client instantiation
- [ ] `spec/coding_agent_tools/molecules/client_factory_spec.rb` - Tests for factory

## Phases

1. **Design Phase**: Determine optimal factory pattern approach
2. **Implementation Phase**: Create factory and refactor build_client
3. **Migration Phase**: Update all client classes to register themselves
4. **Testing Phase**: Ensure all functionality preserved

## Implementation Plan

### Planning Steps
* [x] Analyze current build_client implementation and usage patterns
  > TEST: Current Implementation Analysis
  >   Type: Pre-condition Check
  >   Assert: All provider cases are documented
  >   Command: grep -A 20 "def build_client" lib/coding_agent_tools/cli/commands/llm/query.rb
  >   Result: Found 6 provider cases: google, anthropic, openai, mistral, together_ai, lmstudio
* [x] Design factory pattern that fits ATOM architecture
  > Result: ClientFactory molecule with auto-registration via inherited hook
* [x] Determine registration mechanism (class method, module inclusion, etc.)
  > Result: Use self.inherited hook in BaseClient for auto-registration
* [x] Plan backward compatibility approach
  > Result: Keep build_client method signature identical, change implementation only

### Execution Steps
- [x] Create ClientFactory molecule class
  ```ruby
  module CodingAgentTools
    module Molecules
      class ClientFactory
        class << self
          def register(provider_name, client_class)
            # Implementation
          end
          
          def build(provider_name, options = {})
            # Implementation
          end
        end
      end
    end
  end
  ```
- [x] Add registration mechanism to BaseClient
  ```ruby
  class BaseClient
    def self.inherited(subclass)
      super
      # Auto-register subclass with factory
    end
    
    def self.provider_key
      # Override in subclasses
    end
  end
  ```
- [x] Update each client class to register itself
  > Result: Auto-registration via inherited hook - no changes needed to individual client classes
  > TEST: Client Registration
  >   Type: Action Validation
  >   Assert: All 6 client classes are registered
  >   Command: bin/console -e "CodingAgentTools::Molecules::ClientFactory.registered_providers.count"
- [x] Refactor build_client to use factory
  ```ruby
  def build_client(provider)
    CodingAgentTools::Molecules::ClientFactory.build(provider, api_key: api_key)
  rescue ClientFactory::UnknownProviderError => e
    raise ArgumentError, e.message
  end
  ```
- [x] Add comprehensive tests for factory behavior
- [x] Update integration tests to verify all providers still work
  > TEST: Provider Integration
  >   Type: Action Validation
  >   Assert: All providers can be instantiated via factory
  >   Command: bundle exec rspec spec/integration/llm_query_integration_spec.rb
  >   Result: All 44 integration tests pass - all providers work correctly via factory

## Acceptance Criteria

- [x] Case statement is replaced with factory pattern
- [x] Adding new providers requires no changes to query.rb
- [x] All existing providers continue to work
- [x] Error messages for unknown providers remain clear
- [x] Factory follows ATOM architecture (Molecule component)
- [x] Test coverage maintained at 100%
- [x] Performance is not negatively impacted

## Out of Scope

- Changing the public CLI interface
- Modifying provider client implementations beyond registration
- Adding new providers
- Changing error handling behavior

## References

- Code review report: `docs-project/current/v.0.2.0-synapse/code_review/commits-after-1361d77-20250624-205941/cr-report-gpro.md` (line 67-69)
- Current implementation: `lib/coding_agent_tools/cli/commands/llm/query.rb:build_client`
- [ATOM Architecture Guide](docs-dev/guides/atom-architecture-house-rules.g.md)

## Risks & Mitigations

**Risk**: Auto-registration might create unexpected dependencies or load order issues
**Mitigation**: Use explicit registration with clear error messages if registration fails

**Risk**: Factory pattern might be over-engineering for current needs
**Mitigation**: Keep implementation simple and focused on current use case, avoid premature optimization