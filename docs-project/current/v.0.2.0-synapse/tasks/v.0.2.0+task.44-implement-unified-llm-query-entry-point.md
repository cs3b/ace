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
./exe/llm-gemini-query
./exe/lms-studio-query
./lib/coding_agent_tools/cli/commands/llm/gemini_query.rb
./lib/coding_agent_tools/cli/commands/lms/studio_query.rb
```

## Objective

Introduce a unified entry-point `llm-query <provider>:<model> <prompt>` that consolidates all LLM provider interactions under a single command. This addresses Priority 1 requirement #2 from the code review findings and provides a more ergonomic interface while maintaining backward compatibility through wrapper scripts.

## Scope of Work

- Create new unified `llm-query` executable with provider:model syntax
- Remove `--model` flag in favor of positional argument parsing
- Implement popular shorthand aliases (gflash, gpro, o3, o4-mini, etc.)
- Create thin wrapper scripts for backward compatibility
- Update command routing to handle provider:model parsing
- Add comprehensive error handling for invalid provider:model combinations

### Deliverables

#### Create

- `exe/llm-query` (new unified executable)
- `lib/coding_agent_tools/cli/commands/llm/unified_query.rb`
- `lib/coding_agent_tools/molecules/provider_model_parser.rb`
- `exe/gflash` (alias for google:gemini-1.5-flash)
- `exe/gpro` (alias for google:gemini-1.5-pro)
- `exe/o3` (alias for openai:gpt-3.5-turbo)
- `exe/o4-mini` (alias for openai:gpt-4o-mini)
- `spec/coding_agent_tools/cli/commands/llm/unified_query_spec.rb`
- `spec/coding_agent_tools/molecules/provider_model_parser_spec.rb`

#### Modify

- `lib/coding_agent_tools/cli/commands.rb` (register unified command)
- `coding_agent_tools.gemspec` (add new executables)
- `exe/llm-gemini-query` (convert to wrapper script)
- `exe/lms-studio-query` (convert to wrapper script)
- Documentation and help text

#### Delete

- None (maintain backward compatibility)

## Phases

1. Design provider:model parsing system
2. Implement unified command infrastructure
3. Create shorthand alias executables
4. Convert existing executables to wrapper scripts
5. Update documentation and help systems
6. Add comprehensive testing

## Implementation Plan

### Planning Steps

* [ ] Design provider:model syntax specification and validation rules
  > TEST: Syntax Design Complete
  > Type: Pre-condition Check
  > Assert: Provider:model syntax is documented with examples and edge cases
  > Command: test -f docs/provider-model-syntax.md
* [ ] Research popular model naming conventions across providers
* [ ] Plan alias naming strategy for maximum ergonomics
* [ ] Design error handling for invalid provider:model combinations

### Execution Steps

- [ ] Create `ProviderModelParser` molecule for parsing provider:model syntax
  > TEST: Parser Creation
  > Type: Action Validation
  > Assert: Parser correctly handles valid and invalid syntax
  > Command: bundle exec rspec spec/coding_agent_tools/molecules/provider_model_parser_spec.rb
- [ ] Implement `UnifiedQuery` command class with provider routing
- [ ] Add provider:model validation and error handling
- [ ] Create unified `llm-query` executable
- [ ] Implement shorthand alias executables (gflash, gpro, etc.)
  > TEST: Alias Functionality
  > Type: Action Validation
  > Assert: All alias executables properly delegate to unified command
  > Command: exe/gflash --help | grep -q "google:gemini-1.5-flash"
- [ ] Convert existing executables to thin wrapper scripts
- [ ] Update CLI command registration
- [ ] Add comprehensive test coverage for all new components
  > TEST: Test Coverage
  > Type: Action Validation
  > Assert: All new code has test coverage above 95%
  > Command: bundle exec rspec --format json | jq '.summary.coverage_percent'
- [ ] Update help text and documentation
- [ ] Update gemspec with new executables

## Acceptance Criteria

- [ ] AC 1: `llm-query google:gemini-1.5-flash "test prompt"` works correctly
- [ ] AC 2: `llm-query lmstudio:model-name "test prompt"` works correctly
- [ ] AC 3: Invalid provider:model combinations show helpful error messages
- [ ] AC 4: All shorthand aliases work and show correct provider:model in help
- [ ] AC 5: Backward compatibility maintained - existing executables still work
- [ ] AC 6: Help system shows available providers and example usage
- [ ] AC 7: All tests pass with >95% coverage on new components

## Out of Scope

- ❌ Removing existing individual provider executables
- ❌ Implementing new LLM providers (use existing ones)
- ❌ Complex model discovery or recommendation features
- ❌ Interactive provider selection UI

## References

- [Code Review Task 39 - Priority 1 Requirements](../code-review/task.39/cr-user.md)
- [CLI Architecture Patterns](../../../../docs/architecture.md#cli-command-layer)
- [ATOM Pattern for Molecules](../../../../docs-dev/guides/atom-house-rules.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)