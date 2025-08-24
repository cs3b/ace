---
id: v.0.5.0+task.046
status: pending
priority: high
estimate: 6h
dependencies: []
needs_review: true
---

# Add Claude Code Provider to llm-query Command

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] **Provider Key Selection**: Should we use "cc" or "claude_code" as the primary provider key?
  - **Research conducted**: Checked existing provider patterns (anthropic, openai, google)
  - **Similar implementations**: All use full names, but aliases provide shortcuts
  - **Suggested default**: Use "claude_code" as primary, "cc" as alias
  - **Why needs human input**: User preference and consistency decision

### [MEDIUM] Enhancement Questions
- [ ] **Cost Calculation Source**: Should costs be calculated from Claude's pricing or tracked separately?
  - **Research conducted**: Claude CLI returns `total_cost_usd` in JSON output
  - **Suggested default**: Use Claude's provided cost data directly
  - **Why needs human input**: Decide if we trust/use Claude's cost vs our own calculations

### [LOW] Clarification Questions
- [ ] **Error Message Format**: Should error messages match Claude CLI's style or our standard format?
  - **Research conducted**: Our providers use consistent error format
  - **Suggested default**: Wrap Claude errors in our standard format
  - **Why needs human input**: UX consistency preference

## Behavioral Specification

### User Experience
- **Input**: Users run `llm-query cc:opus "prompt"` or similar Claude Code model invocations
- **Process**: Command seamlessly executes Claude CLI in non-interactive mode and returns results
- **Output**: Formatted response from Claude Code with usage metadata and cost information

### Expected Behavior
<!-- Describe WHAT the system should do from the user's perspective -->

Users can leverage their Claude Code subscription through the familiar llm-query interface. The system detects if Claude CLI is installed, executes it in non-interactive mode with appropriate parameters, and returns properly formatted results. Users experience the same interface consistency as with other providers (google, openai, anthropic) while accessing Claude Code's enhanced capabilities like extended context windows and advanced reasoning.

The provider supports all standard llm-query options including output formats (text/json/markdown), file output, system prompts, temperature control, and max tokens. Error messages clearly indicate if Claude CLI is not installed or if authentication fails.

### Interface Contract
<!-- Define all external interfaces, APIs, and interaction points -->

```bash
# CLI Interface - Basic usage
llm-query cc:opus "Explain quantum computing"
llm-query cc:sonnet "Review this code" --system "You are a code reviewer"
llm-query claude_code:opus-4 prompt.txt --output response.json

# Supported model aliases
llm-query cc:opus     # Maps to claude-opus-4-20250514
llm-query cc:sonnet   # Maps to claude-sonnet-4-20250514
llm-query cc:haiku    # Maps to claude-3-7-haiku
llm-query ccfast      # Quick alias for default/fast model

# Standard options support
llm-query cc:opus "prompt" --format json
llm-query cc:sonnet "prompt" --temperature 0.5
llm-query cc:opus "prompt" --max-tokens 2000
llm-query cc:sonnet prompt.txt --system system.md --output result.md

# Provider listing
llm-models --provider cc
# Lists available Claude Code models

# Cost tracking integration
llm-usage-report --provider cc
# Shows usage and costs for Claude Code calls
```

**Error Handling:**
- Claude CLI not installed: "Error: Claude CLI not found. Install with: npm install -g @anthropic-ai/claude-cli"
- Authentication failure: "Error: Claude authentication failed. Run 'claude setup-token' to configure"
- Model not available: "Error: Model 'cc:invalid' not recognized. Available: opus, sonnet, haiku"
- Network timeout: Standard timeout handling with retry logic

**Edge Cases:**
- Empty prompt: Returns error consistent with other providers
- Very long prompts: Leverages Claude Code's extended context window
- Concurrent requests: Each subprocess execution is independent
- JSON parsing failures: Falls back to text output with warning

### Success Criteria
<!-- Define measurable, observable criteria that indicate successful completion -->

