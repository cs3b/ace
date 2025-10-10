# mcp-proxy - MCP Protocol Proxy Server

## Overview

`mcp-proxy` is a Model Context Protocol (MCP) proxy server that exposes ACE development tools as MCP-compatible resources. It provides both HTTP and stdio transports, security validation, tool wrapping, and routing capabilities for AI assistant integration.

## Purpose

The tool was created to:
- Enable MCP protocol support for ACE development tools
- Provide secure, controlled access to CLI tools via MCP
- Support both HTTP (server mode) and stdio (Claude Desktop) transports
- Implement security validation and rate limiting
- Route requests to appropriate LLM models
- Auto-discover and expose agent definitions

## Location

- **Executable**: `/dev-tools/exe/mcp-proxy`
- **Command Implementation**: `/dev-tools/lib/coding_agent_tools/cli/commands/mcp_proxy.rb`
- **Proxy Organism**: `/dev-tools/lib/coding_agent_tools/organisms/mcp/proxy_server.rb`
- **Supporting Molecules**:
  - `SecurityValidator`: Security validation and rate limiting
  - `ToolWrapper`: Wrap CLI tools for MCP protocol
  - `MessageHandler`: Handle MCP protocol messages
- **Transports**:
  - `HttpTransport`: HTTP server for network access
  - `StdioTransport`: Stdio for Claude Desktop integration

## API Reference

### Command

```bash
mcp-proxy [options]
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--port` | integer | 3000 | Port to bind HTTP server |
| `--host` | string | localhost | Host to bind HTTP server |
| `--stdio` | boolean | false | Use stdio transport instead of HTTP |
| `--config` | string | - | Configuration file path (YAML or JSON) |
| `--verbose` | boolean | false | Enable verbose logging |

### Transport Modes

#### HTTP Mode (Default)
```bash
# Start HTTP server on default port
mcp-proxy

# Custom port and host
mcp-proxy --port 8080 --host 0.0.0.0

# With configuration
mcp-proxy --port 3000 --config mcp-config.yml
```

#### Stdio Mode (Claude Desktop)
```bash
# Use stdio transport for Claude Desktop integration
mcp-proxy --stdio

# With custom configuration
mcp-proxy --stdio --config claude-mcp.yml
```

## How It Works

### Architecture (ATOM Pattern)

#### Atoms
- **ConfigLoader**: Load and parse configuration files
- **PathValidator**: Validate file paths against security rules
- **RateLimiter**: Enforce rate limits on tool usage
- **CommandParser**: Parse CLI tool commands

#### Molecules
- **SecurityValidator**: Security validation orchestration
  - Path validation (allowed/forbidden)
  - Rate limiting enforcement
  - Permission checking

- **ToolWrapper**: CLI tool wrapping for MCP
  - Wrap ACE tools as MCP resources
  - Transform CLI output to MCP format
  - Handle tool errors and validation

- **MessageHandler**: MCP protocol message handling
  - Parse MCP protocol messages
  - Route to appropriate tools
  - Format responses

#### Organisms
- **ProxyServer**: Main proxy orchestration
  - Configuration management
  - Component initialization
  - Transport setup
  - Validation

- **HttpTransport**: HTTP server implementation
  - HTTP request handling
  - MCP protocol over HTTP
  - Connection management

- **StdioTransport**: Stdio implementation
  - Stdio protocol handling
  - Claude Desktop compatibility
  - Message framing

### Execution Flow

```
MCP Client (Claude Desktop, etc.)
        ↓
Transport (HTTP or Stdio)
        ↓
MessageHandler (parse MCP protocol)
        ↓
SecurityValidator (validate request)
        ↓
ToolWrapper (wrap ACE tool)
        ↓
CLI Tool Execution (ace-taskflow, etc.)
        ↓
Response Formatting (MCP protocol)
        ↓
Transport (send response)
        ↓
MCP Client
```

### Security Layers

1. **Path Validation**:
   - Allowed paths: Whitelist of accessible directories
   - Forbidden paths: Blacklist of restricted files/patterns
   - Pattern matching: Glob pattern support

2. **Rate Limiting**:
   - Configurable limits: N requests per time unit
   - Time units: second, minute, hour, day
   - Per-tool limits: Different limits for different tools

3. **Tool Permissions**:
   - Exposed tools: Explicitly listed tools
   - Confirmation required: Tools requiring user confirmation
   - Method restrictions: Limited methods for specific tools

### Default Configuration

```yaml
tools:
  expose:
    git-status: true
    git-commit:
      require_confirmation: true
    task-manager:
      methods:
        - list
        - next
        - create
    nav-ls: true
    nav-tree: true
    context: true
    llm-query:
      require_confirmation: false

security:
  allowed_paths:
    - "dev-taskflow/**"
    - "docs/**"
    - "dev-handbook/**"
  forbidden_paths:
    - ".env"
    - "secrets/**"
    - "*.key"
    - "*.pem"
  rate_limit: "100/hour"

routing:
  default_model: "google:gemini-2.5-flash"
  complex_tasks: "anthropic:claude-3-5-sonnet"

agents:
  directory: ".claude/agents/"
  auto_discover: true
```

