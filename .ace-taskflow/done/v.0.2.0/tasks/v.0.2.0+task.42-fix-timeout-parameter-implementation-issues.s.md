---
id: v.0.2.0+task.42
status: done
priority: high
estimate: 1d
dependencies: [v.0.2.0+task.41]
---

# Fix Timeout Parameter Implementation Issues

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 exe/commands/ lib/coding_agent_tools/cli/commands/ spec/coding_agent_tools/cli/commands/ | sed 's/^/    /'
```

_Result excerpt:_

```
exe/commands/
├── anthropic
│   └── query.rb
├── llm
│   ├── models.rb
│   └── query.rb
├── lms
│   └── query.rb
├── mistral
│   └── query.rb
├── openai
│   └── query.rb
└── together_ai
    └── query.rb
lib/coding_agent_tools/cli/commands/
├── anthropic
│   └── query.rb
├── llm
│   ├── models.rb
│   └── query.rb
├── lms
│   └── query.rb
├── mistral
│   └── query.rb
├── openai
│   └── query.rb
└── together_ai
    └── query.rb
spec/coding_agent_tools/cli/commands/
├── anthropic
│   └── query_spec.rb
├── llm
│   ├── models_spec.rb
│   └── query_spec.rb
├── lms
│   └── query_spec.rb
├── mistral
│   └── query_spec.rb
├── openai
│   └── query_spec.rb
└── together_ai
    └── query_spec.rb
