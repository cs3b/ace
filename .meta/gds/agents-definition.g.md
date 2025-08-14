# Writing Agent Definitions

This guide outlines best practices for creating and maintaining agent definitions located within the `.claude/agents/` directory. These agents serve as specialized task handlers that can be invoked directly by Claude Code or enhanced through the MCP proxy system.

## Goal of Agents

The primary goal of agents is to:
- Provide specialized, context-aware assistance for specific development tasks
- Minimize context window usage through efficient data loading strategies
- Enable both direct Claude Code usage and enhanced MCP proxy features
- Standardize task execution patterns across different domains
- Facilitate autonomous operation with minimal human intervention

## File Naming Convention

All agent files must use the `.ag.md` suffix to distinguish them from other documentation types. This convention enables proper identification and tooling support.

### Naming Pattern
- **Format:** `<agent-name>.ag.md`
- **Style:** Use descriptive names that indicate the agent's primary function
- **Examples:**
  - `git-commit.ag.md` (not `git-commit-manager.md`)
  - `task-manager.ag.md` (not `task-manager-agent.md`)
  - `code-review.ag.md` (not `code-reviewer.md`)
  - `search.ag.md` (not `search-agent.md`)

### File Type Suffixes
The project uses consistent suffixes to identify different content types:
- **`.ag.md`** - Agent definitions (this guide)
- **`.g.md`** - Development guides
- **`.wf.md`** - Workflow instructions
- **`.md`** - General documentation

This naming distinction helps both humans and tools quickly identify agent definitions versus other documentation types.

## Core Principles

### 1. Start Minimal
**Principle:** Agents don't need all data, just enough to make informed decisions.

**Implementation:**
- Load metadata instead of full file contents when possible
- Use command outputs over file reading
- Start with 5-6 essential commands maximum
- Add complexity only based on actual usage patterns

**Example from task-manager-agent:**
```yaml
# Minimal context - just commands, no file content
commands:
  - release-manager current
  - task-manager list
  - task-manager next --limit 5
```

### 2. Dynamic Discovery Over Hard-Coded Values
**Principle:** Use commands to discover current state rather than embedding static paths.

**Implementation:**
- Query for current release/branch/status dynamically
- Use relative paths resolved at runtime
- Leverage existing tools for navigation
- Avoid hard-coding version numbers or release names

**Example:**
```bash
# Good: Dynamic discovery
release-manager current  # Discovers current release

# Bad: Hard-coded path
cd dev-taskflow/current/v.0.5.0-insights/  # Version will change
```

### 3. Work at Metadata Level
**Principle:** Operate on file lists and metadata rather than loading full content.

**Implementation:**
- Use file listings to understand structure
- Extract metadata from filenames and paths
- Load content only when transformation is needed
- Batch metadata operations for efficiency

### 4. Research Before Designing
**Principle:** Analyze actual usage patterns before creating agent workflows.

**Implementation:**
- Study how humans perform the task
- Identify common command sequences
- Document discovered patterns
- Test with real scenarios

### 5. Single Source of Truth
**Principle:** Maintain agents in one canonical location with clear versioning.

**Implementation:**
- All agents in `.claude/agents/` directory
- Use `last_modified` field for versioning
- Document migration paths for updates
- Avoid duplicate agent definitions

## Agent Format Specification

### File Structure
Agents use Markdown with YAML frontmatter for metadata and embedded context definitions.

```markdown
---
# Core metadata (required for all agents)
name: agent-name
description: When to use this agent (clear, specific triggers)
tools: [list, of, allowed, tools]
last_modified: 'YYYY-MM-DD'
type: agent

# MCP proxy enhancements (optional, ignored by Claude Code)
mcp:
  model: provider:model-name
  tools_mapping:
    tool-name:
      expose: true
      methods: [allowed, methods]
  resources: [mcp, resources]
  prompts: [prompt, templates]
  security:
    allowed_paths: [path, patterns]
    rate_limit: requests/hour

# Context configuration
context:
  auto_inject: true|false
  template: embedded|path/to/template
  cache_ttl: seconds
---

# Agent Instructions

Natural language instructions for the agent...

## Context Definition

```yaml
files:
  - path/patterns/*.md
commands:
  - command-to-execute
  - another-command --with-flags
format: markdown-xml
```
```

### Metadata Fields

#### Required Fields
- **name**: Unique identifier for the agent (kebab-case)
- **description**: Clear description of when to use this agent
- **tools**: Comma-separated list of Claude Code tools (e.g., `Bash, Read, Edit`)
  - Note: Custom executables must be called through `Bash`, not listed directly
  - Format: `tools: Bash, Read` (comma-separated, no brackets)
  - Omit entirely to inherit all tools from main thread
- **last_modified**: ISO date of last significant update
- **type**: Always "agent" for agent definitions

#### Optional MCP Fields
- **mcp.model**: Preferred model for this agent's tasks
- **mcp.tools_mapping**: Fine-grained tool access control
- **mcp.security**: Path restrictions and rate limiting
- **mcp.resources**: MCP-specific resources
- **mcp.prompts**: Reusable prompt templates

#### Context Configuration
- **context.auto_inject**: Whether to auto-load context
- **context.template**: Location of context template
- **context.cache_ttl**: Cache duration in seconds

## Context Optimization Strategies

### 1. Command-Based Context
Prefer commands that return structured data over file reading:

```yaml
# Efficient: Commands return just what's needed
commands:
  - task-manager list --filter status:pending
  - git-status --short
  
# Inefficient: Loading entire files
files:
  - dev-taskflow/**/*.md  # Too much content
