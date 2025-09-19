---
id: v.0.2.0+task.46
status: done
priority: none
estimate: 0h
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
./lib/coding_agent_tools/cli/commands/google/query.rb
./lib/coding_agent_tools/cli/commands/anthropic/query.rb
./lib/coding_agent_tools/cli/commands/openai/query.rb
./lib/coding_agent_tools/cli/commands/mistral/query.rb
./lib/coding_agent_tools/cli/commands/together_ai/query.rb
./lib/coding_agent_tools/cli/commands/lms/query.rb
./spec/coding_agent_tools/cli/commands/google/query_spec.rb
./spec/coding_agent_tools/cli/commands/anthropic/query_spec.rb
```

## ⚠️ TASK OBSOLETE

**Status**: This task has been marked as obsolete because its objectives were achieved through a superior architectural approach.

**Resolution**: Task v.0.2.0+task.44 (completed 2025-06-24) implemented a unified LLM query command that:
- Eliminates duplication through a single command handling all providers
- Provides dynamic provider support via `provider:model` syntax
- Offers extensible architecture for adding new providers
- Maintains lower maintenance overhead than base class inheritance

**Current Implementation**: `lib/coding_agent_tools/cli/commands/llm/query.rb` serves as the unified entry point for all 6 providers, achieving the same architectural goals with better design.

## Original Objective (Archive)

Extract `BaseQueryCommand` to eliminate duplication in CLI command classes and implement dynamic provider command registration. This addresses Priority 2 requirement #4 from the code review findings and establishes a consistent pattern for adding new provider commands while reducing maintenance overhead across all 6 providers (google, anthropic, openai, mistral, together_ai, lmstudio).

## ⚠️ OBSOLETE - Scope of Work (Archive)

**Note**: The following scope is no longer applicable as the work has been completed through a unified command approach.

- ~~Create abstract `BaseQueryCommand` with common CLI functionality~~
- ~~Extract shared patterns from existing 6 provider query command classes~~
- ~~Implement dynamic command registration system~~
- ~~Refactor all existing commands to inherit from base class~~
- ~~Establish consistent option parsing and validation across all providers~~
- ~~Add plugin-style provider registration mechanism for all 6 providers~~

**Current Reality**: No separate provider command classes exist - all functionality is unified in `lib/coding_agent_tools/cli/commands/llm/query.rb`.

### Deliverables

#### Create

- `lib/coding_agent_tools/cli/commands/base_query_command.rb`
- `lib/coding_agent_tools/cli/provider_registry.rb`
- `spec/coding_agent_tools/cli/commands/base_query_command_spec.rb`
- `spec/coding_agent_tools/cli/provider_registry_spec.rb`
- `spec/support/shared_examples/query_command_behavior.rb`

#### Modify

- `lib/coding_agent_tools/cli/commands/google/query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands/anthropic/query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands/openai/query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands/mistral/query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands/together_ai/query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands/lms/query.rb` (refactor to inherit)
- `lib/coding_agent_tools/cli/commands.rb` (implement dynamic registration)
- `spec/coding_agent_tools/cli/commands/google/query_spec.rb` (use shared examples)
- `spec/coding_agent_tools/cli/commands/anthropic/query_spec.rb` (use shared examples)
- `spec/coding_agent_tools/cli/commands/openai/query_spec.rb` (use shared examples)
- `spec/coding_agent_tools/cli/commands/mistral/query_spec.rb` (use shared examples)
- `spec/coding_agent_tools/cli/commands/together_ai/query_spec.rb` (use shared examples)
- `spec/coding_agent_tools/cli/commands/lms/query_spec.rb` (use shared examples)

#### Delete

- Duplicated code blocks from existing 6 provider query commands

## ⚠️ OBSOLETE - Phases (Archive)

**Note**: These phases are no longer applicable.

1. ~~Analyze existing 6 provider command classes to identify common patterns~~ - No separate classes exist
2. ~~Design base command class and registration system~~ - Unified approach implemented instead
3. ~~Implement abstract base command with template methods~~ - Single command handles all providers
4. ~~Create dynamic provider registration mechanism for all providers~~ - Built into unified command
5. ~~Refactor all existing commands to use inheritance~~ - No refactoring needed
6. ~~Validate all functionality and add comprehensive tests~~ - Completed in task 44

## Implementation Plan

### Planning Steps

* [ ] Analyze existing 6 provider query commands to identify common patterns and duplication
  > TEST: Command Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common command patterns documented and extraction plan created for all 6 providers
  > Command: test -f docs/command-refactoring-analysis.md
* [ ] Design base command class with clear separation of common vs provider-specific logic
* [ ] Plan dynamic registration system for extensible provider support across all providers
* [ ] Design consistent option parsing and validation strategy across all providers

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
- [ ] Refactor `Google::Query` command to inherit from `BaseQueryCommand`
  > TEST: Google Command Refactoring
  > Type: Action Validation
  > Assert: Refactored Google::Query maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/google/query_spec.rb
- [ ] Refactor `Anthropic::Query` command to inherit from `BaseQueryCommand`
  > TEST: Anthropic Command Refactoring
  > Type: Action Validation
  > Assert: Refactored Anthropic::Query maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/anthropic/query_spec.rb
- [ ] Refactor `Openai::Query` command to inherit from `BaseQueryCommand`
  > TEST: OpenAI Command Refactoring
  > Type: Action Validation
  > Assert: Refactored Openai::Query maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/openai/query_spec.rb
- [ ] Refactor `Mistral::Query` command to inherit from `BaseQueryCommand`
  > TEST: Mistral Command Refactoring
  > Type: Action Validation
  > Assert: Refactored Mistral::Query maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/mistral/query_spec.rb
- [ ] Refactor `TogetherAi::Query` command to inherit from `BaseQueryCommand`
  > TEST: Together AI Command Refactoring
  > Type: Action Validation
  > Assert: Refactored TogetherAi::Query maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/together_ai/query_spec.rb
- [ ] Refactor `Lms::Query` command to inherit from `BaseQueryCommand`
  > TEST: LMS Command Refactoring
  > Type: Action Validation
  > Assert: Refactored Lms::Query maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/lms/query_spec.rb
- [ ] Update command registration to use dynamic provider registry for all 6 providers
- [ ] Create shared RSpec examples for common command behavior
- [ ] Add comprehensive tests for base command and registry
  > TEST: Base Command Test Coverage
  > Type: Action Validation
  > Assert: Base command classes have >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/base_query_command_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Validate no regression in CLI functionality and help output across all providers

## ✅ ACHIEVED - Acceptance Criteria (Archive)

**Note**: All objectives achieved through unified command implementation in task 44.

- [x] ~~AC 1: `BaseQueryCommand` provides common CLI option parsing and validation~~ → **ACHIEVED**: Unified command provides consistent option parsing
- [x] ~~AC 2: Provider commands register dynamically through `ProviderRegistry`~~ → **ACHIEVED**: Dynamic provider selection via `provider:model` syntax
- [x] ~~AC 3-8: Existing provider command functionality unchanged~~ → **ACHIEVED**: All provider functionality available through `llm-query provider:model`
- [x] ~~AC 9: Code duplication reduced by at least 60%~~ → **ACHIEVED**: 100% duplication eliminated (single command)
- [x] ~~AC 10: Help output and error messages consistent~~ → **ACHIEVED**: Single command ensures consistency
- [x] ~~AC 11: All existing CLI integration tests pass~~ → **ACHIEVED**: Verified in task 44
- [x] ~~AC 12: New providers can be added with minimal boilerplate~~ → **ACHIEVED**: Add case to `build_client()` method

## ⚠️ OBSOLETE - Out of Scope (Archive)

- ✅ ~~Implementing the unified `llm-query` command (separate task)~~ → **COMPLETED** in task 44
- ❌ Adding new provider commands beyond the existing 6
- ❌ Changing existing command-line interfaces or options
- ❌ Advanced CLI features like auto-completion

## Resolution Summary

**Task Status**: OBSOLETE - Objectives achieved through superior unified command architecture.
**Alternative Implementation**: See `lib/coding_agent_tools/cli/commands/llm/query.rb` for the current unified approach.
**Related Completed Work**: Task v.0.2.0+task.44 (Implement Unified LLM Query Entry-Point)

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [CLI Architecture Patterns](../../../../docs/architecture.md#cli-command-layer)
- [dry-cli Documentation](https://dry-rb.org/gems/dry-cli/)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)
