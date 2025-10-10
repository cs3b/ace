# coding-agent-tools - Unified CLI Hub

## Overview

`coding-agent-tools` is the main CLI entry point for the legacy dev-tools monolith. It provides a unified interface to 15+ subcommand groups covering task management, LLM integration, code quality, navigation, git operations, and more.

## Purpose

This tool was created as a centralized CLI hub to:
- Provide a single entry point for all development automation tools
- Organize related functionality into logical subcommand groups
- Enable consistent CLI patterns across diverse capabilities
- Support both human developers and AI agents with deterministic interfaces

## Location

- **Executable**: `/dev-tools/exe/coding-agent-tools`
- **CLI Registry**: `/dev-tools/lib/coding_agent_tools/cli.rb`
- **Command Implementations**: `/dev-tools/lib/coding_agent_tools/cli/commands/`

## Architecture

### Command Registration Pattern

Uses Dry::CLI with deferred registration to avoid circular dependencies:

```ruby
module CodingAgentTools::Cli::Commands
  extend Dry::CLI::Registry

  # Deferred registration methods
  def self.register_llm_commands
    # Load and register LLM commands
  end

  def self.register_task_commands
    # Load and register task commands
  end

  # ... other registration methods

  def self.call(*args)
    # Register all commands
    register_llm_commands
    register_task_commands
    # ... register all other command groups

    # Execute via Dry::CLI
    Dry::CLI.new(self).call(arguments: args)
  end
end
```

### Subcommand Groups

The CLI provides 15+ subcommand groups:

| Group | Purpose | Status |
|-------|---------|--------|
| `llm` | LLM provider queries | ✅ Migrated to ace-llm |
| `task` | Task management | ✅ Migrated to ace-taskflow |
| `release` | Release management | ✅ Migrated to ace-taskflow |
| `code` | Code review operations | ⚠️ Partial migration to ace-review |
| `code-lint` | Code quality linting | 📋 Target: ace-lint |
| `git` | Git operations | 📋 Target: ace-git-* |
| `nav` | Resource navigation | ✅ Migrated to ace-nav |
| `context` | Context loading | ✅ Migrated to ace-context |
| `search` | Unified search | ✅ Migrated to ace-search |
| `coverage` | Coverage analysis | 📋 Target: ace-coverage |
| `handbook` | Handbook operations | 📋 Target: ace-handbook |
| `integrate` | AI assistant integration | 📋 Target: ace-integrate |
| `reflection` | Retrospective synthesis | 📋 Target: ace-taskflow |
| `create-path` | File/directory creation | 📋 Target: ace-create |
| `mcp-proxy` | MCP proxy server | 📋 Target: ace-mcp-server |
| `agent-lint` | Agent validation | 📋 Target: ace-handbook |

## API Reference

### Global Commands

```bash
coding-agent-tools version              # Print version
coding-agent-tools all                  # List all available tools
```

### Subcommand Groups

#### LLM Commands (→ ace-llm)
```bash
coding-agent-tools llm query "prompt" -m gpt-4
coding-agent-tools llm usage_report
```

#### Task Commands (→ ace-taskflow)
```bash
coding-agent-tools task next
coding-agent-tools task recent
coding-agent-tools task list
coding-agent-tools task all             # Alias for list
coding-agent-tools task generate-id
```

#### Release Commands (→ ace-taskflow)
```bash
coding-agent-tools release current
coding-agent-tools release next
coding-agent-tools release all
coding-agent-tools release generate-id
coding-agent-tools release validate
coding-agent-tools release draft
```

#### Code Commands (→ ace-review)
```bash
coding-agent-tools code review
coding-agent-tools code review-synthesize
coding-agent-tools code lint
```

#### Code-Lint Commands (→ ace-lint)
```bash
coding-agent-tools code-lint all
coding-agent-tools code-lint ruby
coding-agent-tools code-lint markdown
coding-agent-tools code-lint docs-dependencies
```

#### Git Commands (→ ace-git-*)
```bash
coding-agent-tools git status
coding-agent-tools git commit
coding-agent-tools git add
coding-agent-tools git push
coding-agent-tools git pull
coding-agent-tools git log
coding-agent-tools git diff
coding-agent-tools git fetch
coding-agent-tools git checkout
coding-agent-tools git switch
coding-agent-tools git mv
coding-agent-tools git rm
coding-agent-tools git restore
coding-agent-tools git tag
```

#### Nav Commands (→ ace-nav)
```bash
coding-agent-tools nav path [uri]
coding-agent-tools nav tree [uri]
coding-agent-tools nav ls [uri]
```

