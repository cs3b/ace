# Context

## Metadata

- **preset_content**: # Project Context

You are working on the Coding Agent Workflow Toolkit (Meta) - a comprehensive meta-repository that provides documentation and guidance for setting up AI-assisted development workflow systems.
- **preset_name**: project
- **output**: cache

## Files

### docs/architecture.md

```
# ACE - System Architecture

## Overview

ACE (Agent Coding Environment) is a mono-repo ecosystem of modular Ruby gems that provide a deterministic CLI surface for AI-assisted software development. Both human developers and AI agents use the same tools through consistent interfaces.

## Core Architecture Principles

- **Mono-Repo Structure**: All ace-* gems at repository root with shared dependencies
- **ATOM Pattern**: Consistent architecture across all gems (Atoms, Molecules, Organisms, Models)
- **Configuration Cascade**: Hierarchical .ace/ configuration with nearest-wins resolution
- **Zero-Dependency Core**: ace-core uses only Ruby standard library
- **AI-Native Design**: Deterministic commands designed for autonomous agent execution

## Repository Organization

The mono-repo contains modular ace-* gems and legacy components being migrated. Each gem follows the ATOM architecture pattern with consistent directory structure. For detailed file organization and navigation, see [blueprint.md](blueprint.md).

## ATOM Architecture Pattern

All ace-* gems follow the ATOM pattern for consistent, testable code organization:

### Atoms (Pure Functions)

- No side effects or external dependencies
- Single, well-defined purpose
- Examples: `yaml_parser`, `deep_merger`, `path_expander`

### Molecules (Composed Operations)

- Combine atoms to perform specific operations
- May have controlled side effects (file I/O)
- Examples: `yaml_loader`, `config_finder`, `context_chunker`

### Organisms (Business Logic)

- Orchestrate molecules to implement features
- Handle complex workflows and coordination
- Examples: `config_resolver`, `context_loader`, `test_orchestrator`

### Models (Data Structures)

- Pure data carriers with no business logic
- Immutable value objects preferred
- Examples: `config`, `context_data`, `test_result`

## Component Types

### Tools (ace-* gems)

Modular Ruby gems providing focused CLI functionality:

- **ace-core**: Configuration management foundation
- **ace-context**: Project context loading
- **ace-test-runner**: Test execution and reporting
- **ace-test-support**: Shared testing infrastructure
- **ace-taskflow**: Task and release management with dependencies and tree visualization
- **ace-nav**: Resource discovery and navigation with wfi:// protocol support
- **ace-llm**: Multi-provider AI model integration with client registry

### Workflows (.wf.md)

Self-contained instruction documents for AI agents:

- Migrating to `ace-taskflow/handbook/workflow-instructions/`
- Legacy location: `dev-handbook/workflow-instructions/`
- Include all necessary context and templates
- Follow ADR-001 self-containment principle
- Discoverable via ace-nav wfi:// protocol

### Agents (.ag.md)

Specialized single-purpose agents for focused tasks:

- Located in `dev-handbook/.integrations/claude/agents/`
- Exposed via `.claude/agents/` symlinks
- Designed for delegation and composition

### Guides

Development patterns and best practices:

- Located in `dev-handbook/guides/`
- Reference documentation for humans and agents
- Standards and conventions

## AI Integration Architecture

### Claude Code Integration

- **Commands**: `.claude/commands/` maps workflows to slash commands
- **Agents**: `.claude/agents/` provides agent access via Task tool
- **Deterministic CLI**: All tools provide predictable, parseable output
- **wfi:// Protocol**: Direct workflow access via ace-nav integration

### Platform Compatibility

- Commands work identically for humans and agents
- Platform-agnostic design (Claude Code, Codex, OpenCode)
- Future MCP (Model Context Protocol) support planned

### Agent Delegation Pattern

1. User invokes command or agent
2. Agent analyzes task requirements
3. Delegates to specialized subagents as needed
4. Aggregates results and reports back

## Key Architectural Decisions

### Mono-Repo Migration (ADR-015)

- Migrated from multi-repository submodules to mono-repo
- Each capability packaged as focused ace-* gem
- Simplified dependency management and testing

### ATOM Architecture (ADR-011)

- Enforces clean separation of concerns
- Consistent patterns across all gems
- Testable, maintainable code structure

### Workflow Self-Containment (ADR-001)

- Workflows include all necessary templates
- No external dependencies except core docs
- Enables reliable autonomous execution

### Configuration Cascade

- `.ace/` directories searched from current to home
- Nearest configuration wins (deepest in tree)
- Enables project-specific settings without modification

### Zero-Dependency Core

- ace-core uses only Ruby standard library
- Provides stable foundation for all other gems
- Reduces dependency conflicts and complexity

## Security & Quality Principles

- **Path Validation**: Multi-layer validation for file operations
- **Input Sanitization**: Clean all user inputs before processing
- **Test Coverage**: Comprehensive test suites using ace-test-support
- **CI/CD Integration**: GitHub Actions matrix testing across Ruby versions
- **Deterministic Output**: Consistent, predictable command results

## Future Architecture

### Planned Migrations

- **ace-handbook**: Workflows, guides, and templates as a gem
- **ace-git**: Enhanced git operations
- **ace-search**: Unified file and content search across codebases
- **ace-review**: Code review automation and synthesis

### Vision

Every development capability becomes an installable Ruby gem. Prompts, agents, and workflows are embedded within thematic gems, making them instantly available through `gem install ace-*`.

---

*For detailed architectural decisions, see [docs/decisions.md](decisions.md)*


```

