---
id: v.0.2.0+task.3 # REQUIRED - Unique ID. Always use bin/tnid to get the next sequential number for the current release. For format details, see docs-dev/guides/project-management.md#task-id-convention.
status: done # See [Project Management Guide](project-management.md) for all possible values
priority: medium
estimate: 6h
dependencies: [v.0.2.0+task.2]
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

Implement the `llm-lmstudio-query` command (R-LLM-3) that interfaces with LM Studio on `localhost:1234` using the server's REST protocol for offline inference. Default model should be "mistralai/devstral-small-2505" but configurable. This provides offline LLM capabilities as an alternative to cloud-based services.

## Scope of Work

- Create CLI command `llm-lmstudio-query` with Ruby implementation
- Integrate with LM Studio REST API on localhost:1234
- Support prompt input from string argument or file path
- Handle response formatting and error scenarios
- Implement connection testing and server availability checks

### Deliverables

#### Create

- lib/coding_agent_tools/cli/commands/lms/query.rb
- lib/coding_agent_tools/organisms/lm_studio_client.rb
- exe/llm-lmstudio-query (executable CLI script)
- spec/coding_agent_tools/cli/commands/lms/query_spec.rb
- spec/coding_agent_tools/organisms/lm_studio_client_spec.rb
- spec/integration/llm_lmstudio_query_integration_spec.rb (Aruba + VCR integration tests)

#### Modify

- coding_agent_tools.gemspec (add http client dependencies if needed)

#### Note on Zeitwerk

- lib/coding_agent_tools.rb modifications may not be needed due to Zeitwerk autoloading (ADR-002), as long as proper file naming conventions are followed

## Phases

1. Research & API Analysis
2. HTTP Client Implementation
3. CLI Command Implementation
4. Testing & Error Handling

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [x] Research LM Studio REST API documentation and endpoints (reference lms-query.fish)
  > TEST: API Documentation Review
  > Type: Pre-condition Check
  > Assert: Understand LM Studio REST protocol and response formats
  > Command: Manual testing with curl against localhost:1234
- [x] Analyze LM Studio server startup and configuration requirements
- [x] Design error handling for server unavailable scenarios
- [x] Plan consistent interface with Gemini client for future abstraction

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [x] Create LMStudioClient organism with HTTP REST integration (reusing HTTPRequestBuilder and APIResponseParser molecules)
  > TEST: Verify LMStudioClient Class
  > Type: Action Validation
  > Assert: LMStudioClient class exists with generate_text method
  > Command: ruby -e "require './lib/coding_agent_tools/organisms/lm_studio_client'; puts CodingAgentTools::Organisms::LMStudioClient.new.respond_to?(:generate_text)"
- [x] Implement server health check and connection validation
  > TEST: Verify Server Health Check
  > Type: Action Validation
  > Assert: Client can detect if LM Studio server is running
  > Command: ruby -e "require './lib/coding_agent_tools/organisms/lm_studio_client'; puts CodingAgentTools::Organisms::LMStudioClient.new.server_available?"
- [x] Implement CLI command class with argument parsing
- [x] Create executable script in exe/ that calls the CLI command class
  > TEST: Verify CLI Executable
  > Type: Action Validation
  > Assert: llm-lmstudio-query command is executable and shows help
  > Command: exe/llm-lmstudio-query --help
- [x] Add comprehensive unit tests including mock server scenarios
  > TEST: Verify Test Coverage
  > Type: Action Validation
  > Assert: All new classes have corresponding test files with mocks
  > Command: find spec -name "*lm_studio*" -o -name "*lms*"
- [x] Integrate APICredentials molecule for authentication (reuse from Task 2)
- [x] Create integration tests using Aruba + VCR pattern (following llm_gemini_query_integration_spec.rb)
  > TEST: Verify Integration Test Setup
  > Type: Action Validation
  > Assert: Integration test file exists and follows Aruba/VCR pattern
  > Command: find spec/integration -name "*llm_lmstudio*"
- [x] Configure VCR cassettes for LM Studio API interactions

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] AC 1: `llm-lmstudio-query` command accepts prompts as string arguments and file paths
- [x] AC 2: Command successfully interfaces with LM Studio REST API on localhost:1234
- [x] AC 3: Response output matches expected format from LM Studio
- [x] AC 4: Clear error messages when LM Studio server is not available
- [x] AC 5: All unit tests pass with >95% code coverage
- [x] AC 6: Integration test successfully calls live LM Studio instance

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
- Default model: mistralai/devstral-small-2505
- Architecture: Follow ATOM pattern - LMStudioClient organism composes APICredentials, HTTPRequestBuilder, and APIResponseParser molecules
- Reuse existing molecules: APICredentials (from Task 2), HTTPRequestBuilder, APIResponseParser
- CLI pattern: Follow same structure as lib/coding_agent_tools/cli/commands/llm/query.rb
- Integration testing: Use Aruba + VCR pattern similar to llm_gemini_query_integration_spec.rb
- Zeitwerk: Follow ADR-002 file naming conventions to avoid manual require statements

```
