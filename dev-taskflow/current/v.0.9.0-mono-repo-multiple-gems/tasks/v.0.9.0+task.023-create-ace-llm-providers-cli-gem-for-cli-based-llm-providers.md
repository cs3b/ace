---
id: v.0.9.0+task.023
status: pending
priority: high
estimate: 6h
dependencies: [v.0.9.0+task.021]
---

# Create ace-llm-providers-cli gem for CLI-based LLM providers

## Behavioral Specification

### User Experience
- **Input**: Users provide LLM provider/model selection for CLI-based tools (Claude Code, Codex, etc.) via the same ace-llm-query interface
- **Process**: Users experience seamless querying of CLI-based LLM providers through subprocess execution with proper error handling and authentication checks
- **Output**: Users receive LLM responses from CLI tools with the same formatting options as HTTP providers

### Expected Behavior
Users should be able to query LLM providers that are accessed through CLI tools (Claude Code via `claude` CLI, Codex via `codex` CLI, etc.) using the same unified ace-llm-query interface. The system should automatically detect if the CLI tool is installed and authenticated, provide clear error messages if setup is needed, and handle subprocess execution safely. The CLI providers should register dynamically when the ace-llm-providers-cli gem is installed, extending the base ace-llm functionality without requiring changes to the core gem.

### Interface Contract
```bash
# CLI Provider Interface (extends ace-llm-query)
ace-llm-query cc:opus <prompt> [options]          # Claude Code via CLI
ace-llm-query cc:sonnet <prompt> [options]        # Claude Code Sonnet
ace-llm-query codex:gpt-5 <prompt> [options]      # Codex via CLI
ace-llm-query codex:mini <prompt> [options]       # Codex Mini model
ace-llm-query opencode <prompt> [options]         # OpenCode CLI
ace-llm-query codex-oss <prompt> [options]        # Codex OSS

# Examples:
ace-llm-query cc:opus "Explain this Ruby pattern"
ace-llm-query codex:gpt-5 code.rb --system "Review for best practices"
ace-llm-query opencode "Generate unit tests" --output tests.rb

# All standard ace-llm-query options work:
--output, -o FILE       # Output to file
--format FORMAT         # Output format: text, json, markdown
--temperature FLOAT     # Generation temperature
--max-tokens INT        # Maximum output tokens
--system FILE_OR_TEXT   # System prompt
--timeout SECONDS       # Request timeout (applies to subprocess)
--force, -f             # Force overwrite
--debug, -d             # Enable debug output

# Provider-specific behavior:
# Shows CLI setup instructions if tool not found
# Shows authentication instructions if not authenticated
# Handles subprocess timeouts gracefully
```

**Error Handling:**
- CLI tool not found: Show installation instructions (e.g., "Install Claude Code: brew install --cask claude")
- Not authenticated: Show authentication steps (e.g., "Authenticate: claude login")
- Subprocess timeout: Respect --timeout with clear error message
- CLI tool error: Display tool's error output with context

**Edge Cases:**
- CLI tool updating in background: Retry logic with exponential backoff
- Large responses from CLI: Stream output to prevent memory issues
- Concurrent CLI calls: Handle process management safely
- CLI tool version incompatibility: Detect and warn about version issues

### Success Criteria
- [ ] **Behavioral Outcome 1**: All CLI providers accessible through ace-llm-query interface
- [ ] **User Experience Goal 2**: Automatic detection of CLI tool availability with helpful setup instructions
- [ ] **System Performance 3**: Subprocess execution with proper timeout and error handling
- [ ] **Plugin Architecture**: CLI providers register dynamically when gem is installed
- [ ] **Compatibility**: Works seamlessly with ace-llm core gem
- [ ] **Error Messages**: Clear, actionable error messages for setup and authentication

### Validation Questions
- [ ] **Requirement Clarity**: Should CLI providers support streaming output for long responses?
- [ ] **Edge Case Handling**: How should we handle CLI tools that require interactive authentication?
- [ ] **User Experience**: Should we cache CLI tool availability checks to improve performance?
- [ ] **Success Definition**: What timeout defaults make sense for CLI subprocess execution?

## Objective

Create a modular ace-llm-providers-cli gem that extends ace-llm with CLI-based LLM providers (Claude Code, Codex, OpenCode, etc.). This enables users to query LLMs accessed through CLI tools while maintaining the same interface and keeping the core ace-llm gem lightweight.