### docs/blueprint.md

```
# Project Blueprint: ACE (Agent Coding Environment)

## What is a Blueprint?

This document provides navigation guidance for the ACE codebase, highlighting what to modify and what to avoid.

## Repository Structure

```
ace-*/          # Ruby gems following ATOM architecture
dev-handbook/   # Workflows, agents, guides (legacy, migrating to ace-handbook)
.ace-taskflow/  # Task and release management (migrated from dev-taskflow)
dev-tools/      # CLI tools (legacy, being split into ace-* gems)
.claude/        # Claude Code integration (commands and agent symlinks)
.ace/           # Configuration cascade root
docs/           # System documentation and ADRs
.github/        # CI/CD workflows
```

For detailed architecture and ATOM pattern, see [architecture.md](architecture.md).

## Read-Only Paths

AI agents should treat these as read-only unless explicitly instructed to modify:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `.github/workflows/**/*` # CI/CD configuration
- `dev-handbook/guides/**/*` # Development guides
- `dev-handbook/workflow-instructions/**/*` # AI workflow instructions
- `.ace-taskflow/done/**/*` # Completed tasks
- `.ace-taskflow/v.*/retro/**/*` # Development retrospectives
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should ignore these during normal operations:

- `.ace-taskflow/done/**/*` # Completed tasks and releases
- `.cache/ace-*/**/*` # Cached output from ace tools
- `ace-*/coverage/**/*` # Test coverage reports
- `**/test-reports/**/*` # Test report files
- `tmp/**/*` # Temporary files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `node_modules/**/*` # Node.js dependencies
- `*.bak` # Backup files
- `docs/context/cached/**/*` # Legacy cached context files


```

### docs/decisions.md

