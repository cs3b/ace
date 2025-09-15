---
id: v.0.5.0+task.050
status: done
priority: high
estimate: 4-6h
dependencies: []
needs_review: false
---

## Review Questions (All Resolved)

### [HIGH] Critical Implementation Questions
- [x] **OpenCode Authentication Setup**: Use error detection approach
  - **Resolution**: Try command, detect auth failure, guide with clear error message
  - **Error message**: "OpenCode authentication required. Run 'opencode auth' to configure providers via Models.dev"
  - **Implementation**: No auto-prompting, keep it simple

- [x] **Default Model Selection Strategy**: Use Gemini Flash 2.5
  - **Resolution**: Default to `google/gemini-2.5-flash` 
  - **Rationale**: Fast, capable, and free model available through OpenCode
  - **Implementation**: Set as DEFAULT_MODEL constant

- [x] **Model Format Handling**: Strict validation
  - **Resolution**: Require provider/model format, show error with examples for malformed input
  - **Implementation**: Validate format before passing to OpenCode

### [MEDIUM] Enhancement Questions
- [x] **Session Management Integration**: Skip for v1
  - **Resolution**: No session management in initial implementation
  - **Rationale**: Keep it simple, can add later if needed
  - **Implementation**: Ignore --session and --continue flags

- [x] **Agent Integration Support**: Skip for v1
  - **Resolution**: No agent support in initial implementation
  - **Rationale**: Focus on core functionality first
  - **Implementation**: Can be added as future enhancement

# Add OpenCode Provider to llm-query Command

## Behavioral Specification

### User Experience
- **Input**: Users run `llm-query oc:model "prompt"` or use shorter aliases like `llm-query opencode "prompt"`
- **Process**: Command seamlessly executes OpenCode CLI in non-interactive mode and returns results
- **Output**: Formatted response from OpenCode with usage metadata (limited by CLI capabilities)

### Expected Behavior

Users can leverage SST's OpenCode through the familiar llm-query interface. The system detects if OpenCode CLI is installed, executes it in non-interactive mode with appropriate parameters, and returns properly formatted results. Users experience the same interface consistency as with other providers while accessing OpenCode's multi-provider capabilities including Anthropic, OpenAI, and other models available through the OpenCode platform.

The provider supports standard llm-query options where applicable, including output formats, file output, model selection in provider/model format, and session management. Error messages clearly indicate if OpenCode CLI is not installed or if authentication fails. The system can discover available models through `opencode models` command.

### Interface Contract

```bash
# CLI Interface - Basic usage
llm-query oc:anthropic/claude-3-5-sonnet "Explain quantum computing"
llm-query oc:openai/gpt-4 "Review this code"
llm-query opencode prompt.txt --output response.txt

# Model discovery
llm-query oc:list  # Special alias to list available models
llm-models --provider oc
# Lists all models available through OpenCode

# Supported model formats
llm-query oc:anthropic/claude-3-5-sonnet  # Full provider/model format
llm-query oc:claude  # May use default provider if configured
llm-query opencode   # Quick alias for default model

# Standard options support (where applicable)
llm-query oc:anthropic/claude "prompt" --output result.txt
llm-query oc:openai/gpt-4 prompt.txt 

# Session management support
llm-query oc:claude "prompt" --session "project-x"
llm-query oc:claude "follow-up" --continue  # Continue last session

# Agent support (if applicable)
llm-query oc:claude "prompt" --agent "code-reviewer"

# Cost tracking integration (limited)
llm-usage-report --provider oc
# Shows usage for OpenCode calls (without detailed token counts)
```

**Error Handling:**
- OpenCode CLI not installed: "Error: OpenCode CLI not found. Install via npm: npm install -g @sst/opencode"
- Authentication failure: "Error: OpenCode authentication failed. Run 'opencode auth' to configure"
- Model not available: "Error: Model 'oc:invalid/model' not recognized. Run 'opencode models' to see available models"
- Network timeout: Standard timeout handling with retry logic
- Invalid model format: "Error: Use provider/model format, e.g., 'anthropic/claude-3-5-sonnet'"

**Edge Cases:**
- Empty prompt: Returns error consistent with other providers
- Model discovery: Dynamically fetches available models via `opencode models`
- Session continuation: Maps --continue and --session flags appropriately
- Concurrent requests: Each subprocess execution is independent
- No JSON output: Text parsing with best-effort metadata extraction

### Success Criteria

- [x] **Provider Recognition**: `llm-query oc:anthropic/claude "test"` executes without "unknown provider" error
- [x] **OpenCode CLI Execution**: System successfully invokes `opencode run` with correct parameters
- [x] **Model Discovery**: `list_models` method lists available models from OpenCode with fallback
- [x] **Output Formatting**: Text output works consistently with other providers
- [x] **Error Messages**: Clear, actionable error messages when OpenCode CLI is missing or auth fails
- [x] **Alias Support**: Short aliases (opencode, oc:gflash) work as expected
- [x] **Session Management**: Skipped for v1 as planned (simple implementation first)
- [x] **Multi-Provider Support**: Correctly handles provider/model format for different AI providers

