# ACE (Agent Coding Environment) - System Architecture

## Overview

This document outlines the system architecture and technical design decisions for ACE, a mono-repo ecosystem of modular Ruby gems that enable AI-assisted software development.

For detailed implementation patterns, see the individual gem READMEs in their respective directories.

## Core Design Principles

### System-Level Principles
- **Mono-Repo Architecture**: Single repository with modular ace-* gems for clear separation of concerns
- **ATOM Pattern Consistency**: All gems follow the same Atoms, Molecules, Organisms, Models structure
- **Zero-Dependency Core**: ace-core has no external dependencies, using only Ruby standard library
- **Configuration Cascade**: Hierarchical .ace/ configuration with nearest/deepest wins resolution
- **AI-Native Design**: Built specifically with autonomous AI agent capabilities and limitations in mind

### Implementation Principles
- **ATOM Architecture**: Structured around Atoms (pure functions), Molecules (composed operations), Organisms (business logic), and Models (data structures) (per ADR-011)
- **Test-Driven Development**: Comprehensive testing with shared ace-test-support infrastructure, Minitest for unit tests
- **Predictable CLI**: Deterministic commands where agents and humans use the same interface
- **Gem Modularity**: Each ace-* gem has focused functionality with explicit dependencies
- **CI/CD Integration**: GitHub Actions matrix testing across multiple Ruby versions

## Technology Stack

### Core Technology Choices
- **Primary Language**: Ruby (>= 3.2) - Chosen for its expressiveness, developer productivity, and suitability for scripting and tooling
- **Runtime**: MRI (C Ruby) >= 3.2 - Standard and widely adopted Ruby implementation
- **Architecture Pattern**: ATOM (Atoms, Molecules, Organisms, Ecosystems) - Guiding principle for structuring the codebase

### Technical Infrastructure
- **Coordination**: Root Gemfile with path-based gem references for workspace management
- **Documentation**: Markdown with embedded templates and context documents
- **Configuration**: YAML-based cascade resolution through .ace/ directories
- **Testing Framework**: ace-test-support providing shared infrastructure, Minitest for assertions
- **Test Execution**: ace-test-runner with parallel processing and CI optimization
- **Caching**: Smart caching in ace-context with file-based persistence
- **ATOM Components**: Consistent patterns across all gems for maintainability

### External Integrations
- **LLM Providers**: Google Gemini, OpenAI, Anthropic, Mistral, Together AI, LM Studio (per ADR-014)
- **Cost Tracking**: LiteLLM pricing database for accurate cost calculations
- **Version Control**: Git CLI, GitHub REST API

### Security Architecture
- **Path Validation**: Multi-layer validation for file operations
- **Sanitization**: Automatic sanitization of sensitive information
- **Secure Logging**: Privacy-preserving log output
- **Defense in Depth**: Multiple validation layers

## System Architecture

## Mono-Repo Architecture

ACE uses a mono-repo structure with modular Ruby gems at the repository root:

### Current ace-* Gems (Operational)

#### ace-core (Foundation)
- **Purpose**: Zero-dependency configuration management and shared primitives
- **Key Features**:
  - Configuration cascade resolution (.ace/settings.yml)
  - Environment variable management
  - Deep hash merging utilities
  - Path expansion and normalization
- **Architecture**: Pure Ruby standard library, no external dependencies

#### ace-context (Context Loading)
- **Purpose**: Intelligent context loading with caching and multi-format output
- **Key Features**:
  - Smart caching with file modification detection
  - Multi-format output (YAML, JSON, TOML, XML)
  - Template processing with variable substitution
  - Command execution integration
- **Dependencies**: ace-core for configuration

#### ace-test-runner (Test Execution)
- **Purpose**: Comprehensive test execution with parallel processing
- **Key Features**:
  - Multi-source test discovery
  - Parallel execution support
  - CI-optimized output modes
  - ace-test-suite for CI environments
- **Dependencies**: ace-core, ace-test-support

#### ace-test-support (Testing Infrastructure)
- **Purpose**: Shared testing utilities and infrastructure
- **Key Features**:
  - TestEnvironment for isolated testing
  - ConfigHelpers for configuration testing
  - Minitest extensions and assertions
  - Fixture management
- **Dependencies**: minitest, ace-core

### Legacy Components (Being Migrated)

