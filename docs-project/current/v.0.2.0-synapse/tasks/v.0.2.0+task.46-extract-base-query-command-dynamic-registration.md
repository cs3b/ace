---
id: v.0.2.0+task.46
status: pending
priority: high
estimate: 8h
dependencies: [v.0.2.0+task.45]
---

# Extract Base Query Command and Implement Dynamic Registration

## 0. Directory Audit ✅

_Command run:_

```bash
find . -path "*/cli/commands/*" -name "*query*" -type f | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/cli/commands/llm/gemini_query.rb
./lib/coding_agent_tools/cli/commands/lms/studio_query.rb
./spec/coding_agent_tools/cli/commands/llm/gemini_query_spec.rb
./spec/coding_agent_tools/cli/commands/lms/studio_query_spec.rb
```

## Objective

Extract `BaseQueryCommand` to eliminate duplication in CLI command classes and implement dynamic provider command registration. This addresses Priority 2 requirement #4 from the code review findings and establishes a consistent pattern for adding new provider commands while reducing maintenance overhead.

## Scope of Work

- Create abstract `BaseQueryCommand` with common CLI functionality
- Extract shared patterns from existing query command classes
- Implement dynamic command registration system
- Refactor existing commands to inherit from base class
- Establish consistent option parsing and validation
- Add plugin-style provider registration mechanism

### Deliverables

#### Create

- `lib/coding_agent_tools/cli/commands/base_query_command.rb`
- `lib/coding_agent_tools/cli/provider_registry.rb`
- `spec/coding_agent_tools/cli/commands/base_query_command_spec.rb`
- `spec/coding_agent_tools/cli/provider_registry_spec.rb`
- `spec/support/shared_examples/query_command_behavior.rb`

#### Modify

- `lib/coding_agent_tools/cli/commands/llm/gemini_query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands/lms/studio_query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands.rb` (implement dynamic registration)
- `spec/coding_agent_tools/cli/commands/llm/gemini_query_spec.rb` (use shared examples)
- `spec/coding_agent_tools/cli/commands/lms/studio_query_spec.rb` (use shared examples)

#### Delete

- Duplicated code blocks from existing query commands

## Phases

1. Analyze existing command classes to identify common patterns
2. Design base command class and registration system
3. Implement abstract base command with template methods
4. Create dynamic provider registration mechanism
5. Refactor existing commands to use inheritance
6. Validate all functionality and add comprehensive tests

## Implementation Plan

### Planning Steps

* [ ] Analyze existing query commands to identify common patterns and duplication
  > TEST: Command Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common command patterns documented and extraction plan created
  > Command: test -f docs/command-refactoring-analysis.md
* [ ] Design base command class with clear separation of common vs provider-specific logic
* [ ] Plan dynamic registration system for extensible provider support
* [ ] Design consistent option parsing and validation strategy

### Execution Steps

- [ ] Create `BaseQueryCommand` with common CLI infrastructure
  > TEST: Base Command Creation
  > Type: Action Validation
  > Assert: BaseQueryCommand compiles and provides expected interface
  > Command: ruby -c lib/coding_agent_tools/cli/commands/base_query_command.rb
- [ ] Extract common option definitions (prompt, output, verbose, etc.)
- [ ] Implement template methods for provider-specific operations
- [ ] Create `ProviderRegistry` for dynamic command registration
  > TEST: Provider Registry Functionality
  > Type: Action Validation
  > Assert: Registry can register and retrieve provider commands
  > Command: bundle exec rspec spec/coding_agent_tools/cli/provider_registry_spec.rb
- [ ] Add consistent error handling and validation across base command
- [ ] Refactor `GeminiQuery` command to inherit from `BaseQueryCommand`
  > TEST: Gemini Command Refactoring
  > Type: Action Validation
  > Assert: Refactored GeminiQuery maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/gemini_query_spec.rb
- [ ] Refactor `StudioQuery` command to inherit from `BaseQueryCommand`
  > TEST: Studio Command Refactoring
  > Type: Action Validation
  > Assert: Refactored StudioQuery maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/lms/studio_query_spec.rb
- [ ] Update command registration to use dynamic provider registry
- [ ] Create shared RSpec examples for common command behavior
- [ ] Add comprehensive tests for base command and registry
  > TEST: Base Command Test Coverage
  > Type: Action Validation
  > Assert: Base command classes have >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/base_query_command_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Validate no regression in CLI functionality and help output

## Acceptance Criteria

- [ ] AC 1: `BaseQueryCommand` provides common CLI option parsing and validation
- [ ] AC 2: Provider commands register dynamically through `ProviderRegistry`
- [ ] AC 3: Existing `llm-gemini-query` command functionality unchanged
- [ ] AC 4: Existing `lms-studio-query` command functionality unchanged
- [ ] AC 5: Code duplication reduced by at least 60% in command classes
- [ ] AC 6: Help output and error messages remain consistent
- [ ] AC 7: All existing CLI integration tests pass
- [ ] AC 8: New providers can be added with minimal boilerplate

## Out of Scope

- ❌ Implementing the unified `llm-query` command (separate task)
- ❌ Adding new provider commands (use existing ones only)
- ❌ Changing existing command-line interfaces or options
- ❌ Advanced CLI features like auto-completion

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [CLI Architecture Patterns](../../../../docs/architecture.md#cli-command-layer)
- [dry-cli Documentation](https://dry-rb.org/gems/dry-cli/)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)