#### Context Commands (→ ace-context)
```bash
coding-agent-tools context [inputs...]
```

#### Search Commands (→ ace-search)
```bash
coding-agent-tools search [pattern]
```

#### Coverage Commands (→ ace-coverage)
```bash
coding-agent-tools coverage analyze <file>
```

#### Handbook Commands (→ ace-handbook)
```bash
coding-agent-tools handbook sync-templates
```

#### Integration Commands (→ ace-integrate)
```bash
coding-agent-tools integrate [type]
```

#### Reflection Commands (→ ace-taskflow)
```bash
coding-agent-tools reflection synthesize
```

#### Create-Path Commands (→ ace-create)
```bash
coding-agent-tools create-path [type]
```

#### MCP Proxy Commands (→ ace-mcp-server)
```bash
coding-agent-tools mcp-proxy
```

#### Agent-Lint Commands (→ ace-handbook)
```bash
coding-agent-tools agent-lint
```

## Migration Strategy

The `coding-agent-tools` CLI is being **decomposed** into focused ace-* gems. This represents the primary migration effort for the ACE ecosystem.

### Migration Status

#### ✅ Completed Migrations

1. **ace-llm** (LLM integration)
   - Original: `coding-agent-tools llm query`
   - New: `ace-llm-query`
   - Status: Fully migrated, working

2. **ace-taskflow** (Task/release management)
   - Original: `coding-agent-tools task/release`
   - New: `ace-taskflow task/release`
   - Status: Fully migrated, working

3. **ace-nav** (Resource navigation)
   - Original: `coding-agent-tools nav`
   - New: `ace-nav`
   - Status: Fully migrated, working

4. **ace-context** (Context loading)
   - Original: `coding-agent-tools context`
   - New: `ace-context`
   - Status: Fully migrated, working

5. **ace-search** (Unified search)
   - Original: `coding-agent-tools search`
   - New: `ace-search`
   - Status: Fully migrated, working

6. **ace-review** (Code review - partial)
   - Original: `coding-agent-tools code review`
   - New: `ace-review`
   - Status: Partially migrated, preset system working

#### 📋 Pending Migrations

1. **ace-lint** (Code quality)
   - Target: `coding-agent-tools code-lint` → `ace-lint`
   - Priority: High (frequently used)

2. **ace-git-commit** (Git operations - partial)
   - Target: `coding-agent-tools git commit` → `ace-git-commit`
   - Status: Commit generation migrated, other git commands pending

3. **ace-handbook** (Handbook operations)
   - Target: `coding-agent-tools handbook` → `ace-handbook`
   - Includes: Template sync, agent validation

4. **ace-coverage** (Coverage analysis)
   - Target: `coding-agent-tools coverage` → `ace-coverage`
   - Or integrate into: `ace-test-runner`

5. **ace-create** (File/directory creation)
   - Target: `coding-agent-tools create-path` → `ace-create`
   - Alternative: Integrate into other gems as needed

6. **ace-mcp-server** (MCP proxy)
   - Target: `coding-agent-tools mcp-proxy` → `ace-mcp-server`
   - Priority: Medium (niche use case)

### Migration Pattern

Each subcommand group follows this pattern:

1. **Extract to ace-* gem**:
   ```ruby
   # New gem: ace-example/lib/ace/example/cli.rb
   module Ace::Example
     class CLI < Dry::CLI::Command
       # Migrated functionality
     end
   end
   ```

2. **Create standalone executable**:
   ```ruby
   # ace-example/exe/ace-example
   #!/usr/bin/env ruby
   require 'ace/example'
   exit Ace::Example::CLI.start(ARGV)
   ```

3. **Add to workspace Gemfile**:
   ```ruby
   # Root Gemfile
   gem 'ace-example', path: 'ace-example'
   ```

4. **Create development binstub**:
   ```bash
   # bin/ace-example
   #!/usr/bin/env ruby
   load "ace-example/exe/ace-example"
   ```

5. **Update documentation and deprecation notices**

### Transition Period Support

During migration, both interfaces are supported:

```bash
# Legacy (still works)
coding-agent-tools llm query "test"

# New (preferred)
ace-llm-query "test"
```

## Integration with ace-* Architecture

### Current Architecture

`coding-agent-tools` is a **monolithic CLI hub** that violates the focused gem principle:

**Problems**:
- Single gem with too many responsibilities
- Difficult to maintain and test
- Large dependency footprint
- Circular dependency risks
- Slow to load due to many requires

### Target Architecture

**Focused ace-* gems** with single responsibilities:

**Benefits**:
- Each gem has clear scope
- Independent versioning
- Faster load times
- Easier testing
- Modular installation

### Example: Before vs After

**Before (Monolith)**:
```bash
# All commands in one gem
coding-agent-tools llm query "test"
coding-agent-tools task next
coding-agent-tools search "pattern"
# ... 15+ subcommand groups
```

**After (Focused Gems)**:
```bash
# Each capability as standalone gem
ace-llm-query "test"
ace-taskflow task next
ace-search "pattern"
# ... focused tools
```

## Usage Examples

### List All Available Tools

```bash
coding-agent-tools all
```

Output:
```
Available Coding Agent Tools:

Task Management:
  - task: Task management operations
  - release: Release management operations

LLM Integration:
  - llm: LLM provider operations

Code Quality:
  - code: Code review and quality
  - code-lint: Multi-language linting

... (15+ categories)
```

### Using Subcommands

```bash
# Task management
coding-agent-tools task next
coding-agent-tools task list

# LLM queries
coding-agent-tools llm query "Explain this code" -m claude-3-5-sonnet

# Code review
coding-agent-tools code review --diff HEAD~1..HEAD

# Navigation
coding-agent-tools nav path wfi://task-create
```

### Getting Help

```bash
# Global help
coding-agent-tools --help

# Subcommand help
coding-agent-tools llm --help
coding-agent-tools task --help
```

## Configuration

No centralized configuration. Each subcommand group manages its own config:

- LLM: `.ace/llm/config.yml`
- Tasks: `.ace-taskflow/`
- Code quality: `.ace/code-quality/config.yml`
- Navigation: `.ace/nav/config.yml`

## Exit Codes

- `0` - Success
- `1` - Command error or validation failure

## Limitations

### As a Monolith

1. **Large Surface Area**: Too many responsibilities in one tool
2. **Slow Startup**: Loads all commands even when using one
3. **Difficult Testing**: Hard to test in isolation
4. **Version Coupling**: All features versioned together
5. **Complex Dependencies**: All subcommands share dependency tree

### Migration Challenges

1. **Breaking Changes**: Users must update scripts to new commands
2. **Documentation Drift**: Docs spread across multiple gems
3. **Discovery**: Harder to find the right tool for the job
4. **Transition Period**: Maintaining both old and new simultaneously

## Deprecation Timeline

The `coding-agent-tools` monolith is being **gradually deprecated** as capabilities migrate to focused gems:

- **v0.9.0** (Current): Most core capabilities migrated (llm, task, nav, context, search)
- **v0.10.0**: Complete migration of remaining capabilities
- **v0.11.0**: Deprecation warnings for all `coding-agent-tools` commands
- **v0.12.0**: Redirect wrapper to new commands
- **v1.0.0**: Remove `coding-agent-tools` entirely

### Transition Helper

Future versions will include a migration helper:

```bash
# Shows new command for old usage
coding-agent-tools --migrate-help llm query

# Output:
# The 'coding-agent-tools llm query' command has moved to 'ace-llm-query'
#
# Old: coding-agent-tools llm query "prompt" -m model
# New: ace-llm-query "prompt" -m model
#
# Update your scripts and aliases to use the new command.
```

## Historical Context

`coding-agent-tools` emerged from the need to organize growing functionality:

1. **Phase 1**: Individual scripts for specific tasks
2. **Phase 2**: Consolidated into `coding-agent-tools` monolith
3. **Phase 3**: Extracted focused capabilities to ace-* gems
4. **Phase 4** (Future): Complete decomposition, monolith removed

The tool served its purpose as a staging ground for developing capabilities before they matured into focused gems.

## Related Documentation

- Individual tool migrations:
  - `docs/ace-llm.md`
  - `docs/ace-taskflow.md`
  - `docs/ace-nav.md`
  - `docs/ace-context.md`
  - `docs/ace-search.md`
  - `docs/ace-review.md`

- Pending migrations:
  - `docs/code-lint.md` → ace-lint
  - `docs/coverage-analyze.md` → ace-coverage
  - `docs/handbook.md` → ace-handbook
  - `docs/mcp-proxy.md` → ace-mcp-server

- Architecture:
  - `docs/architecture.md` - ACE architecture overview
  - `docs/decisions/ADR-015-mono-repo-ace-gems-migration.md`

## See Also

- **ace-core**: Configuration foundation for all gems
- **ace-test-support**: Testing infrastructure for all gems
- **Gemfile**: Workspace dependencies
- **bin/**: Development binstubs for all ace-* tools
