# agent-lint - Agent Definition Validator

## Overview

`agent-lint` is a validation and linting tool for agent definition files (`.ag.md`) used in the ACE ecosystem. It validates agent file structure, required fields, and checks compatibility with both Claude Code and MCP proxy systems.

## Purpose

The tool was created to ensure agent definitions follow standardized formats and are compatible with different AI assistant platforms. It helps maintain quality and consistency across agent definitions while supporting dual compatibility (Claude Code native + MCP proxy enhancements).

## Location

- **Executable**: `/dev-tools/exe/agent-lint`
- **Command Implementation**: `/dev-tools/lib/coding_agent_tools/cli/commands/agent_lint.rb`
- **Registration**: Via `ExecutableWrapper` pattern in dev-tools

## API Reference

### Basic Commands

```bash
# List all agents with validation status
agent-lint --list

# Validate specific agent file
agent-lint --validate .claude/agents/my-agent.ag.md

# List with detailed information
agent-lint --list --format detailed

# Filter by compatibility
agent-lint --list --compatibility claude
agent-lint --list --compatibility mcp
```

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--list, -l` | boolean | false | List all available agents |
| `--validate, -v` | string | - | Validate specific agent file |
| `--format, -f` | string | summary | Output format: summary, detailed, claude, mcp |
| `--agent-dir` | string | .claude/agents | Directory containing agent files |
| `--compatibility, -c` | string | all | Filter by compatibility: all, claude, mcp |

### Output Formats

#### Summary Format
```
Available Agents:
==================
  task-finder              [Claude]
  git-all-commit           [Claude | MCP+]
  search                   [Claude]
```

#### Detailed Format
```
Detailed Agent Information:
==========================

task-finder:
  File: .claude/agents/task-finder.ag.md
  Name: task-finder
  Description: FIND tasks only - list, filter, discover...
  Tools: Read, Bash
  Claude Compatible: Yes
  MCP Enhanced: No
  Context Definition: Yes
```

#### Claude Format
Lists only Claude Code compatible agents with descriptions.

#### MCP Format
Lists only MCP proxy enhanced agents with model and security info.

### Validation Checks

The tool validates:

1. **Structure Checks**:
   - YAML frontmatter presence
   - Name field
   - Description field
   - Tools field
   - Context Definition section

2. **Compatibility Checks**:
   - **Claude Compatible**: Has required frontmatter fields (name, description, tools)
   - **MCP Enhanced**: Contains `mcp:` or `context:` configuration blocks

### Exit Codes

- `0` - Success
- `1` - Error occurred

## How It Works

### Architecture

The tool uses a simple pattern-matching approach:

1. **File Discovery**: Scans configured agent directory for `.md` files
2. **Content Analysis**: Reads each file and checks for required patterns
3. **Validation**: Validates structure and compatibility requirements
4. **Reporting**: Formats results based on selected output mode

### ATOM Architecture Mapping

- **Atoms**: Pattern matching functions (regex-based field detection)
- **Molecules**: File reading, content parsing
- **Organisms**: Validation orchestration, result formatting
- **CLI Command**: Top-level interface

The current implementation is **self-contained within a single command class** - it does not follow full ATOM separation.

## Integration with ace-* Architecture

### Current Status

`agent-lint` is a **standalone executable** within dev-tools that operates independently of other ACE components.

### Migration Options

#### Option 1: ace-handbook Integration
Agent definitions and their validation could be part of `ace-handbook`:

```ruby
# Future: ace-handbook agent validate
module Ace::Handbook::Agents
  class Validator
    # Migrate agent-lint functionality here
  end
end
```

**Pros**:
- Agents are documentation/workflow artifacts
- Natural grouping with other handbook content
- Single gem for all AI assistant integration patterns

**Cons**:
- Mixes validation tools with documentation
- Handbook gem may become too large

#### Option 2: Standalone ace-agent-lint
Create a focused gem for agent validation:

```ruby
# Future: ace-agent-lint
module Ace::AgentLint
  module Atoms
    module PatternMatcher  # Regex-based field detection
    module Validator       # Pure validation functions
  end

  module Molecules
    class AgentReader      # File reading and parsing
    class CompatibilityChecker  # Compatibility validation
  end

  module Organisms
    class AgentValidator   # Orchestration
    class ReportFormatter  # Multi-format output
  end