```
# Project Decisions

This document provides actionable decisions from Architecture Decision Records (ADRs) that directly affect how AI agents and developers should work with this codebase.

## Active Decisions

### Workflow Self-Containment
**Decision**: All AI workflows must be completely self-contained with embedded templates and context. Workflows cannot depend on other workflows or external files except the three standard context documents.
**Impact**: When executing workflows, never load external guides or templates. All necessary information must be within the .wf.md file itself. Only load `docs/what-do-we-build.md`, `docs/architecture.md`, and `docs/blueprint.md` for project context.
**Details**: [ADR-001](decisions/ADR-001-workflow-self-containment-principle.md)

### XML Template Embedding
**Decision**: Use XML format `<documents>` and `<template>` tags for embedding templates within workflow files, placed at the end of the document.
**Impact**: When updating workflows, preserve XML template blocks exactly. Use `handbook sync-templates` command to synchronize embedded templates with source files. Never use four-tick markdown blocks for templates.
**Details**: [ADR-002](decisions/ADR-002-xml-template-embedding-architecture.md)

### Template Directory Structure
**Decision**: All templates must be stored in `dev-handbook/templates/` with standardized subdirectories and `.template.md` extension.
**Impact**: When creating new templates, place them in the appropriate subdirectory (project-docs/, release-tasks/, code-review/, reflections/, task-management/). Always use `.template.md` extension.
**Details**: [ADR-003](decisions/ADR-003-template-directory-separation.md)

### Consistent Path Standards
**Decision**: All document paths must be relative to project root, never absolute. Follow standard patterns like `dev-handbook/templates/**/*.template.md`.
**Impact**: When referencing files in documentation or code, always use paths relative to the project root. Never use absolute paths or paths starting with `./` or `../`.
**Details**: [ADR-004](decisions/ADR-004-consistent-path-standards.md)

### Universal Document Embedding
**Decision**: Use the universal `<documents>` container format for embedding any type of document (templates, guides, examples) in workflows.
**Impact**: When embedding documents in workflows, always use the `<documents>` wrapper with appropriate document type tags. This enables automated synchronization and validation.
**Details**: [ADR-005](decisions/ADR-005-universal-document-embedding-system.md)

## Architecture Decisions

### Mono-Repo Migration to ace-* Gems
**Decision**: Migrate from multi-repository submodule architecture to mono-repo with modular ace-* Ruby gems.
**Impact**: When working with the codebase:
- All new functionality goes into appropriate ace-* gems at the repository root
- Follow ATOM architecture (atoms/, molecules/, organisms/, models/) in each gem
- Use the root Gemfile for development dependencies
- Run commands with `bundle exec` during development
- Configuration uses .ace/ cascade with nearest/deepest wins
- Legacy dev-* directories are being migrated incrementally
**Details**: [ADR-015](decisions/ADR-015-mono-repo-ace-gems-migration.md)

## Development Tool Decisions

### CI-Aware VCR Configuration
**Decision**: VCR cassettes must be environment-aware with CI detection and appropriate recording modes.
**Impact**: When writing tests with external API calls, ensure VCR is configured to detect CI environments. Use `new_episodes` mode locally and `none` in CI.
**Details**: [ADR-006](decisions/ADR-006-CI-Aware-VCR-Configuration.t.md)

### Zeitwerk Autoloading
**Decision**: Use Zeitwerk for all Ruby autoloading with proper inflections for acronyms (CLI, HTTP, API, JSON, etc.).
**Impact**: Follow file naming conventions strictly. Use snake_case filenames that match class names. Configure inflections for technical acronyms in the Zeitwerk setup.
**Details**: [ADR-007](decisions/ADR-007-Zeitwerk-for-Autoloading.t.md)

### Observability with dry-monitor
**Decision**: Implement observability using dry-monitor's publish/subscribe pattern with a central Notifications instance.
**Impact**: When adding new features that need monitoring, publish events through the Notifications instance. Subscribe to events for logging, metrics, or debugging.
**Details**: [ADR-008](decisions/ADR-008-Observability-with-dry-monitor.t.md)

### Centralized CLI Error Reporting
**Decision**: Use a centralized ErrorReporter module for all CLI error handling with debug flag support.
**Impact**: Never print errors directly to stdout/stderr in CLI commands. Always route errors through ErrorReporter for consistent formatting and debug support.
**Details**: [ADR-009](decisions/ADR-009-Centralized-CLI-Error-Reporting.t.md)

### HTTP Client Strategy
**Decision**: Use Faraday as the standard HTTP client with retry middleware and observability integration.
**Impact**: For all HTTP requests, use Faraday with the standard middleware stack. Never use Net::HTTP directly. Ensure retry logic and monitoring are configured.
**Details**: [ADR-010](decisions/ADR-010-HTTP-Client-Strategy-with-Faraday.t.md)

### ATOM Architecture Rules
**Decision**: Strictly follow ATOM architecture layers: Models (pure data), Molecules (focused operations), Organisms (business orchestration), Ecosystems (complete workflows).
**Impact**: When creating new components in dev-tools:
- Pure data structures go in `models/` (no behavior)
- Focused operations composing Atoms go in `molecules/` (single responsibility)
- Business logic orchestrating Molecules goes in `organisms/` (complex coordination)
- Never place data carriers in `molecules/` or behavior in `models/`
**Details**: [ADR-011](decisions/ADR-011-ATOM-Architecture-House-Rules.t.md)

### Dynamic Provider System
**Decision**: Implement a dynamic provider system for LLM integrations with standardized interfaces.
**Impact**: When adding new LLM providers, follow the established provider interface pattern. Register providers dynamically through the provider system.
**Details**: [ADR-012](decisions/ADR-012-Dynamic-Provider-System-Architecture.t.md)

### Class Naming Conventions
**Decision**: Preserve established technical acronyms in class names (JSONFormatter, HTTPClient, APICredentials) while using CamelCase for domain terms.
**Impact**: When naming classes, keep technical acronyms uppercase (HTTP, API, JSON, LLM). Use CamelCase for domain-specific terms (LlmModelInfo, not LLMModelInfo).
**Details**: [ADR-013](decisions/ADR-013-Class-Naming-Conventions-and-Zeitwerk-Inflections.t.md)

### LLM Integration Architecture
**Decision**: Use hybrid approach for LLM context sizes: API-first with static fallback mappings.
**Impact**: When integrating with LLM providers, first attempt to get context size from API. Maintain static mappings as fallback for providers without API support.
**Details**: [ADR-014](decisions/ADR-014-LLM-Integration-Architecture.t.md)

## Decision History

For complete decision history and detailed rationale, refer to the individual ADR documents in `docs/decisions/`.
```