- **dev-handbook/**: Workflows and agents (migrating to ace-handbook)
- **dev-tools/**: CLI tools (migrating to individual ace-* gems)
- **dev-taskflow/**: Task management (migrating to ace-taskflow)

## Integration & Data Flow

### How Components Connect

1. **Workflows & Agents**: Defined in `dev-handbook/`, exposed to Claude Code through:
   - Commands: `.claude/commands/` directory with workflow mappings
   - Subagents: `.integrations/claude/agents/` for specialized task execution

2. **CLI Tools**: Available system-wide through shell integration:
   - Fish: `source dev-tools/config/bin-setup-env/setup.fish`
   - Bash/Zsh: Similar setup scripts
   - Direct PATH access for all agents and workflows

3. **Agent Access**: AI agents have full access to:
   - All CLI tools via PATH
   - Workflow instructions via commands
   - Other agents via Task tool delegation

### Example: Context Loading Flow with ace-context

How the ace-context gem processes a context request:

1. **User Action**: Executes `ace-context --preset project`
2. **Configuration Loading**: ace-core resolves .ace/context.yml through cascade
3. **Cache Check**: ace-context checks for valid cached content
4. **Template Processing**: Loads template with variable substitution
5. **File Embedding**: Processes file inclusions based on preset configuration
6. **Command Execution**: Runs specified commands (git status, task-manager, etc.)
7. **Smart Caching**: Saves output with modification timestamps
8. **Format Output**: Returns in specified format (YAML, JSON, etc.)
9. **Result**: Provides complete context with 1000+ lines of structured information

### Other Key Workflows

**TODO**: Document detailed flows for:
- `work-on-task` workflow - Task execution from selection to completion
- `draft-release` workflow - Release preparation and coordination
- Agent delegation patterns - How agents invoke each other


## Agent Architecture

### Gem Integration with AI Agents

Ace gems provide CLI tools that AI agents can execute directly:

#### Current Tools
- **ace-context**: Context loading for project understanding
- **ace-test**: Individual test execution with detailed output
- **ace-test-suite**: CI-optimized test suite execution

#### Planned Tools (Future ace-* gems)
- **ace-git**: Enhanced git operations (ace-gc, ace-commit, etc.)
- **ace-llm**: Multi-provider LLM integration
- **ace-handbook**: Workflow and agent management
- **ace-taskflow**: Task and release management

#### Compatibility Architecture
Agents are designed with multi-platform compatibility in mind:
- **Claude Code Subagents**: Primary integration through Claude's Task tool with `subagent_type` parameter
- **MCP Proxy Integration**: Compatible with the MCP (Model Context Protocol) proxy we're developing for broader AI platform support
- **Future OpenCode Support**: Architecture designed for direct integration with OpenCode and similar platforms

#### Agent Design Principles
- **Single Purpose**: Each agent performs one focused task exceptionally well
- **Standardized Response Format**: Consistent output structure across all agents
- **Parameter Support**: Accept `expected_params` for configuration
- **Composition Ready**: Agents can delegate to each other for complex workflows

## Integration Patterns

### AI Agent Integration
- Direct CLI execution via agent tools
- Structured workflow instructions (.wf.md)
- Specialized agent invocation through platform-specific interfaces
- Embedded template system
- Documentation-driven task tracking

### Human Developer Integration
- Enhanced CLI tools for productivity
- Development guides and templates
- Multi-repository coordination

### CI/CD Integration
- Batch processing support
- Non-interactive execution modes
2. **Configuration Management**: Environment-based configuration
3. **Security Integration**: Safe defaults for automated environments
4. **Cost Tracking**: Comprehensive usage and cost monitoring

## Security Architecture

### System-Level Security

- **Repository Isolation**: Clear boundaries between different concerns
- **Access Control**: Appropriate file permissions and path restrictions
- **Credential Management**: Secure handling of API keys and tokens
- **Audit Trail**: Comprehensive logging of all operations

### Implementation Security

- **Path Validation**: Prevent directory traversal attacks
- **Input Sanitization**: Clean all user inputs and file paths
- **Secure Logging**: Automatic redaction of sensitive information
- **Operation Confirmation**: Safe defaults with confirmation prompts

## Performance Considerations

### System-Level Performance

- **Submodule Efficiency**: Minimal overhead for multi-repository coordination
- **Documentation Speed**: Fast template synchronization and analysis
- **Task Management**: Efficient file-based task tracking

### Implementation Performance

- **Startup Speed**: ≤ 200ms CLI command initialization
- **Caching Strategy**: XDG-compliant caching with intelligent invalidation
- **HTTP Optimization**: Connection pooling, retry logic, and timeout management
- **Memory Efficiency**: Minimal memory footprint with lazy loading

## Developer Environment Setup

ACE is designed exclusively for developer environments:

1. **Repository Setup**: Clone the mono-repo
2. **Ruby Environment**: `bundle install` at repository root
3. **Gem Development**: Use `bundle exec` for gem commands
4. **Testing**: Run `bundle exec rake test` in each gem directory
5. **CI Integration**: GitHub Actions automatically tests across Ruby 3.0, 3.1, 3.2

This is a developer toolkit - there is no production deployment. All components run locally in the developer's environment.


## Architectural Decisions

All architectural decisions are documented in Architecture Decision Records (ADRs). 

**For actionable decisions and their impacts**, see: `docs/decisions.md`

This consolidated document provides:
- Core decisions that affect development behavior
- Direct impacts on how agents and developers work
- Links to full ADR documents for detailed context

ADRs are organized by scope:
- **System-Level**: `docs/decisions/ADR-*.md` (architecture, workflows, gem migration)
- **Tools-Specific**: `docs/decisions/ADR-*.t.md` (implementation patterns)
- **Gem-Specific**: Future ADRs in individual gem directories

The decisions.md file is automatically maintained by the `update-context-docs` workflow to ensure it stays current with all ADRs.

---

*This document should be updated when significant structural changes are made to the system architecture. For tools-specific technical details, see [Tools Architecture](./architecture-tools.md).*
