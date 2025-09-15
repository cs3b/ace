---
id: v.0.5.0+task.048
status: done
priority: high
estimate: 6-8 hours
dependencies: []
---

# Implement LLM Aliases System and Remove Model Fetching Infrastructure

## Objective

Replace the complex model fetching/caching system with a simple, user-configurable aliases system that allows users to define shortcuts for their preferred LLM models.

## Background

- Currently llm-query uses a complex model fetching and caching system
- Users typically use only a handful of models
- The model fetching adds unnecessary complexity and API calls
- A simple YAML-based alias system would be more flexible and user-friendly

## Scope

1. Create a configurable alias system for LLM models
2. Support both global aliases (work anywhere) and provider-specific aliases
3. Remove the entire llm-models command and related infrastructure
4. Simplify provider clients (especially ClaudeCodeClient)

## Key Requirements

- Create config/default-llm-aliases.yml with sensible defaults
- Implement LlmAliasResolver molecule for alias resolution
- Update llm-query to use alias resolver
- Remove llm-models command and all model fetching/caching code
- Maintain backward compatibility (direct model names still work)

## Example Aliases to Implement

**Global aliases:**
- opus → cc:claude-opus-4-1
- gpt5 → openai:gpt-5
- gpro → google:gemini-2.5-pro

**Provider-specific aliases:**
- cc:opus → claude-opus-4-1
- openai:mini → gpt-5-mini

## Implementation Plan

### Planning Steps

* [ ] Review current model fetching implementation in llm-models command
* [ ] Identify all files that import or use CacheManager
* [ ] Map out all provider clients that have list_models methods
* [ ] Design the default aliases YAML structure with examples
* [ ] Plan the LlmAliasResolver class interface

### Execution Steps

- [ ] Create config/default-llm-aliases.yml with aliases:
  ```yaml
  global:
    gpro: "google:gemini-2.5-pro"
    gflash: "google:gemini-2.5-flash"
    gfast: "google:gemini-2.0-flash-lite"
    opus: "cc:claude-opus-4-1"
    sonnet: "cc:claude-sonnet-4-0"
    haiku: "cc:claude-3-5-haiku-latest"
    gpt5: "openai:gpt-5"
    gpt5mini: "openai:gpt-5-mini"
    gpt5nano: "openai:gpt-5-nano"
  providers:
    cc:
      opus: "claude-opus-4-1"
      opus4: "claude-opus-4-0"
      sonnet: "claude-sonnet-4-0"
      haiku: "claude-3-5-haiku-latest"
    google:
      pro: "gemini-2.5-pro"
      flash: "gemini-2.5-flash"
      lite: "gemini-2.0-flash-lite"
    openai:
      gpt5: "gpt-5"
      mini: "gpt-5-mini"
      nano: "gpt-5-nano"
  ```

- [ ] Create lib/coding_agent_tools/molecules/llm_alias_resolver.rb
  - [ ] Load config from ~/.config/coding-agent-tools/llm-aliases.yml
  - [ ] Fall back to default aliases if user config missing
  - [ ] Implement resolve(input) method with proper precedence

- [ ] Update lib/coding_agent_tools/cli/commands/llm/query.rb
  - [ ] Add alias resolution before provider parsing
  - [ ] Ensure backward compatibility

- [ ] Simplify lib/coding_agent_tools/organisms/claude_code_client.rb
  - [ ] Remove MODEL_MAPPING constant
  - [ ] Simplify or remove list_models method
  - [ ] Remove model normalization logic

- [ ] Delete model fetching infrastructure:
  - [ ] exe/llm-models
  - [ ] lib/coding_agent_tools/cli/commands/llm/models.rb
  - [ ] spec/coding_agent_tools/cli/commands/llm/models_spec.rb
  - [ ] lib/coding_agent_tools/molecules/cache_manager.rb
  - [ ] spec/coding_agent_tools/molecules/cache_manager_spec.rb
  - [ ] config/fallback_models.yaml

- [ ] Clean up references:
  - [ ] Remove models command from CLI registry
  - [ ] Remove CacheManager imports
  - [ ] Update any documentation mentioning llm-models

- [ ] Add tests for alias resolver
- [ ] Test the complete flow with various aliases
- [ ] Verify backward compatibility works

## Acceptance Criteria

- [ ] LlmAliasResolver molecule is implemented and functional
- [ ] config/default-llm-aliases.yml exists with sensible defaults
- [ ] llm-query command supports alias resolution for all providers
- [ ] Global aliases work (e.g., `llm-query opus "test"` resolves to Claude)
- [ ] Provider-specific aliases work (e.g., `llm-query cc:opus "test"`)
- [ ] Backward compatibility maintained (direct model names still work)
- [ ] llm-models command is completely removed
- [ ] Model fetching/caching infrastructure is removed
- [ ] ClaudeCodeClient is simplified (no model fetching)
- [ ] All tests pass
- [ ] CLI help reflects new alias system
- [ ] Documentation is updated

## Technical Notes

- Consider using dry-configurable for YAML configuration loading
- Ensure alias resolution happens early in llm-query processing
- Maintain clear separation between alias resolution and provider selection
- Test edge cases like circular aliases and missing configurations
