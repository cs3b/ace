---
id: v.0.5.0+task.049
status: pending
priority: high
estimate: 4-6h
dependencies: []
---

# Add Codex CLI Provider to llm-query Command

## Behavioral Specification

### User Experience
- **Input**: Users run `llm-query codex:model "prompt"` or use shorter aliases like `llm-query codex "prompt"`
- **Process**: Command seamlessly executes Codex CLI in non-interactive mode and returns results
- **Output**: Formatted response from Codex with usage metadata (limited by CLI capabilities)

### Expected Behavior

Users can leverage their Codex CLI (OpenAI) through the familiar llm-query interface. The system detects if Codex CLI is installed, executes it in non-interactive mode with appropriate parameters, and returns properly formatted results. Users experience the same interface consistency as with other providers (google, openai, anthropic, cc) while accessing Codex's capabilities like o3-mini and other OpenAI models.

The provider supports standard llm-query options where applicable, including output formats, file output, model selection, and configuration overrides. Error messages clearly indicate if Codex CLI is not installed or if authentication fails.

### Interface Contract

```bash
# CLI Interface - Basic usage
llm-query codex:o3-mini "Explain quantum computing"
llm-query codex:o3 "Review this code"
llm-query codex prompt.txt --output response.txt

# Supported model aliases
llm-query codex:o3        # Maps to o3 model
llm-query codex:o3-mini   # Maps to o3-mini model
llm-query codex           # Quick alias for default model

# Standard options support (where applicable)
llm-query codex:o3 "prompt" --output result.txt
llm-query codex:o3-mini prompt.txt 

# Configuration override support
llm-query codex:o3 "prompt" --config "sandbox=read-only"

# Provider listing
llm-models --provider codex
# Lists available Codex models (if discoverable)

# Cost tracking integration (limited)
llm-usage-report --provider codex
# Shows usage for Codex calls (without token counts)
```

**Error Handling:**
- Codex CLI not installed: "Error: Codex CLI not found. Install from https://codex.ai or via npm"
- Authentication failure: "Error: Codex authentication failed. Run 'codex login' to configure"
- Model not available: "Error: Model 'codex:invalid' not recognized"
- Network timeout: Standard timeout handling with retry logic

**Edge Cases:**
- Empty prompt: Returns error consistent with other providers
- Very long prompts: Handled by Codex CLI's capabilities
- Concurrent requests: Each subprocess execution is independent
- No JSON output: Text parsing with best-effort metadata extraction

### Success Criteria

- [ ] **Provider Recognition**: `llm-query codex:o3-mini "test"` executes without "unknown provider" error
- [ ] **Codex CLI Execution**: System successfully invokes `codex exec` with correct parameters
- [ ] **Output Formatting**: Text output works consistently with other providers
- [ ] **Error Messages**: Clear, actionable error messages when Codex CLI is missing or auth fails
- [ ] **Alias Support**: Short aliases (codex:o3, codex) resolve to correct models
- [ ] **Option Mapping**: Model selection and configuration options correctly map to Codex CLI flags
- [ ] **Graceful Degradation**: Works without token counts or detailed metadata

### Validation Questions

- [ ] **Default Model**: Should default be o3-mini, o3, or auto-detect from user's Codex config?
- [ ] **OSS Mode**: Should we support `--oss` flag for local Ollama integration?
- [ ] **Sandbox Modes**: How to map llm-query options to Codex sandbox policies?
- [ ] **Profile Support**: Should we expose Codex profile selection via llm-query?

## Objective

Enable developers to use OpenAI's Codex CLI through the unified llm-query interface, providing consistent access to all LLM providers while leveraging Codex's capabilities and existing authentication.

## Scope of Work

- **User Experience Scope**: Command-line invocation of Codex models through llm-query with standard options
- **System Behavior Scope**: Subprocess execution of Codex CLI, output parsing, metadata normalization, error handling
- **Interface Scope**: New provider "codex" with model selection and standard llm-query options

### Deliverables

#### Behavioral Specifications
- Codex provider integration with llm-query command
- Model alias mapping for user convenience  
- Consistent error handling and user feedback

#### Validation Artifacts
- Test cases for Codex CLI subprocess execution
- Integration tests with mocked Codex responses
- Usage tracking verification (limited by CLI output)

## Out of Scope

- ❌ **Implementation Details**: Specific class structure, file organization, subprocess library choice
- ❌ **Technology Decisions**: Whether to use Open3, IO.popen, or other subprocess methods
- ❌ **Performance Optimization**: Caching strategies, connection pooling approaches
- ❌ **Future Enhancements**: MCP protocol support, streaming responses, advanced features

## Technical Approach

