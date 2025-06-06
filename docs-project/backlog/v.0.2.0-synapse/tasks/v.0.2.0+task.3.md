---
id: v.0.2.0+task.3 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
status: pending # See [Project Management Guide](project-management.md) for all possible values
priority: medium
estimate: 6h
dependencies: []
---

# Implement lms-studio-query Command

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

Implement the `lms-studio-query` command (R-LLM-3) that interfaces with LM Studio on `localhost:1234` using the server's REST protocol for offline inference. Default model should be "mistral-small-24b-instruct-2501@8bit" but configurable. This provides offline LLM capabilities as an alternative to cloud-based services.

## Scope of Work

- Create CLI command `lms-studio-query` with Ruby implementation
- Integrate with LM Studio REST API on localhost:1234
- Support prompt input from string argument or file path
- Handle response formatting and error scenarios
- Implement connection testing and server availability checks

### Deliverables

#### Create

- lib/coding_agent_tools/commands/lms_studio_query.rb
- lib/coding_agent_tools/llm/lm_studio_client.rb
- bin/lms-studio-query (executable CLI script)
- spec/commands/lms_studio_query_spec.rb
- spec/llm/lm_studio_client_spec.rb

#### Modify

- lib/coding_agent_tools.rb (require new modules)
- coding_agent_tools.gemspec (add http client dependencies if needed)

## Phases

1. Research & API Analysis
2. HTTP Client Implementation
3. CLI Command Implementation
4. Testing & Error Handling

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [ ] Research LM Studio REST API documentation and endpoints (reference lms-query.fish)
  > TEST: API Documentation Review
  > Type: Pre-condition Check
  > Assert: Understand LM Studio REST protocol and response formats
  > Command: Manual testing with curl against localhost:1234
- [ ] Analyze LM Studio server startup and configuration requirements
- [ ] Design error handling for server unavailable scenarios
- [ ] Plan consistent interface with Gemini client for future abstraction

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [ ] Create LMStudioClient class with HTTP REST integration (based on lms-query.fish)
  > TEST: Verify LMStudioClient Class
  > Type: Action Validation
  > Assert: LMStudioClient class exists with generate_text method
  > Command: ruby -e "require './lib/coding_agent_tools/llm/lm_studio_client'; puts CodingAgentTools::LLM::LMStudioClient.new.respond_to?(:generate_text)"
- [ ] Implement server health check and connection validation
  > TEST: Verify Server Health Check
  > Type: Action Validation
  > Assert: Client can detect if LM Studio server is running
  > Command: ruby -e "require './lib/coding_agent_tools/llm/lm_studio_client'; puts CodingAgentTools::LLM::LMStudioClient.new.server_available?"
- [ ] Implement CLI command class with argument parsing
- [ ] Create executable bin script that calls the command class
  > TEST: Verify CLI Executable
  > Type: Action Validation
  > Assert: lms-studio-query command is executable and shows help
  > Command: bin/lms-studio-query --help
- [ ] Add comprehensive unit tests including mock server scenarios
  > TEST: Verify Test Coverage
  > Type: Action Validation
  > Assert: All new classes have corresponding test files with mocks
  > Command: find spec -name "*lm_studio*" -o -name "*lms*"
- [ ] Implement integration test with actual LM Studio instance

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [ ] AC 1: `lms-studio-query` command accepts prompts as string arguments and file paths
- [ ] AC 2: Command successfully interfaces with LM Studio REST API on localhost:1234
- [ ] AC 3: Response output matches expected format from LM Studio
- [ ] AC 4: Clear error messages when LM Studio server is not available
- [ ] AC 5: All unit tests pass with >95% code coverage
- [ ] AC 6: Integration test successfully calls live LM Studio instance

## Out of Scope

- ❌ LM Studio server installation or configuration
- ❌ Model selection override (handled in R-LLM-4)
- ❌ Custom LM Studio endpoint configuration
- ❌ Streaming responses (future enhancement)
- ❌ LM Studio server startup automation
- ❌ Multiple model instances or switching

## References

- Fish implementation: docs-project/backlog/v.0.2.0-synapse/docs/lms-query.fish
- LM Studio API endpoint: http://localhost:1234/v1/chat/completions
- Default model: mistral-small-24b-instruct-2501@8bit

```
