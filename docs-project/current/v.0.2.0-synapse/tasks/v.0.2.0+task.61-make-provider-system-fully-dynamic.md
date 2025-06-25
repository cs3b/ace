---
id: v.0.2.0+task.61
status: done
priority: medium
estimate: 3h
dependencies: ["v.0.2.0+task.60"]
---

# Make Provider System Fully Dynamic by Moving Configuration to Client Classes

## Objective / Problem

Currently, the ProviderModelParser contains hardcoded constants for supported providers and dynamic aliases:

```ruby
SUPPORTED_PROVIDERS = %w[
  google
  anthropic
  openai
  mistral
  together_ai
  lmstudio
].freeze

DYNAMIC_ALIASES = {
  "gflash" => "google:gemini-2.5-flash",
  "gpro" => "google:gemini-2.5-pro",
  "csonet" => "anthropic:claude-4-0-sonnet-latest",
  "copus" => "anthropic:claude-4-0-opus-latest",
  "o4mini" => "openai:gpt-4o-mini",
  "o3" => "openai:o3"
}.freeze
```

This creates maintenance overhead when adding new providers - developers must update these hardcoded lists. We should move this configuration to the client classes themselves and have the ProviderModelParser pull this information dynamically during client registration.

## Directory Audit

Current provider-related files:
```
lib/coding_agent_tools/
├── molecules/
│   ├── provider_model_parser.rb    # Contains hardcoded constants
│   └── client_factory.rb           # Handles client registration
├── organisms/
│   ├── google_client.rb            # Should define own aliases
│   ├── anthropic_client.rb         # Should define own aliases
│   ├── openai_client.rb            # Should define own aliases
│   ├── mistral_client.rb           # Should define own aliases
│   ├── togetherai_client.rb        # Should define own aliases
│   └── lmstudio_client.rb          # Should define own aliases
└── cli/commands/llm/
    └── models.rb                   # Uses provider constants
```

## Scope of Work

- Move SUPPORTED_PROVIDERS from hardcoded constant to dynamic discovery
- Move DYNAMIC_ALIASES from hardcoded constant to client-defined aliases
- Update client classes to define their own aliases via class methods
- Modify ProviderModelParser to collect provider info during registration
- Update ClientFactory registration flow to collect provider metadata
- Ensure CLI commands still work with dynamic provider discovery

## Deliverables / Manifest

| File | Action | Purpose |
|------|--------|---------|
| `lib/coding_agent_tools/organisms/*_client.rb` | Modify | Add class method for defining aliases |
| `lib/coding_agent_tools/molecules/provider_model_parser.rb` | Modify | Remove hardcoded constants, use dynamic collections |
| `lib/coding_agent_tools/molecules/client_factory.rb` | Modify | Collect provider metadata during registration |
| `lib/coding_agent_tools/cli/commands/llm/models.rb` | Modify | Use dynamic provider discovery |
| `spec/coding_agent_tools/molecules/provider_model_parser_spec.rb` | Modify | Update tests for dynamic behavior |
| `spec/coding_agent_tools/organisms/*_client_spec.rb` | Modify | Test alias definitions |

## Phases

1. **Analysis** - Understand current provider registration flow
2. **Design** - Plan client-side alias definition API
3. **Implementation** - Move constants to client classes and update parser
4. **Integration** - Update CLI commands and ensure compatibility
5. **Testing** - Verify dynamic discovery works correctly

## Implementation Plan

### Planning Steps
* [x] Analyze current provider registration flow in ClientFactory and ProviderModelParser
* [x] Design client-side API for defining aliases (class method signature)
* [x] Plan how ProviderModelParser will collect and store dynamic provider info
* [x] Identify all places that use SUPPORTED_PROVIDERS and DYNAMIC_ALIASES constants

### Execution Steps
- [x] Add class method `dynamic_aliases` to all client classes to define their aliases:
  ```ruby
  # Example for GoogleClient
  def self.dynamic_aliases
    {
      "gflash" => "google:gemini-2.5-flash",
      "gpro" => "google:gemini-2.5-pro"
    }
  end
  ```
- [x] Update ClientFactory to collect provider metadata during registration:
  - Collect provider_name from existing method
  - Collect dynamic_aliases from new method
  - Pass this metadata to ProviderModelParser
- [x] Modify ProviderModelParser to use dynamic collections instead of constants:
  - Replace SUPPORTED_PROVIDERS with instance variable populated during registration
  - Replace DYNAMIC_ALIASES with merged aliases from all clients
  - Update all methods that reference these constants
- [x] Update CLI commands to use dynamic provider discovery
- [x] Remove hardcoded constants from ProviderModelParser
- [x] Add tests for client alias definitions
  > TEST: Client Alias Definitions
  > Type: Unit Test
  > Assert: Each client class responds to dynamic_aliases and returns expected format
  > Command: bin/test spec/coding_agent_tools/organisms/*_client_spec.rb -t "dynamic_aliases"
- [x] Update ProviderModelParser tests for dynamic behavior
  > TEST: Dynamic Provider Discovery
  > Type: Integration Test
  > Assert: ProviderModelParser discovers providers and aliases dynamically
  > Command: bin/test spec/coding_agent_tools/molecules/provider_model_parser_spec.rb
- [x] Run full test suite to ensure no regressions
  > TEST: Full Test Suite
  > Type: Regression Test
  > Assert: All tests pass with dynamic provider system
  > Command: bin/test

## Acceptance Criteria

- [x] No hardcoded SUPPORTED_PROVIDERS constant exists in ProviderModelParser
- [x] No hardcoded DYNAMIC_ALIASES constant exists in ProviderModelParser
- [x] Each client class defines its own aliases via dynamic_aliases class method
- [x] ProviderModelParser dynamically discovers providers during client registration
- [x] CLI commands work correctly with dynamic provider discovery
- [x] Adding a new client requires no updates to ProviderModelParser constants
- [x] All existing functionality (aliases, provider validation) works unchanged
- [x] All tests pass with the new dynamic system

## Out of Scope

- Changing the external API or CLI interface
- Modifying provider names returned by provider_name methods
- Updating the BaseClient hierarchy
- Changing how client registration works (only what metadata is collected)

## References & Risks

- Current implementation in ProviderModelParser.rb:231-250
- ClientFactory registration flow
- Risk: Breaking existing alias functionality during migration
- Risk: Provider discovery timing issues if clients aren't loaded
- Mitigation: Preserve existing ensure_providers_loaded mechanism
- Mitigation: Comprehensive testing of dynamic discovery

## Notes

This task completes the dynamic provider system by eliminating the last hardcoded dependencies. After completion, adding a new LLM provider will require only creating the client class with proper class methods - no updates to shared constants or registration logic.