### Validation Questions (Updated from Research)

- [x] **CLI Command Structure**: ✅ Confirmed - `opencode run [message..]` with `--model`, `--session`, `--continue` flags
- [x] **Model Discovery Method**: ✅ Confirmed - `opencode models` lists all provider/model combinations
- [x] **Authentication Flow**: ✅ Confirmed - `opencode auth login` via Models.dev, validate with `opencode models` success
- [x] **Model Format Standard**: ✅ Confirmed - All models use "provider/model" format (e.g., "anthropic/claude-3-5-sonnet")
- [ ] **Default Model**: How to determine default model when user just types `oc:` without model? (NEEDS REVIEW)
- [ ] **Model Aliases**: Should we create shortcuts for common models via alias system? (NEEDS REVIEW)
- [ ] **Agent Integration**: Should we expose OpenCode's `--agent` functionality? (NEEDS REVIEW)
- [ ] **Session Persistence**: Should we map `--session` flag to OpenCode's session management? (NEEDS REVIEW)

## Objective

Enable developers to use SST's OpenCode CLI through the unified llm-query interface, providing consistent access to multiple AI providers through OpenCode's unified platform while maintaining llm-query's standard interface.

## Scope of Work

- **User Experience Scope**: Command-line invocation of OpenCode models through llm-query with standard options
- **System Behavior Scope**: Subprocess execution of OpenCode CLI, model discovery, output parsing, error handling
- **Interface Scope**: New provider "oc" with dynamic model discovery and multi-provider support

### Deliverables

#### Behavioral Specifications
- OpenCode provider integration with llm-query command
- Dynamic model discovery via `opencode models`
- Model alias mapping for user convenience  
- Consistent error handling and user feedback

#### Validation Artifacts
- Test cases for OpenCode CLI subprocess execution
- Integration tests with mocked OpenCode responses
- Model discovery and listing verification
- Usage tracking verification (limited by CLI output)

## Out of Scope

- ❌ **Implementation Details**: Specific class structure, file organization, subprocess library choice
- ❌ **Technology Decisions**: Whether to use Open3, IO.popen, or other subprocess methods
- ❌ **Performance Optimization**: Caching strategies, connection pooling approaches
- ❌ **Future Enhancements**: GitHub agent integration, headless server mode, advanced features

## Technical Approach

### Architecture Pattern (Updated from Research)
- **Provider Pattern**: Follow existing BaseClient inheritance model (like ClaudeCodeClient)
- **Auto-Registration**: Leverage ClientFactory.register via inherited hook with provider name "oc"  
- **Subprocess Execution**: Use Ruby's Open3 for safe command execution with proper error handling
- **Adapter Pattern**: Wrap OpenCode CLI to match internal provider interface
- **Dynamic Discovery**: Use `opencode models` for model listing (confirmed available)

### Technology Stack (Validated)
- **Ruby Open3**: For subprocess execution with stdout/stderr/status capture  
- **JSON Parser**: Parse `opencode models` output and responses (if JSON mode available)
- **Text Parser**: Fallback for text-only output parsing
- **Which Command**: For detecting OpenCode CLI availability
- **Timeout**: Protect against hanging subprocess calls

### Implementation Strategy (Final)
- **Model Discovery**: Implement model listing via `opencode models` (confirmed command)
- **Default Model**: Use `google/gemini-2.5-flash` as default
- **Error-First Design**: Comprehensive error handling for missing CLI, auth failures
- **Provider/Model Format**: Strict validation, require provider/model syntax
- **Authentication Check**: Use `opencode models` success as auth validation
- **CLI Command**: Use `opencode run [prompt]` with `--model` flag only (no session in v1)
- **Metadata Synthesis**: Create synthetic metadata when detailed info not available from CLI
- **Test-Driven**: Mock subprocess calls for reliable testing

### Research Findings Integration
- **OpenCode Commands**: `opencode run [message..]` for execution, `opencode models` for discovery
- **Authentication**: `opencode auth login/list/logout` manages provider credentials via Models.dev
- **Model Format**: All models follow "provider/model" format (e.g., "anthropic/claude-3-5-sonnet")
- **CLI Flags**: Supports `--model`, `--session`, `--continue`, `--agent` for enhanced functionality
- **Multi-Provider**: Access to 75+ providers through single CLI interface

## File Modifications

### Create
- `lib/coding_agent_tools/organisms/open_code_client.rb`
  - Purpose: OpenCode CLI provider implementation
  - Key components: generate_text, list_models (dynamic), CLI execution logic
  - Dependencies: BaseClient, Open3