end
```

**Pros**:
- Single responsibility (validation only)
- Reusable for CI/CD pipelines
- Clear separation of concerns

**Cons**:
- Another gem to maintain
- Small scope for standalone gem

#### Option 3: ace-nav Integration
Agent discovery and validation as part of resource navigation:

```ruby
# Future: ace-nav agent:// protocol
ace-nav 'agent://task-finder' --validate
```

**Pros**:
- Unified resource discovery
- Natural fit with wfi:// protocol pattern
- Leverages existing navigation infrastructure

**Cons**:
- Validation is not core navigation concern
- May complicate ace-nav's focused scope

### Recommended Migration Path

**Recommended: Option 1 (ace-handbook)**

Rationale:
- Agent definitions are inherently documentation artifacts
- Validation is a quality control mechanism for handbook content
- Similar to how `handbook sync-templates` validates template embedding
- Keeps validation tooling with the content it validates

### Migration Tasks

1. **Extract validation logic** from single command class into ATOM layers
2. **Create ace-handbook agent subcommand**:
   ```bash
   ace-handbook agent validate [file]
   ace-handbook agent list [--format detailed]
   ```
3. **Move agent definitions** from `.claude/agents/` to `ace-handbook/agents/`
4. **Update symlink generation** to point to new location
5. **Deprecate agent-lint** with redirect to new command
6. **Update documentation** and migration guides

## Usage Examples

### Validating All Agents

```bash
# Quick status check
agent-lint --list

# Detailed validation report
agent-lint --list --format detailed

# Check Claude Code compatibility
agent-lint --list --compatibility claude --format claude
```

### Validating Specific Agent

```bash
# Validate single file
agent-lint --validate .claude/agents/task-finder.ag.md

# Example output:
# Agent Validation Results:
# ========================
# File: .claude/agents/task-finder.ag.md
#
# Structure Checks:
#   YAML Frontmatter: ✓
#   Name Field: ✓
#   Description Field: ✓
#   Tools Field: ✓
#   Context Definition: ✓
#
# Compatibility:
#   Claude Code Compatible: ✓
#   MCP Proxy Enhanced: ✗
#
# ℹ  This agent is Claude Code compatible but could be enhanced for MCP proxy
```

### Custom Agent Directory

```bash
# Validate agents in different location
agent-lint --list --agent-dir dev-handbook/agents
```

## Configuration

Currently has **no configuration file support**. All options are command-line flags.

Future ace-handbook integration could use:

```yaml
# .ace/handbook/config.yml
ace:
  handbook:
    agents:
      directory: "dev-handbook/agents"
      validation:
        strict: true
        require_mcp_support: false
```

## Limitations

1. **Basic Pattern Matching**: Uses regex rather than proper YAML/frontmatter parsing
2. **No Schema Validation**: Doesn't validate against a formal agent schema
3. **Limited MCP Detection**: Only checks for `mcp:` keyword presence
4. **Single-file Focus**: Cannot validate agent collections or dependencies
5. **No Auto-fix**: Only reports issues, doesn't suggest or apply fixes

## Related Tools

- **handbook sync-templates**: Validates template embedding in workflows
- **ace-nav**: Could provide agent discovery via `agent://` protocol
- **Claude Code**: Consumer of validated agent definitions
- **MCP Proxy**: Uses MCP-enhanced agent metadata

## Historical Context

Created as part of the dev-tools monolith to support dual compatibility:
- Native Claude Code agents (simple frontmatter)
- MCP proxy enhanced agents (additional metadata)

The tool emerged from the need to maintain quality across both integration patterns during the transition to standardized agent definitions.

## Deprecation Timeline

- **Current**: Available via `agent-lint` executable
- **v0.10.0**: Expected migration to `ace-handbook agent validate`
- **v0.11.0**: Deprecation warning when using `agent-lint`
- **v1.0.0**: Removal from dev-tools, fully replaced by ace-handbook

## See Also

- Agent definition format: `dev-handbook/.integrations/claude/agents/README.md`
- Handbook architecture: `docs/ace-handbook.md` (when created)
- MCP proxy setup: `docs/mcp-proxy.md`
