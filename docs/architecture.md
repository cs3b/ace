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

### Workflows (.wf.md)

Self-contained instruction documents for AI agents:

- Located in `dev-handbook/workflow-instructions/`
- Include all necessary context and templates
- Follow ADR-001 self-containment principle

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
- **ace-taskflow**: Task and release management
- **ace-git**: Enhanced git operations
- **ace-llm**: Multi-provider LLM integration

### Vision

Every development capability becomes an installable Ruby gem. Prompts, agents, and workflows are embedded within thematic gems, making them instantly available through `gem install ace-*`.

---

*For detailed architectural decisions, see [docs/decisions.md](decisions.md)*