```

### 2. Progressive Context Loading
Start with minimal context, expand based on need:

```yaml
# Level 1: Discovery
commands:
  - release-manager current

# Level 2: Listing (if needed)
commands:
  - task-manager list

# Level 3: Details (only if required)
files:
  - specific/file.md
```

### 3. Metadata Extraction Patterns
Use commands that provide metadata without content:

```yaml
commands:
  - ls -la directory/  # File metadata
  - git log --oneline -10  # Commit metadata
  - grep -l "pattern" *.md  # Files containing pattern
```

### 4. Context Templates
Create reusable context templates for common patterns:

```yaml
# Embedded template
context:
  template: embedded
  
# External template (reusable)
context:
  template: .claude/contexts/project-overview.yaml
```

## Common Patterns

### Task Management Agent Pattern
Focuses on task discovery and navigation without content loading:

```yaml
commands:
  - release-manager current
  - task-manager list
  - task-manager next --limit 5
  - task-manager recent --limit 3
```

### Code Review Agent Pattern
Loads specific files for review with structured output:

```yaml
files:
  - ${review_target}/**/*.rb
commands:
  - git diff --cached
  - rubocop --format json ${review_target}
format: markdown-xml
```

### Search Agent Pattern
Combines multiple search strategies efficiently:

```yaml
commands:
  - grep -r "${search_term}" . --include="*.md"
  - find . -name "*${search_term}*" -type f
  - git log --grep="${search_term}" --oneline
```

## Anti-Patterns to Avoid

### 1. Loading Everything Upfront
**Bad:**
```yaml
files:
  - /**/*.md  # Loads entire project
```

**Good:**
```yaml
commands:
  - find . -name "*.md" -type f | head -20  # Just listings