### docs/tools.md

```
# ACE Tools Reference

| Tool | Purpose | Key Commands |
|------|---------|--------------|
| **ace-context** | Load project context | `ace-context project`, `ace-context --list` |
| **ace-test** | Run tests | `ace-test test/file.rb`, `ace-test test/file.rb:42` |
| **ace-test-suite** | Run all tests | `ace-test-suite` |
| **ace-taskflow** | Task management | `ace-taskflow task`, `ace-taskflow tasks --preset current` |
| **ace-nav** | Resource navigation | `ace-nav wfi://workflow-name`, `ace-nav --sources` |
| **ace-llm-query** | Query LLM providers | `ace-llm-query "prompt" -m gpt-4` |

## Quick Examples

```sh
# Task management
ace-taskflow task                       # Show next task
ace-taskflow tasks --tree               # Dependency tree view
ace-taskflow idea create "Feature" -gc  # Capture and commit idea

# Navigation and context
ace-context project --output stdio      # Load context to stdout
ace-nav 'wfi://*task*' --list          # Find workflow patterns

# Testing
ace-test test/foo_test.rb:42           # Test at specific line
```

*Full documentation in each ace-*/docs/usage.md*

```

### docs/what-do-we-build.md

```
# ACE (Agent Coding Environment)

## What We Build

ACE packages development capabilities as Ruby gems for AI coding assistants. Whether it's a tool, a workflow, or a template - ACE turns it into a reusable gem that works seamlessly with Claude Code, Codex, OpenCode, and other AI development environments.

