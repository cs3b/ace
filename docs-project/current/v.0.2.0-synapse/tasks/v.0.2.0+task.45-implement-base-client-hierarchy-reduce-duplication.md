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
./lib/coding_agent_tools/organisms/anthropic_client.rb
./lib/coding_agent_tools/organisms/google_client.rb
./lib/coding_agent_tools/organisms/lm_studio_client.rb
./lib/coding_agent_tools/organisms/mistral_client.rb
./lib/coding_agent_tools/organisms/openai_client.rb
./lib/coding_agent_tools/organisms/together_ai_client.rb
./spec/coding_agent_tools/organisms/anthropic_client_spec.rb
./spec/coding_agent_tools/organisms/google_client_spec.rb
```

## Objective

Introduce `BaseChatCompletionClient` and `BaseClient` hierarchy to eliminate code duplication across LLM provider clients. This addresses Priority 2 requirement #3 from the code review findings and establishes a foundation for easier addition of new providers while ensuring consistent behavior across all 6 clients (google, anthropic, openai, mistral, together_ai, lmstudio).

## Scope of Work

- Create abstract base client classes with shared functionality
- Extract common patterns from existing 6 provider clients (google, anthropic, openai, mistral, together_ai, lmstudio)
- Implement template method pattern for provider-specific operations
- Refactor all existing clients to inherit from base classes
- Establish consistent error handling and response processing across all providers
- Add comprehensive testing for inheritance hierarchy

### Deliverables

#### Create

- `lib/coding_agent_tools/organisms/base_client.rb`
- `lib/coding_agent_tools/organisms/base_chat_completion_client.rb`
- `spec/coding_agent_tools/organisms/base_client_spec.rb`
- `spec/coding_agent_tools/organisms/base_chat_completion_client_spec.rb`
- `spec/support/shared_examples/client_behavior.rb`

#### Modify

- `lib/coding_agent_tools/organisms/google_client.rb` (refactor to inherit)
- `lib/coding_agent_tools/organisms/anthropic_client.rb` (refactor to inherit)
- `lib/coding_agent_tools/organisms/openai_client.rb` (refactor to inherit)
- `lib/coding_agent_tools/organisms/mistral_client.rb` (refactor to inherit)
- `lib/coding_agent_tools/organisms/together_ai_client.rb` (refactor to inherit)
- `lib/coding_agent_tools/organisms/lm_studio_client.rb` (refactor to inherit)
- `spec/coding_agent_tools/organisms/google_client_spec.rb` (use shared examples)
- `spec/coding_agent_tools/organisms/anthropic_client_spec.rb` (use shared examples)
- `spec/coding_agent_tools/organisms/openai_client_spec.rb` (use shared examples)
- `spec/coding_agent_tools/organisms/mistral_client_spec.rb` (use shared examples)
- `spec/coding_agent_tools/organisms/together_ai_client_spec.rb` (use shared examples)
- `spec/coding_agent_tools/organisms/lm_studio_client_spec.rb` (use shared examples)
- `lib/coding_agent_tools.rb` (update requires)

#### Delete

- Duplicated code blocks from existing 6 provider clients

## Phases

1. Analyze existing 6 provider clients to identify common patterns
2. Design base class hierarchy and interfaces
3. Implement abstract base classes
4. Refactor all existing clients to use inheritance
5. Create shared test examples
6. Validate all functionality still works across all providers

## Implementation Plan

### Planning Steps

* [ ] Analyze existing 6 provider client implementations to identify common patterns
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common patterns documented and extraction plan created for all 6 providers
  > Command: test -f docs/client-refactoring-analysis.md
* [ ] Design inheritance hierarchy with clear separation of concerns across all providers
* [ ] Plan template method pattern for provider-specific operations
* [ ] Design consistent error handling strategy across all 6 providers

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
- [ ] Refactor `GoogleClient` to inherit from `BaseChatCompletionClient`
  > TEST: Google Client Refactoring
  > Type: Action Validation
  > Assert: Refactored GoogleClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/google_client_spec.rb
- [ ] Refactor `AnthropicClient` to inherit from `BaseChatCompletionClient`
  > TEST: Anthropic Client Refactoring
  > Type: Action Validation
  > Assert: Refactored AnthropicClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/anthropic_client_spec.rb
- [ ] Refactor `OpenaiClient` to inherit from `BaseChatCompletionClient`
  > TEST: OpenAI Client Refactoring
  > Type: Action Validation
  > Assert: Refactored OpenaiClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/openai_client_spec.rb
- [ ] Refactor `MistralClient` to inherit from `BaseChatCompletionClient`
  > TEST: Mistral Client Refactoring
  > Type: Action Validation
  > Assert: Refactored MistralClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/mistral_client_spec.rb
- [ ] Refactor `TogetherAiClient` to inherit from `BaseChatCompletionClient`
  > TEST: Together AI Client Refactoring
  > Type: Action Validation
  > Assert: Refactored TogetherAiClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/together_ai_client_spec.rb
- [ ] Refactor `LMStudioClient` to inherit from `BaseChatCompletionClient`
  > TEST: LM Studio Client Refactoring
  > Type: Action Validation
  > Assert: Refactored LMStudioClient maintains all existing functionality
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
- [ ] Create shared RSpec examples for common client behavior
- [ ] Update all 6 client specs to use shared examples
- [ ] Add comprehensive tests for base class functionality
  > TEST: Base Class Test Coverage
  > Type: Action Validation
  > Assert: Base classes have >95% test coverage
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/base_*_spec.rb --format json | jq '.summary.coverage_percent'
- [ ] Update library requires and autoloading
- [ ] Validate no regression in existing functionality across all providers

## Acceptance Criteria

- [ ] AC 1: `BaseClient` provides common initialization and utility methods
- [ ] AC 2: `BaseChatCompletionClient` handles chat completion workflow
- [ ] AC 3: Existing `GoogleClient` functionality unchanged after refactoring
- [ ] AC 4: Existing `AnthropicClient` functionality unchanged after refactoring
- [ ] AC 5: Existing `OpenaiClient` functionality unchanged after refactoring
- [ ] AC 6: Existing `MistralClient` functionality unchanged after refactoring
- [ ] AC 7: Existing `TogetherAiClient` functionality unchanged after refactoring
- [ ] AC 8: Existing `LMStudioClient` functionality unchanged after refactoring
- [ ] AC 9: Code duplication reduced by at least 50% across all 6 client classes
- [ ] AC 10: All existing tests pass without modification of assertions
- [ ] AC 11: New base classes have comprehensive test coverage
- [ ] AC 12: Shared test examples cover common client behaviors

## Out of Scope

- ❌ Adding new LLM providers beyond the existing 6
- ❌ Changing public APIs of existing clients
- ❌ Implementing advanced features like retry logic (separate task)
- ❌ Performance optimizations beyond basic refactoring

## References

- [Code Review Task 39 - Priority 2 Requirements](../code-review/task.39/cr-user.md)
- [ATOM Architecture - Organisms Layer](../../../../docs/architecture.md#organisms-business-logic-layer)
- [Ruby Inheritance Best Practices](../../../../docs-dev/guides/coding-standards.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)