```

### 2. Hard-Coded Paths
**Bad:**
```yaml
files:
  - dev-taskflow/current/v.0.5.0/tasks/*.md  # Version-specific
```

**Good:**
```yaml
commands:
  - release-manager current  # Discover current version
```

### 3. Redundant Context
**Bad:**
```yaml
files:
  - README.md
  - docs/README.md
  - project/README.md  # Multiple similar files
```

**Good:**
```yaml
files:
  - README.md  # Just the essential one
```

### 4. Missing Error Handling
**Bad:**
```bash
cd specific/directory
cat required-file.md  # Assumes file exists
```

**Good:**
```bash
if [ -f "required-file.md" ]; then
  cat required-file.md
else
  echo "File not found, using defaults"
fi
```

## Testing and Validation

### 1. Dual Compatibility Testing
Test agents in both environments:

```bash
# Direct Claude Code test
# 1. Open Claude Code
# 2. Invoke agent directly
# 3. Verify core functionality works

# MCP Proxy test
mcp-proxy --config test-config.yaml
# Invoke agent through proxy
# Verify enhanced features work
```

### 2. Context Efficiency Testing
Measure and optimize context usage:

```bash
# Measure context size
context --from-agent .claude/agents/agent-name.md | wc -c

# Target: <10KB for simple agents, <50KB for complex
```

### 3. Performance Validation
Ensure agents respond quickly:

- Initial response: <2 seconds
- Context loading: <500ms
- Command execution: <1 second per command

### 4. Error Resilience Testing
Verify graceful degradation:

- Missing files: Agent continues with available data
- Failed commands: Clear error reporting
- Unavailable tools: Fallback strategies work

## Agent Creation Workflow

### 1. Research Phase
```bash
# Analyze how task is currently done
task-manager recent --limit 10
git log --oneline -20

# Document command patterns
echo "Common commands:" > agent-research.md
history | grep "relevant-pattern" >> agent-research.md
```

### 2. Prototype Phase
Create minimal agent with core functionality:

```yaml
---
name: prototype-agent
description: Testing new agent pattern
tools: [basic-tool]
last_modified: '2025-08-14'
type: agent
---

Basic instructions...

## Context Definition
```yaml
commands:
  - single-test-command
```
```

### 3. Enhancement Phase
Add features based on usage:

- Observe actual usage patterns
- Add commonly needed commands
- Introduce MCP enhancements if beneficial
- Document common workflows

### 4. Optimization Phase
Reduce context and improve efficiency:

- Replace file loads with commands
- Remove redundant context
- Add caching where appropriate
- Optimize command sequences

## Tool Access and Permissions

### Custom Tool Wrappers
When agents need to use custom executables (like git wrapper tools):

1. **Agent Definition**: Use `tools: Bash` to enable command execution
2. **Permission Configuration**: Use settings.json to enforce tool restrictions

Example for git wrapper tools:
```json
{
  "permissions": {
    "deny": [
      "Bash(git status*)",  // Deny native git commands
      "Bash(git commit*)",
      "Bash(git add*)"
    ],
    "allow": [
      "Bash(git-status*)",  // Allow wrapper tools only
      "Bash(git-commit*)",
      "Bash(git-add*)"
    ]
  }
}
```

This pattern:
- Forces use of enhanced wrapper tools
- Prevents accidental use of native commands
- Provides security through permission boundaries
- Works with Claude Code's existing permission system

## Best Practices Summary

1. **Start Simple**: Begin with 5-6 essential commands
2. **Iterate Based on Usage**: Add complexity only when needed
3. **Prefer Commands**: Use commands over file loading
4. **Dynamic Discovery**: Avoid hard-coded values
5. **Document Workflows**: Include common usage patterns
6. **Test Both Modes**: Ensure Claude Code and MCP compatibility
7. **Optimize Context**: Minimize token usage
8. **Handle Errors**: Graceful degradation is essential
9. **Version Properly**: Update last_modified on changes
10. **Single Source**: Maintain agents in .claude/agents/ only
11. **Secure Tool Access**: Use permission rules for custom tools

## Migration Guide

### From Old Format to Enhanced Format
When updating existing agents:

1. Add YAML frontmatter with required fields
2. Move context to Context Definition section
3. Add MCP metadata (optional)
4. Test in both environments
5. Update last_modified date

### Example Migration
**Before:**
```markdown
# Git Commit Agent

You help with commits...

Load these files:
- file1.md
- file2.md
```

**After:**
```markdown
---
name: git-commit-manager
description: Intelligent git commit assistance
tools: [git-commit, git-status]
last_modified: '2025-08-14'
type: agent
---

You help with commits...

## Context Definition
```yaml
files:
  - file1.md
  - file2.md
```
```

## References

- Task 013: Context Loading Tool Implementation
- Task 014: MCP Proxy Server Architecture
- Task 015: Enhanced Markdown Agents Specification
- Existing Agents: `.claude/agents/` directory
- Original Idea: `dev-taskflow/backlog/ideas/20250814-1859-*.md`

---

*This guide should be updated as new patterns emerge and agent capabilities evolve. Focus on maintaining efficiency, clarity, and dual compatibility as core values.*

<documents>
    <template path="dev-handbook/.meta/tpl/agent.md.tmpl">
---
# Core metadata (both Claude Code and MCP proxy compatible)
name: #{agent_name}
description: #{agent_description}
tools: [#{agent_tools}]
last_modified: '#{date}'
type: agent

# MCP proxy enhancements (optional - remove if not needed)
mcp:
  model: #{mcp_model}  # e.g., google:gemini-2.5-flash
  tools_mapping:
    #{tool_name}:
      expose: true
      methods: [#{allowed_methods}]
  security:
    allowed_paths: 
      - "#{path_pattern}"
    rate_limit: #{rate}/hour

# Context configuration
context:
  auto_inject: #{auto_inject}  # true or false
  template: embedded  # or path to external template
  cache_ttl: #{cache_seconds}  # e.g., 300 for 5 minutes
---

You are a #{agent_role} focused on #{agent_focus}.

## Core Responsibilities

#{agent_responsibilities}

## Key Commands

```bash
# Primary operations
#{primary_commands}

# Discovery and navigation
#{discovery_commands}

# Status and reporting
#{status_commands}
```

## Common Workflows

### Workflow 1: #{workflow_1_name}
```bash
#{workflow_1_commands}
```

### Workflow 2: #{workflow_2_name}
```bash
#{workflow_2_commands}
```

## Best Practices

1. **#{practice_1_title}**: #{practice_1_description}
2. **#{practice_2_title}**: #{practice_2_description}
3. **#{practice_3_title}**: #{practice_3_description}

## Context Definition

```yaml
# Minimal context - prefer commands over file loading
commands:
  # Discovery commands (get current state)
  - #{discovery_command_1}
  - #{discovery_command_2}
  
  # Primary operations
  - #{operation_command_1}
  - #{operation_command_2}
  
  # Status checks
  - #{status_command_1}

# Only load files if absolutely necessary
files:
  - #{essential_file_pattern}  # Only if content needed

format: markdown-xml
```

## Error Handling

- **Missing resources**: #{missing_resource_strategy}
- **Failed commands**: #{failed_command_strategy}
- **Invalid inputs**: #{invalid_input_strategy}

## Notes

#{additional_notes}
    </template>
</documents>