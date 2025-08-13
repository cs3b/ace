---
id: 014
status: pending
priority: high
estimate: 5d
dependencies: [013]
---

# MCP Proxy Server for Tool Gateway

## Behavioral Specification

### User Experience
- **Input**: MCP client connections (Claude Code, OpenCode, Codex), tool requests, agent invocations
- **Process**: Request validation, tool exposure control, context injection, model routing
- **Output**: MCP-compliant responses with tool results, resources, and prompts

### Expected Behavior
The MCP proxy acts as an intelligent gateway between MCP clients and our dev-tools, providing security, cost optimization, and context enhancement. It selectively exposes tools, automatically injects project context, routes requests to appropriate models, and maintains compatibility with all MCP clients.

### Interface Contract

```bash
# Server Startup
mcp-proxy --port 3000 --config proxy-config.yaml
mcp-proxy --stdio  # For local Claude Desktop integration

# Configuration Format (YAML)
tools:
  expose:
    - git-status
    - git-commit: 
        require_confirmation: true
    - task-manager:
        methods: [list, next, create]
  
security:
  allowed_paths: [dev-taskflow/**, docs/**]
  forbidden_paths: [.env, secrets/**, *.key]
  rate_limit: 100/hour

routing:
  default_model: google:gemini-2.5-flash
  complex_tasks: anthropic:claude-3-5-sonnet

agents:
  directory: .claude/agents/
  auto_discover: true

# MCP Protocol Endpoints
/tools          # List available tools
/tools/invoke   # Execute tool with parameters
/resources      # List available resources
/prompts        # List available prompts
/completion     # Handle completion requests
```

**Error Handling:**
- Unauthorized tool access: Return MCP error with security message
- Rate limit exceeded: Return 429 with retry-after header
- Invalid paths: Sanitize and reject with clear error
- Model unavailable: Fallback to configured alternative

**Edge Cases:**
- Multiple concurrent clients: Handle with connection pooling
- Large responses: Stream using SSE/chunked transfer
- Client disconnection: Clean up resources gracefully

### Success Criteria
- [ ] **Universal Compatibility**: Works with Claude Code, OpenCode, Codex CLI
- [ ] **Security Enforcement**: Zero unauthorized tool executions
- [ ] **Cost Optimization**: 60% reduction via smart model routing
- [ ] **Context Enhancement**: Auto-inject relevant project context
- [ ] **Performance**: <100ms overhead for tool invocation

### Validation Questions
- [ ] **Authentication**: Should we require API keys for proxy access?
- [ ] **Persistence**: Should proxy maintain session state between requests?
- [ ] **Monitoring**: What metrics should be tracked and exposed?
- [ ] **Deployment**: Local-only or support remote deployment?

## Objective

Create a secure, intelligent gateway that bridges MCP clients with our dev-tools ecosystem, providing enhanced security, cost optimization, and context awareness while maintaining full MCP protocol compatibility.

## Scope of Work

- **User Experience Scope**: Transparent proxy for MCP clients with enhanced capabilities
- **System Behavior Scope**: Tool wrapping, request routing, context injection, security validation
- **Interface Scope**: MCP protocol server with HTTP/SSE/stdio transports

### Deliverables

#### Behavioral Specifications
- MCP protocol implementation
- Tool exposure configuration
- Security and rate limiting rules

#### Validation Artifacts
- Compatibility tests with multiple MCP clients
- Security validation scenarios
- Performance benchmarks

## Out of Scope

- ❌ **Implementation Details**: Specific HTTP server framework
- ❌ **Technology Decisions**: Ruby vs other languages for proxy
- ❌ **Performance Optimization**: Specific caching strategies
- ❌ **Future Enhancements**: Custom MCP protocol extensions

## References

- MCP Protocol Specification: modelcontextprotocol.io
- Original idea: dev-taskflow/backlog/ideas/002-cheap-model-delegation.md
- Existing proxies: sparfenyuk/mcp-proxy, open-webui/mcpo

## Implementation Plan

### Planning Steps

* [ ] Research MCP protocol specification and transport options (stdio, HTTP/SSE)
* [ ] Analyze existing MCP proxy implementations for patterns
* [ ] Design tool wrapping strategy for dev-tools executables
* [ ] Research Ruby HTTP server options (Rack, Sinatra, Puma)
* [ ] Investigate SSE implementation for streaming responses
* [ ] Design security layer architecture and validation rules

### Execution Steps

#### 1. Create MCP Proxy Executable and Core Structure

- [ ] Create `dev-tools/exe/mcp-proxy` executable
  ```ruby
  #!/usr/bin/env ruby
  require_relative "../lib/coding_agent_tools"
  CodingAgentTools::CLI.start(ARGV)
  ```

- [ ] Create `dev-tools/lib/coding_agent_tools/cli/commands/mcp_proxy.rb`
  - Define CLI options: --port, --stdio, --config
  - Initialize appropriate transport (HTTP or stdio)
  - Start proxy server