## Scope of Work

- **User Experience Scope**: Seamless integration of CLI-based providers into ace-llm-query workflow
- **System Behavior Scope**: Subprocess execution, CLI tool detection, authentication handling
- **Interface Scope**: Dynamic provider registration that extends ace-llm without modification

### Deliverables

#### Behavioral Specifications
- CLI provider integration specification
- Subprocess execution behavior
- Error handling and setup guidance
- Dynamic registration mechanism

#### Validation Artifacts
- CLI tool detection tests
- Subprocess execution tests
- Error handling validation
- Integration tests with ace-llm core

## Out of Scope

- ❌ **Implementation Details**: Specific subprocess optimization strategies
- ❌ **Technology Decisions**: Alternative IPC mechanisms beyond Open3
- ❌ **Performance Optimization**: CLI tool caching or preloading
- ❌ **Future Enhancements**: Native SDK replacements (separate future gem)
- ❌ **CLI Tool Installation**: Actual installation of CLI tools (only instructions)

## Technical Approach

### Architecture Pattern
- Plugin architecture that extends ace-llm dynamically
- Providers auto-register when gem is loaded
- Inherits from ace-llm base classes (BaseClient, etc.)
- Subprocess execution using Ruby stdlib Open3

### Technology Stack
- **Subprocess**: Open3 (Ruby stdlib) for CLI execution
- **Base Classes**: Provided by ace-llm gem
- **Error Handling**: Custom exceptions for CLI-specific errors
- **No external dependencies**: Only ace-llm and stdlib

### Implementation Strategy
- Create separate gem that depends on ace-llm
- Port CLI providers maintaining subprocess patterns
- Implement CLI detection and authentication checks
- Auto-registration on gem load

## File Modifications

### Create
- ace-llm-providers-cli/ (root directory for new gem)
  - Purpose: CLI provider extension gem
  - Key components: gemspec, lib/, test/
  - Dependencies: ace-llm ~> 0.9.0

- ace-llm-providers-cli/exe/ace-llm-providers-cli-check
  - Purpose: Utility to check CLI tool availability
  - Key components: Detection logic for all CLI tools
  - Dependencies: Shows setup instructions

- ace-llm-providers-cli/lib/ace/llm/providers/cli.rb
  - Purpose: Main entry point that registers providers
  - Key components: Provider registration logic
  - Dependencies: Requires individual provider files

- ace-llm-providers-cli/lib/ace/llm/providers/cli/claude_code_client.rb
  - Purpose: Claude Code CLI provider
  - Key components: Subprocess execution, model mapping
  - Dependencies: Open3, JSON parsing

- ace-llm-providers-cli/lib/ace/llm/providers/cli/codex_client.rb
  - Purpose: Codex CLI provider
  - Key components: Subprocess execution, GPT-5 models
  - Dependencies: Open3, JSON parsing

- ace-llm-providers-cli/lib/ace/llm/providers/cli/open_code_client.rb
  - Purpose: OpenCode CLI provider
  - Key components: Subprocess execution
  - Dependencies: Open3, JSON parsing

- ace-llm-providers-cli/lib/ace/llm/providers/cli/codex_oss_client.rb
  - Purpose: Codex OSS CLI provider
  - Key components: Open source codex integration
  - Dependencies: Open3, JSON parsing

### Modify
- None (new gem, no modifications to existing files)

### Delete
- None (dev-tools providers remain until migration validated)

## Risk Assessment

### Technical Risks
- **Risk:** CLI tools may change their interface
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Version detection and compatibility checks
  - **Rollback:** Pin to known working CLI versions

- **Risk:** Subprocess execution security concerns
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Strict input sanitization, no shell expansion
  - **Rollback:** Disable affected provider

### Integration Risks
- **Risk:** Dynamic registration may conflict with ace-llm core
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Namespace isolation, clear registration API
  - **Monitoring:** Integration tests between gems

## Implementation Plan

### Planning Steps

* [ ] Analyze CLI provider patterns in dev-tools
  - Review subprocess execution patterns
  - Understand authentication flows
  - Map CLI tool detection logic

* [ ] Design plugin registration mechanism
  - Plan auto-registration on gem load
  - Define provider namespace structure
  - Ensure compatibility with ace-llm core

