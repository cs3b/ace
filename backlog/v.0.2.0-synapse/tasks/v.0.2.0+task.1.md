---
id: v.0.2.0+task.1 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
status: pending # See [Project Management Guide](project-management.md) for all possible values
priority: high
estimate: 8h
dependencies: []
---

# Implement llm-gemini-query Command

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Implement the `llm-gemini-query` command (R-LLM-1) that accepts a prompt string or file, calls Google Gemini (model v1.5 Pro), and returns the response as plain text or JSON. This is a foundational component for LLM integration capabilities in the Coding Agent Tools gem.

## Scope of Work

- Create CLI command `llm-gemini-query` with Ruby implementation
- Integrate Google Gemini v1.5 Pro API client
- Support prompt input from string argument or file path
- Handle response formatting (plain text or JSON)
- Implement error handling and retry logic for API failures

### Deliverables

#### Create

- lib/coding_agent_tools/commands/llm_gemini_query.rb
- lib/coding_agent_tools/llm/gemini_client.rb
- bin/llm-gemini-query (executable CLI script)
- spec/commands/llm_gemini_query_spec.rb
- spec/llm/gemini_client_spec.rb

#### Modify

- lib/coding_agent_tools.rb (require new modules)
- coding_agent_tools.gemspec (add google-cloud-ai dependency)

## Phases

1. Research & Design
2. API Client Implementation
3. CLI Command Implementation
4. Testing & Validation

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Research Google Gemini API v1.5 Pro integration patterns and authentication
  > TEST: API Documentation Review
  > Type: Pre-condition Check
  > Assert: Understand API endpoints, authentication, and response formats
  > Command: Manual review of Google AI documentation
- [ ] Analyze existing CLI command patterns in the codebase
- [ ] Design command interface and parameter structure
- [ ] Plan error handling strategy for API rate limits and network issues

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Add google-cloud-ai gem dependency to gemspec
  > TEST: Verify Dependency Added
  > Type: Action Validation
  > Assert: google-cloud-ai gem is listed in gemspec dependencies
  > Command: grep "google-cloud-ai" coding_agent_tools.gemspec
- [ ] Create GeminiClient class with API integration
  > TEST: Verify GeminiClient Class
  > Type: Action Validation
  > Assert: GeminiClient class exists with generate_text method
  > Command: ruby -e "require './lib/coding_agent_tools/llm/gemini_client'; puts CodingAgentTools::LLM::GeminiClient.new.respond_to?(:generate_text)"
- [ ] Implement CLI command class with argument parsing
- [ ] Create executable bin script that calls the command class
  > TEST: Verify CLI Executable
  > Type: Action Validation
  > Assert: llm-gemini-query command is executable and shows help
  > Command: bin/llm-gemini-query --help
- [ ] Add comprehensive unit tests for all components
  > TEST: Verify Test Coverage
  > Type: Action Validation
  > Assert: All new classes have corresponding test files
  > Command: find spec -name "*gemini*" -o -name "*llm*"
- [ ] Implement integration test with live API (using test key)

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: `llm-gemini-query` command accepts prompts as string arguments and file paths
- [ ] AC 2: Command successfully integrates with Google Gemini v1.5 Pro API
- [ ] AC 3: Response output supports both plain text and JSON formats
- [ ] AC 4: All unit tests pass with >95% code coverage
- [ ] AC 5: Integration test successfully calls live Gemini API
- [ ] AC 6: Error handling gracefully manages API failures and invalid inputs

## Out of Scope

- ❌ API key configuration (handled in R-LLM-2)
- ❌ Model selection override (handled in R-LLM-4)
- ❌ LM Studio integration (handled in R-LLM-3)
- ❌ Streaming responses (future enhancement)
- ❌ Custom system prompts or conversation history

## References

```