#### 2. Implement MCP Protocol Core

- [ ] Create `dev-tools/lib/coding_agent_tools/atoms/mcp/protocol_validator.rb`
  - Validate MCP message format
  - Check required fields
  - Verify protocol version

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/message_handler.rb`
  - Parse incoming MCP messages
  - Route to appropriate handlers
  - Format MCP responses

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/tool_wrapper.rb`
  - Wrap dev-tools executables as MCP tools
  - Map tool parameters to CLI arguments
  - Capture and format tool output

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/resource_provider.rb`
  - Define available resources
  - Handle resource queries
  - Format resource responses

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/prompt_manager.rb`
  - Manage prompt templates
  - Handle prompt invocations
  - Variable substitution

#### 3. Implement Transport Layers

- [ ] Create `dev-tools/lib/coding_agent_tools/organisms/mcp/http_transport.rb`
  - HTTP server setup (using Rack/Sinatra)
  - SSE endpoint for streaming
  - Request/response handling
  > TEST: HTTP Transport
  > Type: Integration Test
  > Assert: Server responds to MCP requests
  > Command: curl -X POST localhost:3000/tools -d '{"jsonrpc":"2.0","method":"tools/list"}'

- [ ] Create `dev-tools/lib/coding_agent_tools/organisms/mcp/stdio_transport.rb`
  - Stdio message reading
  - JSON-RPC over stdio
  - Compatible with Claude Desktop

#### 4. Implement Security and Routing

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/security_validator.rb`
  - Path validation and sanitization
  - Tool access control
  - Rate limiting implementation
  > TEST: Security Validation
  > Type: Unit Test
  > Assert: Forbidden paths rejected
  > Command: rspec spec/unit/molecules/mcp/security_validator_spec.rb

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/model_router.rb`
  - Route requests to appropriate models
  - Cost optimization logic
  - Fallback handling

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/context_injector.rb`
  - Auto-inject project context
  - Use context tool from task 013
  - Agent-specific context loading

#### 5. Implement Tool Exposure Configuration

- [ ] Create configuration parser
  ```yaml
  tools:
    expose:
      - git-status
      - git-commit:
          require_confirmation: true
      - task-manager:
          methods: [list, next]
  ```

- [ ] Map configuration to tool availability
  - Selective method exposure
  - Parameter validation
  - Output filtering

#### 6. Implement Agent Discovery and Loading

- [ ] Create `dev-tools/lib/coding_agent_tools/molecules/mcp/agent_discoverer.rb`
  - Scan .claude/agents/ directory
  - Parse agent metadata
  - Extract MCP-specific configuration

- [ ] Integrate agents as MCP resources
  - Expose agents as invocable resources
  - Handle agent-specific context
  - Apply routing rules from metadata

#### 7. Implement MCP Endpoints

- [ ] `/tools` - List available tools
  ```json
  {
    "tools": [
      {
        "name": "git-status",
        "description": "Show git repository status",
        "parameters": {...}
      }
    ]
  }
  ```

- [ ] `/tools/invoke` - Execute tool
  - Validate parameters
  - Execute tool via wrapper
  - Return formatted result

- [ ] `/resources` - List resources
  - Include discovered agents
  - Dynamic resources from config

- [ ] `/prompts` - List prompts
  - Agent-specific prompts
  - Template prompts

- [ ] `/completion` - Handle completions
  - Route to appropriate model
  - Apply context injection

#### 8. Testing Implementation

- [ ] Create protocol compliance tests
  - MCP message format validation
  - Protocol version compatibility

- [ ] Create transport tests
  - HTTP endpoint tests
  - Stdio communication tests
  - SSE streaming tests

- [ ] Create security tests
  - Path traversal prevention
  - Rate limiting verification
  - Access control validation

- [ ] Create integration tests
  - Full proxy flow with tool execution
  - Multi-client handling
  - Agent invocation through proxy

- [ ] Create compatibility tests
  - Test with Claude Code simulator
  - Verify OpenCode compatibility
  - Test with MCP test client

#### 9. Documentation and Configuration

- [ ] Create proxy configuration examples
  - Tool exposure configs
  - Security rules
  - Model routing rules

- [ ] Document MCP endpoint specifications
- [ ] Create integration guide for Claude Code
- [ ] Add examples to docs/tools.md

### Risk Analysis

**Technical Risks:**
- MCP protocol compatibility (mitigated by following spec closely)
- Multi-client concurrency (mitigated by proper server architecture)
- Security vulnerabilities (mitigated by validation layers)

**Rollback Strategy:**
- Proxy is optional layer, direct tool access remains
- Can disable proxy without affecting tools
- Configuration-based, easy to modify

**Performance Impact:**
- <100ms overhead target for tool invocation
- Connection pooling for efficiency
- Caching where appropriate