- [ ] **Provider Recognition**: `llm-query cc:opus "test"` executes without "unknown provider" error
- [ ] **Claude CLI Execution**: System successfully invokes `claude -p` with correct parameters
- [ ] **Output Formatting**: JSON, text, and markdown formats work consistently with other providers
- [ ] **Error Messages**: Clear, actionable error messages when Claude CLI is missing or auth fails
- [ ] **Alias Support**: Short aliases (cc:opus, ccfast) resolve to correct models
- [ ] **Cost Tracking**: Usage metadata includes token counts and cost calculations
- [ ] **Option Mapping**: Temperature, max_tokens, and system prompts correctly map to Claude CLI flags

### Validation Questions (Resolved Through Research)
<!-- Questions answered through autonomous research -->

- [x] **Authentication Method**: Should we use ANTHROPIC_API_KEY or rely on Claude's setup-token?
  - **Resolution**: Use Claude's setup-token authentication
  - **Evidence**: Claude CLI manages its own auth via `claude setup-token` command
  - **Implementation**: Check if claude is authenticated, guide user to run setup-token if not

- [x] **Model Version Pinning**: Should cc:opus always use latest or pin to specific version?
  - **Resolution**: Use model aliases that map to current versions
  - **Evidence**: Claude CLI accepts model names like "opus", "sonnet" directly
  - **Implementation**: Pass model names directly to Claude CLI, it handles version resolution

- [x] **Streaming Support**: Should we support Claude's stream-json format for real-time output?
  - **Resolution**: Not in initial implementation, can be added later
  - **Evidence**: --output-format supports stream-json but adds complexity
  - **Implementation**: Start with json format, streaming can be future enhancement

- [ ] **Tool Capability**: Should we expose Claude Code's tool/function calling capabilities?
  - **Needs Review**: Complex feature requiring design decision
  - **Research**: Claude CLI supports tools but requires additional flags
  - **Impact**: Would need different command structure

- [x] **Fallback Behavior**: If Claude CLI fails, should we fall back to standard Anthropic API?
  - **Resolution**: No automatic fallback, clear error messages instead
  - **Evidence**: Different auth methods and capabilities between Claude CLI and API
  - **Implementation**: If Claude CLI unavailable, suggest using anthropic: provider

## Objective

Enable developers to use their Claude Code subscription through the unified llm-query interface, providing consistent access to all LLM providers while leveraging Claude Code's enhanced capabilities and existing authentication.

## Scope of Work
<!-- Define the behavioral scope - what user experiences and system behaviors are included -->

- **User Experience Scope**: Command-line invocation of Claude Code models through llm-query with all standard options
- **System Behavior Scope**: Subprocess execution of Claude CLI, output parsing, metadata normalization, error handling
- **Interface Scope**: New provider "cc" or "claude_code" with model selection and standard llm-query options

### Deliverables
<!-- Focus on behavioral and experiential deliverables, not implementation artifacts -->

#### Behavioral Specifications
- Claude Code provider integration with llm-query command
- Model alias mapping for user convenience  
- Consistent error handling and user feedback

#### Validation Artifacts
- Test cases for Claude CLI subprocess execution
- Integration tests with mocked Claude responses
- Cost calculation verification

## Out of Scope
<!-- Explicitly exclude implementation concerns to maintain behavioral focus -->

- ❌ **Implementation Details**: Specific class structure, file organization, subprocess library choice
- ❌ **Technology Decisions**: Whether to use Open3, IO.popen, or other subprocess methods
- ❌ **Performance Optimization**: Caching strategies, connection pooling approaches
- ❌ **Future Enhancements**: MCP protocol support, streaming responses, function calling

## Technical Approach

### Architecture Pattern
- **Provider Pattern**: Follow existing BaseClient/BaseChatCompletionClient inheritance model
- **Auto-Registration**: Leverage ClientFactory.register via inherited hook
- **Subprocess Execution**: Use Ruby's Open3 for safe command execution with proper error handling
- **Adapter Pattern**: Wrap Claude CLI to match internal provider interface

### Technology Stack
- **Ruby Open3**: For subprocess execution with stdout/stderr/status capture
- **JSON Parser**: Built-in Ruby JSON for parsing Claude's JSON output
- **Faraday**: Not needed - direct CLI execution instead of HTTP
- **Which Command**: For detecting Claude CLI availability

