---
id: v.0.2.0+task.44
status: pending
priority: high
estimate: 8h
dependencies: [v.0.2.0+task.43]
---

# Implement Unified LLM Query Entry-Point

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*llm*query*" -type f | head -10
```

_Result excerpt:_

```
./exe/llm-google-query
./exe/llm-anthropic-query
./exe/llm-openai-query
./exe/llm-mistral-query
./exe/llm-together-ai-query
./exe/llm-lmstudio-query
./lib/coding_agent_tools/cli/commands/google/query.rb
./lib/coding_agent_tools/cli/commands/anthropic/query.rb
./lib/coding_agent_tools/cli/commands/openai/query.rb
./lib/coding_agent_tools/cli/commands/mistral/query.rb
```

## Objective

Introduce a unified entry-point `llm-query <provider>:<model> <prompt>` that consolidates all LLM provider interactions under a single command. This addresses Priority 1 requirement #2 from the code review findings and provides a more ergonomic interface while maintaining backward compatibility through wrapper scripts. The system now supports 6 providers: google, anthropic, openai, mistral, together_ai, and lmstudio.

## Scope of Work

- Create new unified `llm-query` executable with provider:model syntax
- Remove `--model` flag in favor of positional argument parsing
- Implement dynamic shorthand aliases pointing to latest models (gflash, gpro, csonet, copus, o4mini, o3, etc.)
- Create thin wrapper scripts for backward compatibility across all 6 providers
- Update command routing to handle provider:model parsing for all providers
- Add comprehensive error handling for invalid provider:model combinations

### Deliverables

#### Create

- `exe/llm-query` (new unified executable)
- `lib/coding_agent_tools/cli/commands/llm/unified_query.rb`
- `lib/coding_agent_tools/molecules/provider_model_parser.rb`
- `exe/gflash` (alias for google:gemini-2.5-flash)
- `exe/gpro` (alias for google:gemini-2.5-pro)
- `exe/csonet` (alias for anthropic:claude-4-0-sonnet-latest)
- `exe/copus` (alias for anthropic:claude-4-0-opus-latest)
- `exe/o4mini` (alias for openai:gpt-4o-mini)
- `exe/o3` (alias for openai:o3)
- `spec/coding_agent_tools/cli/commands/llm/unified_query_spec.rb`
- `spec/coding_agent_tools/molecules/provider_model_parser_spec.rb`

#### Modify

- `lib/coding_agent_tools/cli/commands.rb` (register unified command)
- `coding_agent_tools.gemspec` (add new executables)
- `exe/llm-google-query` (convert to wrapper script)
- `exe/llm-anthropic-query` (convert to wrapper script)
- `exe/llm-openai-query` (convert to wrapper script)
- `exe/llm-mistral-query` (convert to wrapper script)
- `exe/llm-together-ai-query` (convert to wrapper script)
- `exe/llm-lmstudio-query` (convert to wrapper script)
- Documentation and help text

#### Delete

- None (maintain backward compatibility)

## Phases

1. Design provider:model parsing system for all 6 providers
2. Implement unified command infrastructure
3. Create dynamic shorthand alias executables pointing to latest models
4. Convert existing executables to wrapper scripts for all providers
5. Update documentation and help systems
6. Add comprehensive testing for multi-provider support

## Implementation Plan

### Planning Steps

* [ ] Design provider:model syntax specification and validation rules for all 6 providers
  > TEST: Syntax Design Complete
  > Type: Pre-condition Check
  > Assert: Provider:model syntax is documented with examples and edge cases for all providers
  > Command: test -f docs/provider-model-syntax.md
* [ ] Research model naming conventions across all 6 providers (google, anthropic, openai, mistral, together_ai, lmstudio)
* [ ] Plan dynamic alias strategy that points to latest models (gflash→gemini-2.5-flash, csonet→claude-4-0-sonnet-latest, etc.)
* [ ] Design error handling for invalid provider:model combinations across all providers

### Execution Steps

- [ ] Create `ProviderModelParser` molecule for parsing provider:model syntax across all 6 providers
  > TEST: Parser Creation
  > Type: Action Validation
  > Assert: Parser correctly handles valid and invalid syntax for all providers
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_model_parser_spec.rb
- [ ] Implement `UnifiedQuery` command class with multi-provider routing
- [ ] Add provider:model validation and error handling for all 6 providers
- [ ] Create unified `llm-query` executable
- [ ] Implement dynamic shorthand alias executables (gflash, gpro, csonet, copus, o4mini, o3, etc.)
  > TEST: Alias Functionality
  > Type: Action Validation
  > Assert: All alias executables properly delegate to unified command with latest models
  > Command: exe/gflash --help | grep -q "google:gemini-2.5-flash"
- [ ] Convert all existing provider executables to thin wrapper scripts
- [ ] Update CLI command registration for multi-provider support
- [ ] Add comprehensive test coverage for all new components and providers
  > TEST: Test Coverage
  > Type: Action Validation
  > Assert: All new code has test coverage above 95%
  > Command: bundle exec rspec --format json | jq '.summary.coverage_percent'
- [ ] Update help text and documentation for all providers
- [ ] Update gemspec with new executables

## Acceptance Criteria

- [ ] AC 1: `llm-query google:gemini-2.5-flash "test prompt"` works correctly
- [ ] AC 2: `llm-query anthropic:claude-4-0-sonnet-latest "test prompt"` works correctly
- [ ] AC 3: `llm-query openai:gpt-4o "test prompt"` works correctly
- [ ] AC 4: `llm-query lmstudio:model-name "test prompt"` works correctly
- [ ] AC 5: Invalid provider:model combinations show helpful error messages for all providers
- [ ] AC 6: All shorthand aliases work and dynamically point to latest models
- [ ] AC 7: Backward compatibility maintained - all existing provider executables still work
- [ ] AC 8: Help system shows all 6 available providers and example usage
- [ ] AC 9: All tests pass with >95% coverage on new components

## Out of Scope

- ❌ Removing existing individual provider executables
- ❌ Implementing additional LLM providers beyond the existing 6
- ❌ Complex model discovery or recommendation features
- ❌ Interactive provider selection UI
- ❌ Real-time model availability checking for "latest" aliases

## References

- [Code Review Task 39 - Priority 1 Requirements](../code-review/task.39/cr-user.md)
- [CLI Architecture Patterns](../../../../docs/architecture.md#cli-command-layer)
- [ATOM Pattern for Molecules](../../../../docs-dev/guides/atom-house-rules.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)