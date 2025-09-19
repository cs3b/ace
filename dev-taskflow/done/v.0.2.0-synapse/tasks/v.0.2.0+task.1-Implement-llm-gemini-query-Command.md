---
id: v.0.2.0+task.1
status: done
priority: high
estimate: 8h
dependencies: []
---

# Implement llm-gemini-query Command

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 lib
```

_Result excerpt:_

```
lib
├── coding_agent_tools
│   ├── atoms
│   ├── cli.rb
│   ├── ecosystems
│   ├── error.rb
│   ├── models
│   ├── molecules
│   ├── organisms
│   └── version.rb
└── coding_agent_tools.rb

7 directories, 4 files
```

## Objective

Implement the `llm-gemini-query` command (R-LLM-1) that accepts a prompt string or file, calls Google Gemini (model gemini-2.0-flash-lite), and returns the response with explicit output formatting. This is a foundational component for LLM integration capabilities in the Coding Agent Tools gem.

## Scope of Work

- Create CLI command `llm-gemini-query` with Ruby implementation following ATOM architecture
- Integrate Google Gemini API client (gemini-2.0-flash-lite model)
- Support prompt input from string argument or file path
- Handle response formatting with explicit --format flag (text or json)
- Implement error handling with optional --debug flag
- Use faraday for HTTP client implementation
- Load API key from .env with singleton configuration override capability

### Deliverables

#### Create

**ATOM Architecture Files:**
- lib/coding_agent_tools/atoms/http_client.rb
- lib/coding_agent_tools/atoms/json_formatter.rb
- lib/coding_agent_tools/atoms/env_reader.rb
- lib/coding_agent_tools/molecules/api_credentials.rb
- lib/coding_agent_tools/molecules/http_request_builder.rb
- lib/coding_agent_tools/molecules/api_response_parser.rb
- lib/coding_agent_tools/organisms/gemini_client.rb
- lib/coding_agent_tools/organisms/prompt_processor.rb
- lib/coding_agent_tools/cli/commands/llm/query.rb
- .ace/tools/exe/llm-gemini-query (executable CLI script)

**Test Files:**
- spec/coding_agent_tools/atoms/http_client_spec.rb
- spec/coding_agent_tools/atoms/json_formatter_spec.rb
- spec/coding_agent_tools/atoms/env_reader_spec.rb
- spec/coding_agent_tools/molecules/api_credentials_spec.rb
- spec/coding_agent_tools/molecules/http_request_builder_spec.rb
- spec/coding_agent_tools/molecules/api_response_parser_spec.rb
- spec/coding_agent_tools/organisms/gemini_client_spec.rb
- spec/coding_agent_tools/organisms/prompt_processor_spec.rb
- spec/coding_agent_tools/cli/commands/llm/query_spec.rb
- spec/integration/llm_gemini_query_integration_spec.rb

#### Modify

- lib/coding_agent_tools.rb (require new modules)
- lib/coding_agent_tools/cli.rb (register LLM commands)
- coding_agent_tools.gemspec (add faraday dependency)

## Phases

1. Research & Design
2. API Client Implementation
3. CLI Command Implementation
4. Testing & Validation

## Implementation Plan

*This section details the specific steps required to complete the task. It is divided into two subsections to distinguish between planning/analysis activities and actual implementation work._

### Planning Steps

*Optional but recommended for complex tasks. Use asterisk markers (`* [ ]`) for research, analysis, and design activities that help clarify the approach before implementation begins._

- [x] Research Google Gemini API gemini-2.0-flash-lite integration patterns and authentication
  > TEST: API Documentation Review
  > Type: Pre-condition Check
  > Assert: Understand API endpoints, authentication, and response formats for gemini-2.0-flash-lite
  > Command: Manual review of Google AI documentation and fish script reference
- [x] Analyze existing CLI command patterns and ATOM architecture in codebase
  > TEST: Architecture Compliance Check
  > Type: Pre-condition Check
  > Assert: Understand how atoms, molecules, organisms interact in current structure
  > Command: Review lib/coding_agent_tools structure and existing CLI patterns
- [x] Design CLI interface with --format and --debug flags
  > TEST: CLI Interface Design
  > Type: Design Validation
  > Assert: Command interface supports text/json output and debug mode
  > Command: Mock CLI usage scenarios: `llm-gemini-query "prompt" --format json --debug`
- [x] Plan ATOM component dependencies and data flow
  > TEST: Component Architecture Design
  > Type: Design Validation
  > Assert: Clear separation of concerns between atoms, molecules, organisms
  > Command: Document component interaction diagram
- [x] Plan error handling strategy with debug flag integration
  > TEST: Error Handling Strategy
  > Type: Design Validation
  > Assert: Graceful error handling with verbose debug option
  > Command: Document error scenarios and debug output format

### Execution Steps

*Required section. Use hyphen markers (`- [ ]`) for concrete implementation actions that modify code, create files, or change the system state._

- [x] Add faraday dependency to gemspec
  > TEST: Verify Faraday Dependency
  > Type: Action Validation
  > Assert: Faraday gem is available and can be required
  > Command: ruby -e "require 'faraday'; puts 'Faraday available'"
- [x] Implement Atoms layer (http_client, json_formatter, env_reader)
  > TEST: Verify Atoms Implementation
  > Type: Action Validation
  > Assert: All atom classes are loadable and functional
  > Command: ruby -e "require './lib/coding_agent_tools/atoms/http_client'; puts 'Atoms loaded'"
- [x] Implement Molecules layer (api_credentials, http_request_builder, api_response_parser)
  > TEST: Verify Molecules Implementation
  > Type: Action Validation
  > Assert: All molecule classes integrate atoms correctly
  > Command: ruby -e "require './lib/coding_agent_tools/molecules/api_credentials'; puts 'Molecules loaded'"
- [x] Implement Organisms layer (gemini_client, prompt_processor)
  > TEST: Verify Organisms Implementation
  > Type: Action Validation
  > Assert: GeminiClient and PromptProcessor classes work with molecules
  > Command: ruby -e "require './lib/coding_agent_tools/organisms/gemini_client'; puts CodingAgentTools::Organisms::GeminiClient.new.respond_to?(:generate_text)"
- [x] Implement CLI command with --format and --debug flags
  > TEST: Verify CLI Command Implementation
  > Type: Action Validation
  > Assert: CLI command class handles arguments correctly
  > Command: ruby -e "require './lib/coding_agent_tools/cli/commands/llm/query'; puts 'CLI command loaded'"
- [x] Create executable script in .ace/tools/exe/ directory
  > TEST: Verify CLI Executable
  > Type: Action Validation
  > Assert: llm-gemini-query command is executable and shows help
  > Command: .ace/tools/exe/llm-gemini-query --help
- [x] Register LLM commands in CLI registry
  > TEST: Verify Command Registration
  > Type: Action Validation
  > Assert: LLM commands are registered and accessible
  > Command: coding_agent_tools llm --help
- [x] Implement comprehensive unit tests for all ATOM components
  > TEST: Verify Test Coverage
  > Type: Action Validation
  > Assert: All new classes have corresponding test files with >95% coverage
  > Command: find spec -path "*/atoms/*" -o -path "*/molecules/*" -o -path "*/organisms/*" -o -path "*/cli/commands/llm/*"
- [x] Implement integration test with live API (using test key)
  > TEST: Verify Integration Test
  > Type: Action Validation
  > Assert: End-to-end integration test passes with live API
  > Command: rspec spec/integration/llm_gemini_query_integration_spec.rb

## Acceptance Criteria

*Define the conditions that signify the task is complete. These can be manual checks or high-level statements whose details are verified by embedded tests in the Implementation Plan._

- [x] AC 1: `llm-gemini-query` command accepts prompts as string arguments and file paths
- [x] AC 2: Command successfully integrates with Google Gemini API using gemini-2.0-flash-lite model
- [x] AC 3: Response output supports explicit --format flag with text and json options
- [x] AC 4: Command implements --debug flag for verbose error output
- [x] AC 5: API credentials are loaded from .env with singleton configuration override capability
- [x] AC 6: Implementation follows ATOM architecture with proper separation of concerns
- [x] AC 7: All unit tests pass with >95% code coverage across atoms, molecules, organisms
- [x] AC 8: Integration test successfully calls live Gemini API
- [x] AC 9: Error handling gracefully manages API failures and invalid inputs with appropriate debug information
- [x] AC 10: Faraday HTTP client is properly integrated for API requests

## Out of Scope

- ❌ Advanced API key configuration beyond .env and singleton override (handled in R-LLM-2)
- ❌ Model selection override beyond gemini-2.0-flash-lite default (handled in R-LLM-4)
- ❌ LM Studio integration (handled in R-LLM-3)
- ❌ Streaming responses (future enhancement)
- ❌ Custom system prompts or conversation history (future enhancement)
- ❌ Response caching or rate limiting (future enhancement)
- ❌ Multiple output formats beyond text/json (future enhancement)

## References

- Fish implementation: .ace/taskflow/current/v.0.2.0-synapse/docs/gemini-query.fish
- Gemini API documentation: https://ai.google.dev/api/rest
- Default model: gemini-2.0-flash-lite
- ATOM Architecture: .ace/taskflow/architecture.md
- Faraday HTTP client: https://lostisland.github.io/faraday/
- Dry-CLI framework: https://dry-rb.org/gems/dry-cli/

```
