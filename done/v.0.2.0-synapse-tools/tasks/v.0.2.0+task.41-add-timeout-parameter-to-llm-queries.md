---
id: v.0.2.0+task.41
status: done
priority: high
estimate: 3d
dependencies: []
---

# Add `--timeout` Parameter to `llm-<provider>-query` Commands

## Objective / Problem

The current `llm-<provider>-query` commands lack a `--timeout` parameter, which is essential for controlling the maximum duration of HTTP requests to LLM providers. Without this, long-running or stalled requests can block the system indefinitely, leading to poor user experience and resource exhaustion. The objective is to introduce a `--timeout` parameter to allow users to specify a maximum wait time for these queries, ensuring robustness and responsiveness.

## Directory Audit (0)

```bash
tree -L 2 exe/llm* | sed 's/^/    /'
tree -L 4 lib/coding_agent_tools/cli/commands/ | sed 's/^/    /'

exe
├── llm-anthropic-query
├── llm-gemini-query
├── llm-lmstudio-query
├── llm-mistral-query
├── llm-openai-query
└── llm-together-ai-query

lib/coding_agent_tools/cli/commands
├── anthropic
│   └── query.rb
├── llm
│   └── query.rb
├── lms
│   └── query.rb
├── mistral
│   └── query.rb
├── openai
│   └── query.rb
└── together_ai
    └── query.rb
```

## Scope of Work

This task involves modifying all specified `llm-<provider>-query` executable scripts (located in `exe/`) to accept a new `--timeout` parameter. The parameter value must then be passed down through their respective Ruby client libraries (located in `lib/coding_agent_tools/cli/commands/`) to the underlying HTTP request atom. Additionally, comprehensive unit tests must be added or updated for each client to verify that the timeout functionality is correctly implemented and propagated.

## Deliverables / Manifest

*   `exe/llm-anthropic-query`: Modify to accept `--timeout` and pass it to the Ruby client.
*   `lib/coding_agent_tools/cli/commands/anthropic/query.rb`: Update to accept and pass the timeout to the HTTP client.
*   Unit tests for `lib/coding_agent_tools/cli/commands/anthropic/query.rb`: Add tests for `--timeout` parameter.

*   `exe/llm-gemini-query`: Modify to accept `--timeout` and pass it to the Ruby client.
*   `lib/coding_agent_tools/cli/commands/llm/query.rb`: Update (if applicable for Gemini) to accept and pass the timeout to the HTTP client.
*   Unit tests for `lib/coding_agent_tools/cli/commands/llm/query.rb` (or specific Gemini client tests): Add tests for `--timeout` parameter.

*   `exe/llm-lmstudio-query`: Modify to accept `--timeout` and pass it to the Ruby client.
*   `lib/coding_agent_tools/cli/commands/lms/query.rb`: Update to accept and pass the timeout to the HTTP client.
*   Unit tests for `lib/coding_agent_tools/cli/commands/lms/query.rb`: Add tests for `--timeout` parameter.

*   `exe/llm-mistral-query`: Modify to accept `--timeout` and pass it to the Ruby client.
*   `lib/coding_agent_tools/cli/commands/mistral/query.rb`: Update to accept and pass the timeout to the HTTP client.
*   Unit tests for `lib/coding_agent_tools/cli/commands/mistral/query.rb`: Add tests for `--timeout` parameter.

*   `exe/llm-openai-query`: Modify to accept `--timeout` and pass it to the Ruby client.
*   `lib/coding_agent_tools/cli/commands/openai/query.rb`: Update to accept and pass the timeout to the HTTP client.
*   Unit tests for `lib/coding_agent_tools/cli/commands/openai/query.rb`: Add tests for `--timeout` parameter.

*   `exe/llm-together-ai-query`: Modify to accept `--timeout` and pass it to the Ruby client.
*   `lib/coding_agent_tools/cli/commands/together_ai/query.rb`: Update to accept and pass the timeout to the HTTP client.
*   Unit tests for `lib/coding_agent_tools/cli/commands/together_ai/query.rb`: Add tests for `--timeout` parameter.

## Phases

1.  **Analysis & Planning:** Identify the exact locations in each `exe/llm-<provider>-query` script where the `--timeout` parameter needs to be parsed and passed. Determine the appropriate Ruby client method and underlying HTTP client atom to which the timeout should be applied for each provider.
2.  **Implementation:**
    *   Modify argument parsing in each `exe` script.
    *   Integrate the `--timeout` value into the corresponding Ruby client's HTTP request logic.
3.  **Unit Testing:** Add specific unit tests for each LLM Ruby client to ensure the `--timeout` parameter is correctly processed and passed to the underlying HTTP atom.

## Implementation Plan

### Planning Steps
* [x] Identify the exact HTTP client/atom used by each Ruby client within `lib/coding_agent_tools/cli/commands/`.
* [x] Determine the mechanism to pass the `--timeout` argument from the `exe` script to the Ruby client, and then to the identified HTTP client/atom.
* [x] Review existing unit tests for `lib/coding_agent_tools/cli/commands/` clients to understand the testing framework (e.g., RSpec) and patterns for testing HTTP interactions.

