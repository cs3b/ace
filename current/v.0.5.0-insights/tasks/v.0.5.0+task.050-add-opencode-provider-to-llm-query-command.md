---
id: v.0.5.0+task.050
status: draft
priority: high
estimate: TBD
dependencies: []
---

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

- [ ] **Provider Recognition**: `llm-query oc:anthropic/claude "test"` executes without "unknown provider" error
- [ ] **OpenCode CLI Execution**: System successfully invokes `opencode run` with correct parameters
- [ ] **Model Discovery**: `llm-models --provider oc` lists available models from OpenCode
- [ ] **Output Formatting**: Text output works consistently with other providers
- [ ] **Error Messages**: Clear, actionable error messages when OpenCode CLI is missing or auth fails
- [ ] **Alias Support**: Short aliases (opencode, oc:claude) work as expected
- [ ] **Session Management**: --continue and --session flags map correctly to OpenCode
- [ ] **Multi-Provider Support**: Correctly handles provider/model format for different AI providers

### Validation Questions

- [ ] **Default Model**: How to determine default model when user just types `opencode`?
- [ ] **Model Aliases**: Should we create shortcuts for common models (e.g., oc:claude → anthropic/claude-3-5-sonnet)?
- [ ] **Agent Integration**: Should we expose OpenCode's agent functionality through llm-query?
- [ ] **Session Persistence**: How to handle session IDs between llm-query and OpenCode?
- [ ] **Provider Parsing**: How to handle models that don't follow provider/model format?

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

## References

- OpenCode CLI documentation: `opencode --help` output
- SST OpenCode repository: https://github.com/sst/opencode
- Claude Code integration pattern: v.0.5.0+task.046
- Existing provider implementations in dev-tools
- User request for OpenCode integration with llm-query