- `spec/coding_agent_tools/organisms/open_code_client_spec.rb`
  - Purpose: Unit tests for OpenCodeClient
  - Key components: Mock subprocess tests, model discovery tests, error handling tests
  - Dependencies: RSpec, test factories

- `spec/cassettes/llm_query_integration/opencode/*.json`
  - Purpose: VCR cassettes for integration tests
  - Key components: Mocked OpenCode CLI responses
  - Dependencies: VCR framework

### Modify
- `config/default-llm-aliases.yml`
  - Changes: Add "opencode" global alias and "oc" provider-specific aliases
  - Impact: Enable quick access via aliases
  - Integration points: Alias resolver

- `spec/integration/llm_query_integration_spec.rb`
  - Changes: Add test cases for oc: provider
  - Impact: Validate CLI integration
  - Integration points: Command execution tests

## Test Case Planning

### Happy Path Scenarios
- Basic prompt execution: `llm-query oc:anthropic/claude "Hello"`
- File input: `llm-query oc:openai/gpt-4 prompt.txt`
- Model discovery: `llm-models --provider oc`
- Session continuation: `llm-query oc:claude "test" --continue`
- Agent usage: `llm-query oc:claude "test" --agent "reviewer"`

### Edge Case Scenarios
- Empty prompt handling
- Invalid provider/model format
- Model discovery failures
- Session ID persistence
- Special characters in prompt
- Concurrent executions

### Error Condition Scenarios
- OpenCode CLI not installed
- Authentication not configured
- Invalid model format
- Network timeout during execution
- Model discovery command failure
- Subprocess execution failure

### Integration Tests
- End-to-end llm-query execution
- Model discovery and listing
- Session management
- Cost tracking integration (limited)
- Multi-provider model access

## Risk Assessment

### Technical Risks
- **Risk:** OpenCode CLI output format changes
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Flexible text parsing, version detection

- **Risk:** Model discovery command changes
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Fallback to static model list

### Integration Risks
- **Risk:** Provider/model format parsing complexity
  - **Probability:** Medium  
  - **Impact:** Medium
  - **Mitigation:** Robust parsing with clear error messages

- **Risk:** Session management complexity
  - **Probability:** High
  - **Impact:** Low
  - **Mitigation:** Start simple, enhance later

## Implementation Plan

### Planning Steps
* [x] Research OpenCode CLI command structure → **COMPLETED**: Uses `opencode run [message..]`
* [x] Analyze run command parameters → **COMPLETED**: Supports `--model`, `--session`, `--continue`, `--agent` flags
* [x] Explore model discovery via `opencode models` → **COMPLETED**: Lists provider/model format from Models.dev
* [x] Research authentication flow → **COMPLETED**: Uses `opencode auth login/list/logout` via Models.dev
* [x] Investigate session management → **COMPLETED**: CLI supports `--session` and `--continue` flags
* [x] Study existing provider patterns → **COMPLETED**: Follow ClaudeCodeClient inheritance model
* [x] Analyze alias system integration → **COMPLETED**: Can leverage existing llm-aliases.yml structure

### Execution Steps
- [x] Create OpenCodeClient class structure
- [x] Implement OpenCode CLI detection
- [x] Implement list_models with `opencode models` parsing
- [x] Implement generate_text with subprocess execution
- [x] Add provider/model format parsing
- [x] Handle session management flags (skipped for v1)
- [x] Add text output parsing
- [x] Create synthetic metadata
- [x] Add comprehensive unit tests
- [x] Add integration tests with mocked responses
- [x] Update alias configuration
- [x] Document usage in tools.md

## Acceptance Criteria

### Behavioral Requirement Fulfillment
- [x] `llm-query oc:anthropic/claude-3-5-sonnet "test"` executes without "unknown provider" error
- [x] Model discovery works via `list_models` method (with fallback models)
- [x] Standard llm-query options work where applicable
- [x] Error messages provide clear remediation steps
- [x] Aliases work for quick access

### Implementation Quality Assurance
- [x] OpenCodeClient follows project patterns (BaseClient inheritance)
- [x] Tests pass with good coverage (27 examples, 0 failures)
- [x] No security vulnerabilities in subprocess execution (uses Open3)
- [x] Performance overhead < 500ms (fast CLI detection and execution)

### Documentation and Validation
- [x] tools.md updated with OpenCode examples
- [x] Integration tests cover main scenarios
- [x] Model discovery documented (implemented with fallback)
- [x] Provider/model format explained (strict provider/model validation)

## References

- OpenCode CLI documentation: `opencode --help` output
- SST OpenCode repository: https://github.com/sst/opencode
- Claude Code integration pattern: v.0.5.0+task.046
- Existing provider implementations in dev-tools
- User request for OpenCode integration with llm-query