### Implementation Strategy
- **Progressive Enhancement**: Start with basic execution, add features incrementally
- **Error-First Design**: Comprehensive error handling for missing CLI, auth failures
- **Metadata Normalization**: Map Claude's output to standard UsageMetadata structure
- **Test-Driven**: Mock subprocess calls for reliable testing

## File Modifications

### Create
- `lib/coding_agent_tools/organisms/claude_code_client.rb`
  - Purpose: Claude Code provider implementation
  - Key components: generate_text, list_models, CLI execution logic
  - Dependencies: BaseClient, Open3, JSON

- `spec/coding_agent_tools/organisms/claude_code_client_spec.rb`
  - Purpose: Unit tests for ClaudeCodeClient
  - Key components: Mock subprocess tests, error handling tests
  - Dependencies: RSpec, test factories

- `spec/cassettes/llm_query_integration/claude_code/*.json`
  - Purpose: VCR cassettes for integration tests
  - Key components: Mocked Claude CLI responses
  - Dependencies: VCR framework

### Modify
- `lib/coding_agent_tools/molecules/provider_model_parser.rb`
  - Changes: Add "cc" and "claude_code" to supported providers
  - Impact: Enable provider recognition in parse method
  - Integration points: Dynamic alias registration

- `lib/coding_agent_tools/molecules/metadata_normalizer.rb`
  - Changes: Add Claude Code output format handling
  - Impact: Proper metadata extraction from Claude JSON
  - Integration points: normalize_with_cost method

- `spec/coding_agent_tools/cli/commands/llm/query_spec.rb`
  - Changes: Add test cases for cc: provider
  - Impact: Validate CLI integration
  - Integration points: Command execution tests

## Test Case Planning

### Happy Path Scenarios
- Basic prompt execution: `llm-query cc:opus "Hello"`
- File input: `llm-query cc:sonnet prompt.txt`
- JSON output: `llm-query cc:opus "test" --format json`
- System prompt: `llm-query cc:sonnet "code" --system "reviewer"`

### Edge Case Scenarios
- Empty prompt handling
- Very long prompt (>100k tokens)
- Special characters in prompt
- Concurrent executions
- Invalid model names

### Error Condition Scenarios
- Claude CLI not installed
- Authentication not configured
- Network timeout during execution
- Invalid JSON response from Claude
- Subprocess execution failure

### Integration Tests
- End-to-end llm-query execution
- Cost tracking integration
- llm-models listing
- Usage report generation

## Risk Assessment

### Technical Risks
- **Risk:** Claude CLI API changes breaking integration
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Version detection and compatibility checks
  - **Rollback:** Feature flag to disable provider

- **Risk:** Subprocess execution security vulnerabilities
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Use Open3 with proper escaping, no shell expansion
  - **Rollback:** Immediate patch and security audit

### Integration Risks
- **Risk:** Performance degradation from subprocess overhead
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Benchmark and optimize subprocess calls
  - **Monitoring:** Response time metrics

### Performance Risks
- **Risk:** Slow Claude CLI startup affecting response times
  - **Mitigation:** Consider process pooling for future optimization
  - **Monitoring:** Track execution times
  - **Thresholds:** < 500ms overhead acceptable

## Implementation Plan

### Planning Steps

* [x] Research Claude CLI JSON output format
  - **Completed**: Analyzed actual JSON output structure
  - **Findings**: Contains `result`, `usage`, `total_cost_usd`, `session_id`, token counts
  - **Key fields**: `usage.input_tokens`, `usage.output_tokens`, `usage.cache_read_input_tokens`
  - **Example output structure**:
    ```json
    {
      "type": "result",
      "result": "response text",
      "usage": {
        "input_tokens": N,
        "output_tokens": N,
        "cache_read_input_tokens": N,
        "cache_creation_input_tokens": N
      },
      "total_cost_usd": 0.00123,
      "session_id": "uuid",
      "duration_ms": 2000
    }
    ```

* [ ] Investigate Claude CLI error codes
  - Test various failure scenarios
  - Document exit codes and error messages
  - Plan error message mapping

* [x] Analyze model name mapping
  - **Completed**: Claude CLI accepts simple model names
  - **Findings**: Use "opus", "sonnet", "haiku" directly
  - **No version pinning needed**: Claude CLI handles version resolution

