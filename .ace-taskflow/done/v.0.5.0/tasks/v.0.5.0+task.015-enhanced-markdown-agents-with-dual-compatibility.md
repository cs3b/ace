---
id: v.0.5.0+task.015
status: done
priority: medium
estimate: 3d
dependencies: [013, 014]
---

# Enhanced Markdown Agents with Dual Compatibility

## Behavioral Specification

### User Experience
- **Input**: Agent invocation from Claude Code directly or via MCP proxy
- **Process**: Agent reads embedded context, executes with appropriate tools and model
- **Output**: Task completion with context-aware responses

### Expected Behavior
Markdown-based agents work seamlessly with both Claude Code (direct invocation) and MCP proxy (enhanced features). Agents contain embedded context definitions, tool restrictions, and optional MCP metadata for advanced routing and security when used through the proxy.

### Interface Contract

```markdown
# Agent Definition Format (.claude/agents/[name].md)
---
# Core metadata (both systems)
name: agent-name
description: When to use this agent
tools: [allowed-tools]  # Claude Code restrictions
last_modified: '2025-08-13'
type: agent

# MCP proxy enhancements (ignored by Claude)
mcp:
  model: provider:model  # Cost-optimized routing
  tools_mapping:
    tool-name:
      expose: true
      settings: ...
  resources: [...]  # MCP resources
  prompts: [...]    # MCP prompt templates
  security:
    allowed_paths: [...]
    rate_limit: ...

# Context configuration
context:
  auto_inject: true  # MCP auto-injection
  template: embedded # or external path
  cache_ttl: 300

# Model routing (MCP)
routing:
  complexity_threshold: simple|medium|complex
  fallback_model: ...
  escalation_model: ...
---

[Agent instructions in natural language...]

## Context Definition
```yaml
files:
  - relevant/files/*.md
commands:
  - relevant-command
format: markdown-xml
```

## Detailed Instructions
[Step-by-step guidance...]
```

**Error Handling:**
- Missing context: Gracefully degrade, use available information
- Tool unavailable: Report clearly, suggest alternatives
- Model routing failure: Fall back to default model

**Edge Cases:**
- Direct Claude invocation: Ignore MCP metadata, use core fields
- MCP proxy invocation: Apply all enhancements
- Unknown fields: Ignore without error

### Success Criteria
- [x] **Dual Compatibility**: 100% of agents work in both Claude and MCP proxy
- [x] **Context Efficiency**: 75% reduction in manual context loading
- [x] **Model Optimization**: Appropriate model selection per agent type
- [x] **Backward Compatible**: Existing agents work without modification
- [x] **Easy Creation**: New agents created in <5 minutes

### Validation Questions
- [x] **Agent Discovery**: How should agents be discovered and registered?
- [x] **Version Control**: Should agents have version numbers?
- [x] **Testing**: How to test agent behavior in both modes?
- [x] **Documentation**: Auto-generate docs from agent metadata?

## Objective

Create a unified agent format that works directly with Claude Code while enabling enhanced features (context injection, model routing, security) when used through the MCP proxy.

## Scope of Work

- **User Experience Scope**: Markdown agents with embedded context and dual compatibility
- **System Behavior Scope**: Agent parsing, context extraction, metadata processing
- **Interface Scope**: Markdown format with YAML frontmatter and embedded templates

### Deliverables

#### Behavioral Specifications
- Enhanced agent format specification
- Context embedding patterns
- Metadata structure for dual compatibility

#### Validation Artifacts
- Agent compatibility tests
- Context extraction validation
- Model routing verification

## Out of Scope

- ❌ **Implementation Details**: Agent parser implementation
- ❌ **Technology Decisions**: YAML parser library selection
- ❌ **Performance Optimization**: Agent caching strategies
- ❌ **Future Enhancements**: Agent versioning system

## References

- Existing agent: .claude/agents/git-commit-manager.md
- Original idea: .ace/taskflow/backlog/ideas/004-specialized-sub-agents.md
- MCP agent patterns: Industry best practices from 2025

## Implementation Plan

### Planning Steps

* [ ] Analyze existing git-commit-manager agent structure
* [ ] Design enhanced metadata schema for dual compatibility
* [ ] Research YAML frontmatter parsing in markdown
* [ ] Plan context embedding patterns
* [ ] Design agent discovery mechanism

### Execution Steps

#### 1. Define Enhanced Agent Format Specification

- [ ] Create agent template with full metadata
  ```markdown
  ---
  # Core fields (Claude Code compatible)
  name: agent-name
  description: When to use
  tools: [allowed-tools]
  
  # MCP enhancements (ignored by Claude)
  mcp:
    model: provider:model
    tools_mapping: {...}
    resources: [...]
    security: {...}
  
  # Context configuration
  context:
    template: embedded
    cache_ttl: 300
  ---
  
  Instructions...
  
  ## Context Definition
  ```yaml
  files: [...]
  commands: [...]
  ```
  ```

- [ ] Document metadata field specifications
  - Required vs optional fields
  - Field validation rules
  - Backward compatibility requirements

#### 2. Create Initial Enhanced Agents

- [ ] Enhance git-commit-manager agent
  - Add MCP metadata section
  - Embed context definition for recent commits
  - Specify model: google:gemini-2.5-flash
  > TEST: Git Agent Enhancement
  > Type: Manual Test
  > Assert: Agent works in Claude Code
  > Command: Manually invoke in Claude Code

- [ ] Create task-manager-agent.md
  ```markdown
  ---
  name: task-manager-agent
  description: Intelligent task management
  tools: [task-manager, nav-path, create-path]
  mcp:
    model: google:gemini-2.5-flash
    tools_mapping:
      task-manager:
        expose: true
        methods: [next, list, create]
  context:
    template: embedded
  ---
  
  You are a task management specialist...
  
  ## Context Definition
  ```yaml
  files:
    - .ace/taskflow/current/*/tasks/*.task.md
    - .ace/taskflow/backlog/**/*.md
  commands:
    - task-manager list
    - task-manager next
  ```
  ```