### Architecture Pattern
- **Provider Pattern**: Follow existing BaseClient/BaseChatCompletionClient inheritance model
- **Auto-Registration**: Leverage ClientFactory.register via inherited hook with provider name "codex"
- **Subprocess Execution**: Use Ruby's Open3 for safe command execution with proper error handling
- **Adapter Pattern**: Wrap Codex CLI to match internal provider interface

### Technology Stack
- **Ruby Open3**: For subprocess execution with stdout/stderr/status capture
- **Text Parser**: Parse text output (no JSON available from Codex)
- **Which Command**: For detecting Codex CLI availability
- **Timeout**: Protect against hanging subprocess calls

### Implementation Strategy
- **Progressive Enhancement**: Start with basic execution, add features incrementally
- **Error-First Design**: Comprehensive error handling for missing CLI, auth failures
- **Metadata Synthesis**: Create synthetic metadata when not available from CLI
- **Test-Driven**: Mock subprocess calls for reliable testing

## File Modifications

### Create
- `lib/coding_agent_tools/organisms/codex_client.rb`
  - Purpose: Codex CLI provider implementation
  - Key components: generate_text, list_models (limited), CLI execution logic
  - Dependencies: BaseClient, Open3

- `spec/coding_agent_tools/organisms/codex_client_spec.rb`
  - Purpose: Unit tests for CodexClient
  - Key components: Mock subprocess tests, error handling tests
  - Dependencies: RSpec, test factories

- `spec/cassettes/llm_query_integration/codex/*.json`
  - Purpose: VCR cassettes for integration tests
  - Key components: Mocked Codex CLI responses
  - Dependencies: VCR framework

### Modify
- `config/default-llm-aliases.yml`
  - Changes: Add "codex" global alias and provider-specific aliases
  - Impact: Enable quick access via aliases
  - Integration points: Alias resolver

- `spec/integration/llm_query_integration_spec.rb`
  - Changes: Add test cases for codex: provider
  - Impact: Validate CLI integration
  - Integration points: Command execution tests

## Test Case Planning

### Happy Path Scenarios
- Basic prompt execution: `llm-query codex:o3-mini "Hello"`
- File input: `llm-query codex:o3 prompt.txt`
- Model selection: `llm-query codex:o3 "test"`
- Configuration override: `llm-query codex "test" --config "sandbox=read-only"`

### Edge Case Scenarios
- Empty prompt handling
- Very long prompt (test Codex limits)
- Special characters in prompt
- Concurrent executions
- Invalid model names
- OSS mode flag handling

### Error Condition Scenarios
- Codex CLI not installed
- Authentication not configured
- Network timeout during execution
- Subprocess execution failure
- Invalid configuration values

### Integration Tests
- End-to-end llm-query execution
- Cost tracking integration (limited)
- llm-models listing (if available)
- Usage report generation

## Risk Assessment

### Technical Risks
- **Risk:** Codex CLI output format changes
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Flexible text parsing, version detection

- **Risk:** No JSON output available
  - **Probability:** Certain
  - **Impact:** Low
  - **Mitigation:** Text parsing, synthetic metadata

### Integration Risks
- **Risk:** Authentication method differences
  - **Probability:** Medium  
  - **Impact:** High
  - **Mitigation:** Clear error messages, auth guidance

## Implementation Plan

### Planning Steps
* [x] Research Codex CLI command structure
* [x] Analyze exec command parameters
* [ ] Test authentication flow
* [ ] Explore configuration options

### Execution Steps
- [ ] Create CodexClient class structure
- [ ] Implement Codex CLI detection
- [ ] Implement generate_text with subprocess execution
- [ ] Add model name handling (o3, o3-mini)
- [ ] Implement list_models method (static or discovered)
- [ ] Add text output parsing
- [ ] Create synthetic metadata
- [ ] Add comprehensive unit tests
- [ ] Add integration tests with mocked responses
- [ ] Update alias configuration
- [ ] Document usage in tools.md

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [ ] `llm-query codex:o3-mini "test"` executes successfully
- [ ] Standard llm-query options work where applicable
- [ ] Error messages provide clear remediation steps
- [ ] Aliases work for quick access

### Implementation Quality Assurance
- [ ] CodexClient follows project patterns
- [ ] Tests pass with good coverage
- [ ] No security vulnerabilities in subprocess execution
- [ ] Performance overhead < 500ms

### Documentation and Validation
- [ ] tools.md updated with Codex examples
- [ ] Integration tests cover main scenarios
- [ ] Model aliases documented clearly

## References

- Codex CLI documentation: `codex --help` output
- Claude Code integration pattern: v.0.5.0+task.046
- Existing provider implementations in dev-tools
- User request for Codex CLI integration with llm-query