## Current Capabilities

- **ace-core**: Configuration management and shared utilities
- **ace-context**: Project context loading with smart caching
- **ace-test-runner**: Test execution and CI integration
- **ace-test-support**: Testing infrastructure and helpers
- **ace-taskflow**: Task and release management with dependencies and tree visualization
- **ace-nav**: Resource discovery and navigation with wfi:// protocol support
- **ace-llm**: Multi-provider AI model integration with client registry

## Coming Soon

- **ace-search**: Unified file and content search across codebases
- **ace-git**: Enhanced git operations and smart commit generation
- **ace-review**: Code review automation and synthesis
- **ace-handbook**: Workflows, guides, and templates as a gem

## The Vision

Every development capability becomes an installable Ruby gem. Prompts, agents, and workflows are embedded within thematic gems rather than generic bundles. Install with `gem install ace-*` and use immediately - whether you're a human developer or an AI agent.

---

*ACE: Making AI-assisted development as simple as `gem install`.*


```

## Commands

### Command: `pwd`

**Output:**
```
/Users/mc/Ps/ace-meta

```

### Command: `date`

**Output:**
```
Mon Sep 29 19:39:42 WEST 2025

```

### Command: `git status --short`

**Output:**
```
 M .ace-taskflow/v.0.9.0/t/041-feat-taskflow-move-done-and-reschedule/task.041.md
 M .cache/ace-context/project.md
 M ace-git-commit/.ace.example/protocols/prompt-sources/ace-git-commit.yml
 M ace-git-commit/.ace.example/protocols/wfi-sources/ace-git-commit.yml
 M ace-nav/.ace.example/protocols/prompt.yml
 M ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb
?? .ace/protocols/prompt-sources/
?? .ace/protocols/prompt.yml
?? .ace/protocols/wfi-sources/ace-git-commit.yml
?? ace-git-commit/handbook/prompts/git-commit.md
?? ace-taskflow/lib/ace/taskflow/molecules/idea_directory_mover.rb
?? ace-taskflow/lib/ace/taskflow/molecules/task_directory_mover.rb

```

### Command: `task-manager recent --limit 3`

**Output:**
```
Status: No tasks found
No recent tasks found

```

### Command: `task-manager next --limit 3`

**Output:**
```

```

### Command: `release-manager current`

**Output:**
```

```

### Command: `eza -R -1 -L 2 --git-ignore --absolute $PROJECT_ROOT_PATH`

**Output:**
```
/Users/mc/Ps/ace-meta/ace-context
/Users/mc/Ps/ace-meta/ace-core
/Users/mc/Ps/ace-meta/ace-git-commit
/Users/mc/Ps/ace-meta/ace-llm
/Users/mc/Ps/ace-meta/ace-llm-providers-cli
/Users/mc/Ps/ace-meta/ace-nav
/Users/mc/Ps/ace-meta/ace-taskflow
/Users/mc/Ps/ace-meta/ace-test-runner
/Users/mc/Ps/ace-meta/ace-test-support
/Users/mc/Ps/ace-meta/bin
/Users/mc/Ps/ace-meta/CHANGELOG.md
/Users/mc/Ps/ace-meta/CLAUDE.md
/Users/mc/Ps/ace-meta/dev-handbook
/Users/mc/Ps/ace-meta/dev-local
/Users/mc/Ps/ace-meta/dev-tools
/Users/mc/Ps/ace-meta/docs
/Users/mc/Ps/ace-meta/Gemfile
/Users/mc/Ps/ace-meta/Gemfile.lock
/Users/mc/Ps/ace-meta/migrate-taskflow.sh
/Users/mc/Ps/ace-meta/mise.toml
/Users/mc/Ps/ace-meta/Rakefile
/Users/mc/Ps/ace-meta/README.md
/Users/mc/Ps/ace-meta/reflections

```