```

## Objective

Fix multiple issues identified in the timeout parameter implementation from task 41, including duplicate command files that violate ATOM architecture, incomplete unit tests, and insufficient test coverage. The current implementation has structural problems where duplicate files exist in `exe/commands/` that mirror `lib/coding_agent_tools/cli/commands/`, and several timeout parameter tests are marked as incomplete despite the task being marked as done.

## Scope of Work

This task addresses three critical areas:
- Remove duplicate command files from `exe/commands/` that violate project structure
- Complete missing timeout parameter unit tests for all LLM providers
- Enhance test coverage to ensure timeout is properly applied at HTTP request level
- Update task 41 status to reflect actual completion state

### Deliverables

#### Delete

- exe/commands/anthropic/query.rb
- exe/commands/llm/query.rb
- exe/commands/llm/models.rb
- exe/commands/lms/query.rb
- exe/commands/mistral/query.rb
- exe/commands/openai/query.rb
- exe/commands/together_ai/query.rb

#### Modify

- spec/coding_agent_tools/cli/commands/llm/query_spec.rb (add missing Gemini timeout tests)
- spec/coding_agent_tools/cli/commands/lms/query_spec.rb (add missing LMS timeout tests)
- spec/coding_agent_tools/cli/commands/mistral/query_spec.rb (add missing Mistral timeout tests)
- spec/coding_agent_tools/cli/commands/openai/query_spec.rb (add missing OpenAI timeout tests)
- spec/coding_agent_tools/cli/commands/together_ai/query_spec.rb (add missing Together AI timeout tests)
- docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.41-add-timeout-parameter-to-llm-queries.md (update status and completion)

## Phases

1. **Cleanup Phase**: Remove duplicate command files that violate ATOM architecture
2. **Testing Phase**: Complete missing timeout parameter unit tests for all providers
3. **Validation Phase**: Enhance test coverage and update task 41 status

## Implementation Plan

### Planning Steps

* [ ] Review current timeout parameter implementation to understand the expected behavior
  > TEST: Implementation Understanding Check
  > Type: Pre-condition Check
  > Assert: Current timeout implementation patterns are documented and understood
  > Command: grep -r "timeout" lib/coding_agent_tools/cli/commands/ --include="*.rb"
* [ ] Analyze existing test patterns to ensure consistency across all provider tests
* [ ] Review task 41 checklist items to identify exactly which tests need completion

### Execution Steps

#### Phase 1: Cleanup Duplicate Command Files
- [x] Remove all duplicate command files from exe/commands/ directory
  > TEST: Duplicate Files Removed
  > Type: Action Validation
  > Assert: No duplicate command files exist in exe/commands/
  > Command: test ! -d exe/commands/
- [x] Verify exe/ directory only contains executable scripts, not Ruby class definitions
  > TEST: Exe Directory Structure Validation
  > Type: Action Validation
  > Assert: exe/ directory contains only executable scripts
  > Command: find exe/ -name "*.rb" -type f | wc -l | grep -q "^0$"

#### Phase 2: Complete Missing Timeout Tests
- [x] Add comprehensive timeout parameter tests to spec/coding_agent_tools/cli/commands/llm/query_spec.rb for Gemini
  > TEST: Gemini Timeout Tests Complete
  > Type: Action Validation
  > Assert: Gemini timeout tests verify HTTP request timeout configuration
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/llm/query_spec.rb --example "timeout"
- [x] Add comprehensive timeout parameter tests to spec/coding_agent_tools/cli/commands/lms/query_spec.rb for LM Studio
  > TEST: LMS Timeout Tests Complete
  > Type: Action Validation
  > Assert: LMS timeout tests verify HTTP request timeout configuration
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/lms/query_spec.rb --example "timeout"
- [x] Add comprehensive timeout parameter tests to spec/coding_agent_tools/cli/commands/mistral/query_spec.rb for Mistral
  > TEST: Mistral Timeout Tests Complete
  > Type: Action Validation
  > Assert: Mistral timeout tests verify HTTP request timeout configuration
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/mistral/query_spec.rb --example "timeout"
- [x] Add comprehensive timeout parameter tests to spec/coding_agent_tools/cli/commands/openai/query_spec.rb for OpenAI
  > TEST: OpenAI Timeout Tests Complete
  > Type: Action Validation
  > Assert: OpenAI timeout tests verify HTTP request timeout configuration
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/openai/query_spec.rb --example "timeout"
- [x] Add comprehensive timeout parameter tests to spec/coding_agent_tools/cli/commands/together_ai/query_spec.rb for Together AI
  > TEST: Together AI Timeout Tests Complete
  > Type: Action Validation
  > Assert: Together AI timeout tests verify HTTP request timeout configuration
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/together_ai/query_spec.rb --example "timeout"

#### Phase 3: Validation and Documentation
- [x] Run all timeout-related tests to ensure comprehensive coverage
  > TEST: All Timeout Tests Pass
  > Type: Action Validation
  > Assert: All timeout parameter tests pass across all providers
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/ --example "timeout"
- [x] Update task 41 status based on actual completion state
- [x] Mark incomplete checklist items in task 41 as complete if tests are now implemented

## Acceptance Criteria

- [x] All duplicate command files removed from exe/commands/ directory
- [x] exe/ directory contains only executable scripts, no Ruby class definitions
- [x] All timeout parameter unit tests implemented for Gemini, LMS, Mistral, OpenAI, and Together AI
- [x] All timeout tests verify that timeout is applied at HTTP request level, not just passed to constructor
- [x] All timeout-related tests pass successfully
- [x] Task 41 status and checklist items updated to reflect actual completion state
- [x] Project structure adheres to ATOM architecture pattern

## Out of Scope

- ❌ Modifying the actual timeout implementation logic (only fixing tests and structure)
- ❌ Adding timeout parameter to other commands not covered in task 41
- ❌ Integration tests (only unit tests are in scope)
- ❌ Modifying core HTTP client implementation

## References

- [Write Actionable Task Guide](docs-dev/guides/task-definition.g.md)
- [Embedding Tests in AI Agent Workflows Guide](docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)
- [v.0.2.0+task.41-add-timeout-parameter-to-llm-queries.md](docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.41-add-timeout-parameter-to-llm-queries.md)
- **Risk**: Removing duplicate files might break existing workflows if they were being used. **Mitigation**: Verify that exe/ scripts properly invoke lib/ implementations.
- **Risk**: Test implementations might not accurately reflect actual timeout behavior. **Mitigation**: Use WebMock or VCR to verify HTTP request configurations.