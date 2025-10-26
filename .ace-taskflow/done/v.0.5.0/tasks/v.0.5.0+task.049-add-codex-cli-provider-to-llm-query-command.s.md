---
id: v.0.5.0+task.049
status: done
priority: high
estimate: 4-6h
dependencies: []
needs_review: false
---

# Add Codex CLI Provider to llm-query Command

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] **Codex CLI Command Structure**: What is the exact command structure for Codex CLI execution?
  - **Research conducted**: Found general info about Codex CLI (launched April 2025, npm install @openai/codex)
  - **Missing details**: Specific commands like `codex exec`, `codex run`, or similar for non-interactive execution
  - **Evidence needed**: Output from `codex --help` and actual command examples
  - **Why needs human input**: Cannot proceed with subprocess implementation without knowing exact command syntax

- [ ] **Authentication Method**: How does Codex CLI handle authentication in our integration?
  - **Research conducted**: Found Codex supports ChatGPT Sign-in and API key authentication
  - **Configuration options**: `~/.codex/config.toml` for preferences, API key env vars possible
  - **Similar pattern**: Claude Code uses `claude setup-token`, but Codex method unclear
  - **Why needs human input**: Need to know if we detect auth via command test or environment check

- [ ] **Model Name Mapping**: How should codex:o3-mini map to actual Codex CLI model names?
  - **Research conducted**: Codex supports o3, o3-mini, gpt-5 models via `-m` flag
  - **Example found**: `codex -m o3` for model selection
  - **Suggested mapping**: codex:o3 → "o3", codex:o3-mini → "o3-mini", codex → "o3-mini" (default)
  - **Why needs human input**: Confirm model naming conventions match user expectations

### [MEDIUM] Enhancement Questions
- [ ] **OSS Mode Support**: Should we implement the `--oss` flag for local Ollama integration mentioned in the spec?
  - **Research conducted**: Task mentions OSS mode but unclear if this exists in Codex CLI
  - **Implementation impact**: Would require different command structure and error handling
  - **Suggested default**: Skip OSS mode in initial implementation, add later if needed
  - **Why needs human input**: Clarify if this is a real Codex feature or speculative

- [ ] **Output Format**: Does Codex CLI support JSON output like Claude CLI, or do we need text parsing?
  - **Research conducted**: Claude CLI uses `--output-format json` for structured responses
  - **Unknown**: Whether Codex has similar JSON output capabilities
  - **Fallback approach**: Text parsing with synthetic metadata if no JSON support
  - **Why needs human input**: Affects metadata extraction and cost calculation approach

### [LOW] Configuration Questions  
- [ ] **Sandbox Configuration**: How should llm-query configuration options map to Codex sandbox policies?
  - **Research conducted**: Task mentions sandbox policies but details unclear
  - **Implementation approach**: Pass through as command flags if supported
  - **Why needs human input**: Low priority - can implement basic version first

## Research Summary

### Codex CLI Overview (Confirmed)
- **Installation**: `npm install -g @openai/codex` or `codex --upgrade`
- **Launch Date**: April 2025 by OpenAI
- **Models Available**: o3, o3-mini, gpt-5 series (default: o4-mini)
- **Platform Support**: macOS/Linux official, Windows experimental (WSL)
- **Pricing**: $1M in API grants available, $25K blocks for eligible projects

### Authentication Options (Confirmed)
- **ChatGPT Sign-in**: Plus/Pro/Team accounts get model access included
- **API Key**: Pay-as-you-go via OpenAI API key environment variable
- **Config File**: `~/.codex/config.toml` for authentication preferences
- **Credits**: Plus users get $5, Pro users get $50 in API credits (30-day expiry)

### Architecture Patterns (From Existing Providers)
- **Provider Registration**: Auto-register via `provider_key()` class method
- **CLI Pattern**: Follow ClaudeCodeClient pattern with subprocess execution
- **Error Handling**: Detect CLI availability with `which codex`, auth via test command
- **Aliases**: Global and provider-specific aliases in llm-aliases.yml
- **Metadata**: Parse output for token counts, costs, execution time

### Implementation Confidence
- **High**: Provider registration, alias system, basic subprocess execution
- **Medium**: Authentication detection, model name mapping  
- **Low**: Command structure, output format, advanced features

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