## Configuration

### Configuration File Format

#### YAML Format
```yaml
# mcp-config.yml
tools:
  expose:
    # Simple tool exposure
    git-status: true

    # Tool with confirmation requirement
    git-commit:
      require_confirmation: true

    # Tool with method restrictions
    task-manager:
      methods:
        - list
        - next
        - create

security:
  # Allowed file paths (glob patterns)
  allowed_paths:
    - "dev-taskflow/**"
    - "docs/**"
    - ".ace-taskflow/**"

  # Forbidden file paths (glob patterns)
  forbidden_paths:
    - ".env"
    - "secrets/**"
    - "*.key"
    - "*.pem"
    - ".ssh/**"

  # Rate limiting (N/unit)
  rate_limit: "100/hour"

routing:
  # Default model for simple queries
  default_model: "google:gemini-2.5-flash"

  # Model for complex tasks
  complex_tasks: "anthropic:claude-3-5-sonnet"

agents:
  # Agent directory for auto-discovery
  directory: ".claude/agents/"

  # Auto-discover agents on startup
  auto_discover: true
```

#### JSON Format
```json
{
  "tools": {
    "expose": {
      "git-status": true,
      "git-commit": {
        "require_confirmation": true
      },
      "task-manager": {
        "methods": ["list", "next", "create"]
      }
    }
  },
  "security": {
    "allowed_paths": ["dev-taskflow/**", "docs/**"],
    "forbidden_paths": [".env", "secrets/**"],
    "rate_limit": "100/hour"
  },
  "routing": {
    "default_model": "google:gemini-2.5-flash",
    "complex_tasks": "anthropic:claude-3-5-sonnet"
  }
}
```

### Configuration Loading

1. Custom config via `--config` flag
2. Default embedded configuration (if no config provided)

### Configuration Validation

The proxy validates configuration on startup:

- **Tools**: Expose config must be a hash
- **Security**: Rate limit format must be `N/unit`
- **Routing**: Default model must be a string

Invalid configuration prevents server startup with detailed error messages.

## Usage Examples

### HTTP Server Mode

```bash
# Start on default port (3000)
mcp-proxy

# Custom port
mcp-proxy --port 8080

# Bind to all interfaces
mcp-proxy --host 0.0.0.0 --port 3000

# With configuration
mcp-proxy --config mcp-config.yml

# Verbose logging
mcp-proxy --verbose
```

### Stdio Mode (Claude Desktop)

```bash
# For Claude Desktop integration
mcp-proxy --stdio

# With custom config
mcp-proxy --stdio --config claude-mcp.yml

# Verbose stdio mode (logs to stderr)
mcp-proxy --stdio --verbose
```

### Claude Desktop Configuration

Add to Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "ace-tools": {
      "command": "/path/to/mcp-proxy",
      "args": ["--stdio", "--config", "/path/to/mcp-config.yml"]
    }
  }
}
```

## Output Examples

### HTTP Mode Startup
```
Starting MCP Proxy Server
Using HTTP transport on localhost:3000
Configuration: {
  :exposed_tools => ["git-status", "git-commit", "task-manager", "nav-ls", "nav-tree", "context", "llm-query"],
  :security => {
    :rate_limit => "100/hour",
    :allowed_paths => 3,
    :forbidden_paths => 4
  },
  :routing => {
    :default_model => "google:gemini-2.5-flash"
  }
}
MCP Proxy Server listening on http://localhost:3000
```

### Stdio Mode Startup
```
Starting MCP Proxy Server
Using stdio transport
Configuration: {...}
MCP Proxy Server ready (stdio mode)
```

### Request Handling (Verbose)
```
[DEBUG] Received MCP request: tools/list
[DEBUG] Security check: PASSED
[DEBUG] Tool wrapper: Executing git-status
[DEBUG] Tool output: On branch main...
[DEBUG] Response formatted: MCP protocol
[INFO] Request completed: tools/list (120ms)
```

### Security Violation
```
[WARN] Security violation: Path access denied
[WARN] Requested path: /Users/mc/.env
[WARN] Reason: Matches forbidden pattern: .env
[ERROR] Request rejected: security_violation
```

## Integration with ace-* Architecture

### Current Status

`mcp-proxy` is a **specialized integration server within dev-tools** that bridges ACE tools with MCP protocol clients.

### Migration Path: ace-mcp-server

Create dedicated MCP integration gem:

```ruby
# Future: ace-mcp-server gem structure
ace-mcp-server/
├── lib/ace/mcp_server/
│   ├── atoms/
│   │   ├── config_loader.rb
│   │   ├── path_validator.rb
│   │   ├── rate_limiter.rb
│   │   └── command_parser.rb
│   ├── molecules/
│   │   ├── security_validator.rb
│   │   ├── tool_wrapper.rb
│   │   └── message_handler.rb
│   ├── organisms/
│   │   ├── proxy_server.rb
│   │   ├── http_transport.rb
│   │   └── stdio_transport.rb
│   └── models/
│       ├── mcp_request.rb
│       ├── mcp_response.rb
│       └── tool_config.rb
├── exe/
│   └── ace-mcp-server
└── test/
    ├── atoms/
    ├── molecules/
    └── organisms/