- [ ] Create search-agent.md
  - Smart code/file searching
  - Context: project structure, file lists
  - Model routing: start cheap, escalate if complex

- [ ] Create create-path-agent.md
  - File/directory creation with templates
  - Context: existing templates, structure
  - Security: path validation rules

- [ ] Create code-lint-agent.md
  - Automated linting and fixes
  - Context: lint configs, recent issues
  - Batch mode support

#### 3. Implement Agent Parsing Components

- [ ] Create `.ace/tools/lib/coding_agent_tools/molecules/agents/agent_parser.rb`
  - Parse markdown files with YAML frontmatter
  - Extract metadata sections
  - Validate agent structure

- [ ] Create `.ace/tools/lib/coding_agent_tools/molecules/agents/metadata_extractor.rb`
  - Extract core Claude fields
  - Extract MCP-specific metadata
  - Handle missing/unknown fields gracefully

- [ ] Create `.ace/tools/lib/coding_agent_tools/molecules/agents/context_definition_parser.rb`
  - Find Context Definition section
  - Extract embedded YAML
  - Support external template references

#### 4. Integrate with Context Tool (from Task 013)

- [ ] Add agent context extraction to context tool
  ```bash
  context --from-agent .claude/agents/task-manager.md
  ```

- [ ] Support embedded context definitions
  - Parse Context Definition section
  - Convert to context template
  - Execute with context tool

- [ ] Handle external context templates
  - Resolve template paths
  - Load and execute templates

#### 5. Integrate with MCP Proxy (from Task 014)

- [ ] Add agent discovery to MCP proxy
  - Scan .claude/agents/ directory
  - Parse agent metadata
  - Register as MCP resources

- [ ] Implement agent-specific routing
  - Read mcp.model from metadata
  - Apply routing rules
  - Handle fallback models

- [ ] Apply agent security rules
  - Read mcp.security section
  - Enforce path restrictions
  - Apply rate limiting

- [ ] Auto-inject agent context
  - Check context.auto_inject flag
  - Load context using context tool
  - Inject into agent invocation

#### 6. Create Agent Management Tools

- [ ] Create `handbook agent list` command
  - List all available agents
  - Show compatibility status
  - Display metadata summary

- [ ] Create `handbook agent validate` command
  - Validate agent format
  - Check metadata completeness
  - Verify context definitions

- [ ] Create `handbook agent generate` command
  - Generate new agent from template
  - Interactive agent creation
  - Metadata wizard

#### 7. Testing and Validation

- [ ] Create agent parsing tests
  - Test metadata extraction
  - Test context parsing
  - Test error handling

- [ ] Create dual compatibility tests
  - Verify Claude Code compatibility
  - Test MCP proxy enhancements
  - Ensure graceful degradation

- [ ] Create integration tests
  - Test agent discovery
  - Test context injection
  - Test model routing

- [ ] Manual compatibility testing
  - Test each agent in Claude Code
  - Test through MCP proxy
  - Document any issues

#### 8. Documentation

- [ ] Create agent authoring guide
  - Metadata field reference
  - Context embedding patterns
  - Best practices

- [ ] Document dual compatibility
  - How fields are used by each system
  - Graceful degradation behavior
  - Enhancement opportunities

- [ ] Add examples to docs/
  - Sample agents for different use cases
  - Migration guide for existing agents
  - Troubleshooting guide

### Risk Analysis

**Technical Risks:**
- Breaking existing Claude agents (mitigated by backward compatibility)
- Complex metadata parsing (mitigated by validation)
- Context extraction failures (mitigated by error handling)

**Rollback Strategy:**
- Enhanced metadata is optional
- Existing agents continue working
- Can remove MCP sections without impact

**Performance Impact:**
- Agent parsing overhead minimal
- Context caching reduces repeated loads
- Metadata validation fast