### Validation Questions (Resolved Through Research)

- [x] **Provider Key Selection**: Should we use "codex" as the primary provider key?
  - **Resolution**: Use "codex" as primary provider key, following existing patterns
  - **Evidence**: Other CLI providers (cc, lmstudio) use descriptive names
  - **Implementation**: Follow ClaudeCodeClient pattern with auto-registration

- [x] **Architecture Pattern**: Should we extend BaseClient or BaseChatCompletionClient?
  - **Resolution**: Extend BaseClient directly like ClaudeCodeClient
  - **Evidence**: CLI providers bypass HTTP and need custom generate_text implementation
  - **Implementation**: Skip HTTP-based chat completion workflow

- [x] **Alias Configuration**: How should Codex aliases be configured?
  - **Resolution**: Add to .coding-agent/llm-aliases.yml following existing pattern  
  - **Evidence**: Found cc: aliases and global shortcuts already configured
  - **Implementation**: Add codex: provider aliases and global shortcuts

### Validation Questions (Resolved)

- [x] **Default Model**: Use gpt-5-mini as default
  - **Decision**: Default to `gpt-5-mini` for balance of speed and capability
  - **Implementation**: Set as DEFAULT_MODEL constant in CodexClient

- [x] **OSS Mode**: Create separate provider for open source models
  - **Decision**: Use `codexoss:` provider prefix for Ollama integration
  - **Implementation**: Create separate CodexOSSClient that uses `--oss` flag

- [x] **Sandbox Policy**: Use full access by default
  - **Decision**: Always use `danger-full-access` sandbox mode
  - **Rationale**: Codex only works in directories we explicitly allow
  - **Implementation**: No safety flags needed in llm-query for Codex

- [x] **Profile Support**: Skip profile support
  - **Decision**: No profile selection in v1
  - **Implementation**: Keep it simple, can add later if needed

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
- **Two Providers**: Separate `codex` and `codexoss` providers
- **Default Model**: Use `gpt-5-mini` as default for codex provider
- **Sandbox Mode**: Always use `-s danger-full-access` for full functionality
- **Error-First Design**: Comprehensive error handling for missing CLI, auth failures
- **Metadata Synthesis**: Create synthetic metadata when not available from CLI
- **Test-Driven**: Mock subprocess calls for reliable testing

## File Modifications

### Create
- `lib/coding_agent_tools/organisms/codex_client.rb`
  - Purpose: Codex CLI provider implementation (cloud models)
  - Key components: generate_text, uses `-s danger-full-access`, defaults to gpt-5-mini
  - Dependencies: BaseClient, Open3

- `lib/coding_agent_tools/organisms/codex_oss_client.rb`
  - Purpose: Codex OSS provider implementation (local Ollama)
  - Key components: generate_text with `--oss` flag, model discovery
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

- Codex CLI documentation: `codex --help` output (needed)
- Claude Code integration pattern: v.0.5.0+task.046 (analyzed)
- Existing provider implementations in .ace/tools (analyzed)
- User request for Codex CLI integration with llm-query
- OpenAI Codex CLI overview: https://help.openai.com/en/articles/11096431-openai-codex-cli-getting-started
- GitHub repository: https://github.com/openai/codex

## Review Summary

**Questions Generated:** 6 total (3 high, 2 medium, 1 low)

**Critical Blockers:** 
- Codex CLI command structure unknown (HIGH) - cannot implement without knowing exact commands
- Authentication method unclear (HIGH) - affects error handling and user guidance  
- Output format unknown (MEDIUM) - affects metadata extraction approach

**Implementation Readiness:** **Blocked on answers** - 3 HIGH priority questions must be resolved before implementation can begin

**Research Completed:**
- Codex CLI general capabilities and installation confirmed
- Authentication options documented (ChatGPT vs API key)
- Provider architecture patterns analyzed from ClaudeCodeClient
- Alias system patterns understood from existing configuration
- Model availability confirmed (o3, o3-mini, gpt-5 series)

**Recommended Next Steps:**
1. **Get actual Codex CLI help output** - `codex --help` to understand command structure
2. **Test authentication methods** - determine how to detect if user is authenticated
3. **Test model execution** - confirm exact syntax for non-interactive execution
4. **After questions answered** - proceed with implementation following ClaudeCodeClient pattern