### Execution Steps

- [ ] Create ClaudeCodeClient class structure
  ```ruby
  # lib/coding_agent_tools/organisms/claude_code_client.rb
  class ClaudeCodeClient < BaseClient
    def self.provider_name; "claude_code"; end
    def self.dynamic_aliases; {...}; end
  end
  ```
  > TEST: Class Creation
  > Type: Structural Test
  > Assert: Class exists and inherits correctly
  > Command: ruby -r./lib/coding_agent_tools -e "p CodingAgentTools::Organisms::ClaudeCodeClient"

- [ ] Implement Claude CLI detection
  ```ruby
  def claude_available?
    system("which claude > /dev/null 2>&1")
  end
  ```
  > TEST: CLI Detection
  > Type: Availability Check
  > Assert: Method correctly detects Claude CLI
  > Command: ruby -e "puts system('which claude > /dev/null 2>&1')"

- [ ] Implement generate_text with subprocess execution
  ```ruby
  def generate_text(prompt, **options)
    cmd = build_claude_command(prompt, options)
    stdout, stderr, status = Open3.capture3(*cmd)
    parse_claude_response(stdout, stderr, status)
  end
  ```
  > TEST: Subprocess Execution
  > Type: Integration Test
  > Assert: Claude CLI executes and returns response
  > Command: echo "test" | claude -p "test" --output-format json

- [ ] Add model name mapping
  ```ruby
  MODEL_MAPPING = {
    "opus" => "claude-opus-4-20250514",
    "sonnet" => "claude-sonnet-4-20250514",
    "haiku" => "claude-3-7-haiku"
  }
  ```

- [ ] Implement list_models method
  ```ruby
  def list_models
    return fallback_models unless claude_available?
    # Return available Claude Code models
  end
  ```

- [ ] Add metadata normalization for Claude output
  - Parse JSON response structure from Claude CLI
  - Map fields: `result` → text, `usage` → metadata
  - Extract token counts: input_tokens, output_tokens, cache tokens
  - Use provided `total_cost_usd` instead of calculating
  - Map `duration_ms` to execution time

- [ ] Create comprehensive unit tests
  > TEST: Unit Test Coverage
  > Type: Test Execution
  > Assert: All methods have test coverage
  > Command: rspec spec/coding_agent_tools/organisms/claude_code_client_spec.rb

- [ ] Add integration tests with mocked responses
  > TEST: Integration Tests
  > Type: End-to-end Test
  > Assert: llm-query cc:opus works correctly
  > Command: rspec spec/integration/llm_query_integration_spec.rb -e "claude_code"

- [ ] Update provider registration
  - Ensure ClaudeCodeClient auto-registers
  - Verify provider appears in llm-models list
  > TEST: Provider Registration
  > Type: Provider Check
  > Assert: cc provider recognized
  > Command: llm-models --provider cc

- [ ] Add error handling and user feedback
  - Clear messages for missing CLI
  - Authentication guidance
  - Model availability errors

- [ ] Document usage in tools.md
  - Add Claude Code examples
  - Document prerequisites
  - Include troubleshooting guide

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] `llm-query cc:opus "test"` executes successfully
- [ ] All standard llm-query options work with cc: provider
- [ ] Error messages provide clear remediation steps
- [ ] Cost tracking integrates properly

### Implementation Quality Assurance
- [ ] ClaudeCodeClient follows project patterns
- [ ] Tests pass with > 90% coverage
- [ ] No security vulnerabilities in subprocess execution
- [ ] Performance overhead < 500ms

### Documentation and Validation
- [ ] tools.md updated with Claude Code examples
- [ ] Integration tests cover all scenarios
- [ ] Model aliases documented clearly

## References

- Research document: dev-taskflow/current/v.0.5.0-insights/researches/run-cloud-code-by-llm-query.md
- Claude CLI documentation: `claude --help` output
- Existing provider pattern: AnthropicClient, OpenAIClient implementations
- User request for Claude Code integration with llm-query
- Ruby Open3 documentation for subprocess execution
- BaseClient inheritance pattern in dev-tools