* [ ] Plan CLI tool detection strategy
  - Design availability checks
  - Plan setup instruction generation
  - Define authentication verification

### Execution Steps

- [ ] Step 1: Create ace-llm-providers-cli gem scaffold
  - Create ace-llm-providers-cli directory
  - Create gemspec with ace-llm dependency
  - Setup standard gem structure
  > TEST: Gem Structure Validation
  > Type: Structure Check
  > Assert: ace-llm-providers-cli gem structure created
  > Command: ls -la ace-llm-providers-cli/ && cat ace-llm-providers-cli/ace-llm-providers-cli.gemspec

- [ ] Step 2: Create provider registration mechanism
  - Create lib/ace/llm/providers/cli.rb entry point
  - Implement auto-registration on require
  - Test with ace-llm ClientFactory
  > TEST: Registration Check
  > Type: Integration Test
  > Assert: Providers register when gem loaded
  > Command: ruby -e "require 'ace/llm'; require 'ace/llm/providers/cli'; puts Ace::LLM::ClientFactory.providers"

- [ ] Step 3: Port ClaudeCodeClient
  - Copy and adapt from dev-tools
  - Update namespace to Ace::LLM::Providers::CLI
  - Maintain subprocess execution logic
  > TEST: Claude Code Provider
  > Type: Provider Check
  > Assert: ClaudeCodeClient loads and registers
  > Command: ruby -e "require 'ace/llm/providers/cli'; p Ace::LLM::Providers::CLI::ClaudeCodeClient"

- [ ] Step 4: Port CodexClient
  - Migrate Codex CLI integration
  - Update model mappings (GPT-5, etc.)
  - Preserve authentication checks
  > TEST: Codex Provider
  > Type: Provider Check
  > Assert: CodexClient functional
  > Command: ls ace-llm-providers-cli/lib/ace/llm/providers/cli/codex_client.rb

- [ ] Step 5: Port remaining CLI providers
  - Port OpenCodeClient
  - Port CodexOSSClient
  - Ensure consistent error handling
  > TEST: All Providers Present
  > Type: Completeness Check
  > Assert: All 4 CLI providers migrated
  > Command: ls ace-llm-providers-cli/lib/ace/llm/providers/cli/*_client.rb | wc -l

- [ ] Step 6: Implement CLI detection utility
  - Create exe/ace-llm-providers-cli-check
  - Check each CLI tool availability
  - Provide setup instructions
  > TEST: Detection Utility
  > Type: Utility Check
  > Assert: Check command works
  > Command: ace-llm-providers-cli/exe/ace-llm-providers-cli-check

- [ ] Step 7: Add error handling
  - CLI not found exceptions
  - Authentication error handling
  - Subprocess timeout handling
  > TEST: Error Handling
  > Type: Exception Check
  > Assert: Proper error classes defined
  > Command: grep -r "class.*Error" ace-llm-providers-cli/lib/

- [ ] Step 8: Create integration tests
  - Test registration with ace-llm
  - Test subprocess execution safety
  - Test error scenarios
  > TEST: Integration Tests
  > Type: Test Suite
  > Assert: Tests pass
  > Command: cd ace-llm-providers-cli && bundle exec rspec

- [ ] Step 9: Documentation
  - Create README with setup instructions
  - Document each CLI provider
  - Add troubleshooting guide
  > TEST: Documentation Complete
  > Type: Documentation Check
  > Assert: README exists with setup info
  > Command: test -f ace-llm-providers-cli/README.md && grep -q "Setup" ace-llm-providers-cli/README.md

## Acceptance Criteria

- [ ] ace-llm-providers-cli gem created with proper structure
- [ ] All 4 CLI providers ported and functional
- [ ] Dynamic registration works with ace-llm core
- [ ] CLI tool detection with helpful setup messages
- [ ] Subprocess execution with proper timeout handling
- [ ] Clear error messages for missing/unauthenticated tools
- [ ] Integration tests pass
- [ ] Documentation complete

## References

- Current implementation: dev-tools/lib/coding_agent_tools/organisms/claude_code_client.rb
- Current implementation: dev-tools/lib/coding_agent_tools/organisms/codex_client.rb
- Dependency on: ace-llm gem (task.021)
- Uses: Ruby stdlib Open3 for subprocess execution
- Pattern: Plugin architecture for provider registration