### Execution Steps
- [x] Modify `exe/llm-anthropic-query` to parse `--timeout` and pass it to `lib/coding_agent_tools/cli/commands/anthropic/query.rb`.
- [x] Update `lib/coding_agent_tools/cli/commands/anthropic/query.rb` to use the timeout parameter in its HTTP calls.
- [x] Add unit tests for `lib/coding_agent_tools/cli/commands/anthropic/query.rb` to verify `--timeout` is correctly handled.
  > TEST: Anthropic Timeout Parameter
  >   Type: Unit Test
  >   Assert: The HTTP request to Anthropic includes the specified timeout.
  >   Command: `bundle exec rspec spec/coding_agent_tools/cli/commands/anthropic/query_spec.rb --example "handles timeout parameter"` (placeholder, actual test name TBD)

- [x] Modify `exe/llm-gemini-query` to parse `--timeout` and pass it to its corresponding Ruby client.
- [x] Update `lib/coding_agent_tools/cli/commands/llm/query.rb` (or specific Gemini client) to use the timeout parameter in its HTTP calls.
- [x] Add unit tests for the Gemini client to verify `--timeout` is correctly handled.
  > TEST: Gemini Timeout Parameter
  >   Type: Unit Test
  >   Assert: The HTTP request to Gemini includes the specified timeout.
  >   Command: `bundle exec rspec spec/coding_agent_tools/cli/commands/llm/query_spec.rb --example "timeout"`

- [x] Modify `exe/llm-lmstudio-query` to parse `--timeout` and pass it to `lib/coding_agent_tools/cli/commands/lms/query.rb`.
- [x] Update `lib/coding_agent_tools/cli/commands/lms/query.rb` to use the timeout parameter in its HTTP calls.
- [x] Add unit tests for `lib/coding_agent_tools/cli/commands/lms/query.rb` to verify `--timeout` is correctly handled.
  > TEST: LM Studio Timeout Parameter
  >   Type: Unit Test
  >   Assert: The HTTP request to LM Studio includes the specified timeout.
  >   Command: `bundle exec rspec spec/coding_agent_tools/cli/commands/lms/query_spec.rb --example "timeout"`

- [x] Modify `exe/llm-mistral-query` to parse `--timeout` and pass it to `lib/coding_agent_tools/cli/commands/mistral/query.rb`.
- [x] Update `lib/coding_agent_tools/cli/commands/mistral/query.rb` to use the timeout parameter in its HTTP calls.
- [x] Add unit tests for `lib/coding_agent_tools/cli/commands/mistral/query.rb` to verify `--timeout` is correctly handled.
  > TEST: Mistral Timeout Parameter
  >   Type: Unit Test
  >   Assert: The HTTP request to Mistral includes the specified timeout.
  >   Command: `bundle exec rspec spec/coding_agent_tools/cli/commands/mistral/query_spec.rb --example "timeout"`

- [x] Modify `exe/llm-openai-query` to parse `--timeout` and pass it to `lib/coding_agent_tools/cli/commands/openai/query.rb`.
- [x] Update `lib/coding_agent_tools/cli/commands/openai/query.rb` to use the timeout parameter in its HTTP calls.
- [x] Add unit tests for `lib/coding_agent_tools/cli/commands/openai/query.rb` to verify `--timeout` is correctly handled.
  > TEST: OpenAI Timeout Parameter
  >   Type: Unit Test
  >   Assert: The HTTP request to OpenAI includes the specified timeout.
  >   Command: `bundle exec rspec spec/coding_agent_tools/cli/commands/openai/query_spec.rb --example "timeout"`

- [x] Modify `exe/llm-together-ai-query` to parse `--timeout` and pass it to `lib/coding_agent_tools/cli/commands/together_ai/query.rb`.
- [x] Update `lib/coding_agent_tools/cli/commands/together_ai/query.rb` to use the timeout parameter in its HTTP calls.
- [x] Add unit tests for `lib/coding_agent_tools/cli/commands/together_ai/query.rb` to verify `--timeout` is correctly handled.
  > TEST: Together AI Timeout Parameter
  >   Type: Unit Test
  >   Assert: The HTTP request to Together AI includes the specified timeout.
  >   Command: `bundle exec rspec spec/coding_agent_tools/cli/commands/together_ai/query_spec.rb --example "timeout"`

- [x] Update documentation or help messages for each `exe/llm-<provider>-query` script to include the new `--timeout` parameter.

## Acceptance Criteria

- [x] Each `exe/llm-<provider>-query` script accepts a `--timeout <SECONDS>` parameter.
- [x] When the `--timeout` parameter is provided, its value is correctly passed from the `exe` script through the corresponding Ruby client library (e.g., `lib/coding_agent_tools/cli/commands/anthropic/query.rb`) to the underlying HTTP client/atom.
- [x] Unit tests for each `llm-<provider>-query` client demonstrate that the `--timeout` parameter is correctly processed and applied to the HTTP request.
- [x] Invalid timeout values (e.g., non-numeric, negative) are handled gracefully (e.g., error message, default value).
- [x] The `--timeout` parameter is documented in the help output of each `exe/llm-<provider>-query` script.

## Out of Scope

-   Modification of integration tests (only unit tests are required).
-   Adding `--timeout` to any commands other than the specified `exe/llm-<provider>-query` scripts.
-   Changes to the core HTTP atom implementation beyond accepting a timeout parameter.

## References & Risks

*   [Write Actionable Task Guide](docs-dev/guides/task-definition.g.md)
*   [Embedding Tests in AI Agent Workflows Guide](docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)
*   **Risk:** Incorrectly propagating the timeout value, leading to it not being applied or causing unexpected behavior in the HTTP client. **Mitigation:** Thorough unit testing for each client.
*   **Risk:** Inconsistent implementation across different `llm-<provider>-query` scripts and Ruby clients. **Mitigation:** Standardize the approach for parsing and passing the timeout.