---
id: v.0.2.0+task.45
status: pending
priority: high
estimate: 10h
dependencies: [v.0.2.0+task.43]
---

# Implement Base Client Hierarchy to Reduce Duplication

## 0. Directory Audit ✅

_Command run:_

```bash
find . -path "*/organisms/*client*" -name "*.rb" | head -10
```

_Result excerpt:_

```
./lib/coding_agent_tools/organisms/gemini_client.rb
./lib/coding_agent_tools/organisms/lm_studio_client.rb
./spec/coding_agent_tools/organisms/gemini_client_spec.rb
./spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
```

## Objective

Introduce `BaseChatCompletionClient` and `BaseClient` hierarchy to eliminate code duplication across LLM provider clients. This addresses Priority 2 requirement #3 from the code review findings and establishes a foundation for easier addition of new providers while ensuring consistent behavior across all clients.

## Scope of Work

- Create abstract base client classes with shared functionality
- Extract common patterns from existing Gemini and LM Studio clients
- Implement template method pattern for provider-specific operations
- Refactor existing clients to inherit from base classes
- Establish consistent error handling and response processing
- Add comprehensive testing for inheritance hierarchy

### Deliverables

#### Create

- `lib/coding_agent_tools/organisms/base_client.rb`
- `lib/coding_agent_tools/organisms/base_chat_completion_client.rb`
- `spec/coding_agent_tools/organisms/base_client_spec.rb`
- `spec/coding_agent_tools/organisms/base_chat_completion_client_spec.rb`
- `spec/support/shared_examples/client_behavior.rb`

#### Modify

- `lib/coding_agent_tools/organisms/gemini_client.rb` (refactor to inherit)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (refactor to inherit)
- `spec/coding_agent_tools/organisms/gemini_client_spec.rb` (use shared examples)
- `spec/coding_agent_tools/organisms/lm_studio_client_spec.rb` (use shared examples)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- Duplicated code blocks from existing clients

## Phases

1. Analyze existing clients to identify common patterns
2. Design base class hierarchy and interfaces
3. Implement abstract base classes
4. Refactor existing clients to use inheritance
5. Create shared test examples
6. Validate all functionality still works

## Implementation Plan

### Planning Steps

* [ ] Analyze existing client implementations to identify common patterns
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common patterns documented and extraction plan created
  > Command: test -f docs/client-refactoring-analysis.md
* [ ] Design inheritance hierarchy with clear separation of concerns
* [ ] Plan template method pattern for provider-specific operations
* [ ] Design consistent error handling strategy across all clients

### Execution Steps

- [ ] Create `BaseClient` with common initialization and utility methods
  > TEST: Base Client Creation
  > Type: Action Validation
  > Assert: BaseClient compiles and provides expected interface
  > Command: ruby -c lib/coding_agent_tools/organisms/base_client.rb
- [ ] Create `BaseChatCompletionClient` inheriting from `BaseClient`
- [ ] Extract common HTTP request/response handling logic
- [ ] Implement template methods for provider-specific operations
- [ ] Add consistent error handling and logging across base classes
- [ ] Refactor `GeminiClient` to inherit from `BaseChatCompletionClient`
  > TEST: Gemini Client Refactoring
  > Type: Action Validation
  > Assert: Refactored GeminiClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/gemini_client_spec.rb
- [ ] Refactor `LMStudioClient` to inherit from `BaseChatCompletionClient`
  > TEST: LM Studio Client Refactoring
  > Type: Action Validation
  > Assert: Refactored LMStudioClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
- [ ] Create shared RSpec examples for common client behavior
- [ ] Update client specs to use shared examples
- [ ] Add comprehensive tests for base class functionality
  > TEST: Base Class Test Coverage
  > Type: Action Validation
  > Assert: Base classes have >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/base_*_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Update library requires and autoloading
- [ ] Validate no regression in existing functionality

## Acceptance Criteria

- [ ] AC 1: `BaseClient` provides common initialization and utility methods
- [ ] AC 2: `BaseChatCompletionClient` handles chat completion workflow
- [ ] AC 3: Existing `GeminiClient` functionality unchanged after refactoring
- [ ] AC 4: Existing `LMStudioClient` functionality unchanged after refactoring
- [ ] AC 5: Code duplication reduced by at least 50% in client classes
- [ ] AC 6: All existing tests pass without modification of assertions
- [ ] AC 7: New base classes have comprehensive test coverage
- [ ] AC 8: Shared test examples cover common client behaviors

## Out of Scope

- ❌ Adding new LLM providers (use existing clients only)
- ❌ Changing public APIs of existing clients
- ❌ Implementing advanced features like retry logic (separate task)
- ❌ Performance optimizations beyond basic refactoring

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Organisms Layer](../../../../docs/architecture.md#organisms-business-logic-layer)
- [Ruby Inheritance Best Practices](../../../../docs-dev/guides/coding-standards.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)