```

### Future CLI Interface

```bash
# Start MCP server
ace-mcp-server

# Stdio mode for Claude Desktop
ace-mcp-server --stdio

# Custom configuration
ace-mcp-server --config mcp-config.yml

# Management commands
ace-mcp-server tools list           # List exposed tools
ace-mcp-server tools add [name]     # Add tool to exposure
ace-mcp-server config validate      # Validate configuration
ace-mcp-server status               # Server status
```

### Integration Points

#### With ACE Tools
MCP proxy wraps existing ACE tools:

```bash
# Exposed via MCP:
ace-taskflow task next    → MCP: task-manager.next
ace-git-commit            → MCP: git-commit
ace-nav ls                → MCP: nav-ls
ace-context project       → MCP: context.project
```

#### With Claude Desktop
Direct integration via stdio transport:

```json
{
  "mcpServers": {
    "ace": {
      "command": "ace-mcp-server",
      "args": ["--stdio"]
    }
  }
}
```

#### With Custom MCP Clients
HTTP transport for custom clients:

```javascript
// Custom MCP client
const client = new MCPClient('http://localhost:3000');
const tasks = await client.call('task-manager.list');
```

## Exit Codes

- `0` - Server started successfully
- `1` - Configuration error or startup failure

## Limitations

1. **Tool Coverage**: Not all ACE tools are exposed (manual configuration required)
2. **Security Model**: Basic path-based security, no fine-grained permissions
3. **Rate Limiting**: Simple time-based limiting, no sophisticated throttling
4. **Protocol Support**: MCP only, no support for other protocols
5. **Agent Enhancement**: Agent MCP metadata not fully utilized
6. **Routing**: Basic model routing, no load balancing or failover

## Future Enhancements

### For ace-mcp-server Migration

1. **Auto-discovery**:
   - Automatically discover ACE tools
   - Generate MCP tool definitions
   - Dynamic tool registration

2. **Enhanced Security**:
   - Role-based access control (RBAC)
   - OAuth/API key authentication
   - Audit logging
   - Encrypted communication

3. **Advanced Routing**:
   - Load balancing across models
   - Failover support
   - Cost-based routing
   - Latency-aware routing

4. **Protocol Support**:
   - OpenAPI/REST fallback
   - GraphQL support
   - gRPC support
   - WebSocket streaming

5. **Monitoring & Observability**:
   - Prometheus metrics
   - Health checks
   - Performance monitoring
   - Request tracing

6. **Agent Integration**:
   - Use agent MCP metadata
   - Auto-configure from agent files
   - Agent-specific security rules

## Related Tools

- **Claude Desktop**: Primary MCP client
- **ACE Tools**: Wrapped tools (ace-taskflow, ace-git-commit, etc.)
- **agent-lint**: Validates agent MCP metadata
- **ace-nav**: Could provide MCP resource discovery

## MCP Protocol

### What is MCP?

Model Context Protocol (MCP) is a standardized protocol for AI assistants to interact with external tools and resources.

**Key Concepts**:
- **Resources**: Files, data, APIs exposed to AI
- **Tools**: Executable operations (CLI commands)
- **Prompts**: Pre-defined interaction patterns
- **Transports**: HTTP, stdio, WebSocket

### MCP Messages

**Tool List Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/list",
  "id": 1
}
```

**Tool Call Request**:
```json
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "task-manager",
    "arguments": {
      "action": "list"
    }
  },
  "id": 2
}
```

**Response**:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "content": [
      {
        "type": "text",
        "text": "v.0.9.0: 3/47 tasks..."
      }
    ]
  },
  "id": 2
}
```

## Historical Context

Developed to provide MCP protocol support for ACE tools:

1. **Phase 1**: Claude Code direct integration (native tools)
2. **Phase 2**: MCP proxy for broader AI assistant support
3. **Phase 3**: Enhanced agent metadata for MCP configuration
4. **Phase 4** (Future): Standardized MCP server gem

The dual-transport design (HTTP + stdio) emerged from supporting both Claude Desktop (stdio) and custom MCP clients (HTTP).

## Migration Timeline

- **Current**: Available as `mcp-proxy` in dev-tools
- **v0.10.0**: Begin extraction to `ace-mcp-server` gem
- **v0.11.0**: Enhanced security and routing features
- **v0.12.0**: Deprecation warning for `mcp-proxy`
- **v1.0.0**: Remove from dev-tools, use `ace-mcp-server`

## See Also

- MCP Specification: https://modelcontextprotocol.io/
- Claude Desktop: https://claude.ai/download
- Agent MCP metadata: `docs/agent-lint.md`
- ACE tools: `docs/tools.md`
- Security considerations: `docs/security.md`
