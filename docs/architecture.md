# Coding Agent Workflow Toolkit - System Architecture

## Overview

This document outlines the system architecture and technical design decisions for the Coding Agent Workflow Toolkit.

For detailed Ruby gem implementation, see [Tools Architecture](./architecture-tools.md).

## Core Design Principles

### System-Level Principles
- **Meta-Repository Architecture**: Multi-repository coordination using Git submodules for clear separation of concerns
- **Workflow Self-Containment**: AI workflows must be completely independent and executable without external dependencies (per ADR-001)
- **Documentation-Driven Development**: Workflows, tasks, and processes are documented first, then implemented
- **AI-Native Design**: Built specifically with autonomous AI agent capabilities and limitations in mind

### Implementation Principles
- **ATOM Architecture**: Structured around Atoms, Molecules, Organisms, and Ecosystems for maintainability and testability (per ADR-011)
- **Test-Driven Development**: High emphasis on testing with comprehensive unit and integration test coverage using RSpec
- **Predictable CLI**: Designing commands with ergonomic flags suitable for both human and agent interaction
- **Modularity**: Components are designed with explicit boundaries and dependency injection
- **Security-First**: Multi-layered security framework with path validation, sanitization, and secure logging

## Technology Stack

### Core Technology Choices
- **Primary Language**: Ruby (>= 3.2) - Chosen for its expressiveness, developer productivity, and suitability for scripting and tooling
- **Runtime**: MRI (C Ruby) >= 3.2 - Standard and widely adopted Ruby implementation
- **Architecture Pattern**: ATOM (Atoms, Molecules, Organisms, Ecosystems) - Guiding principle for structuring the codebase

### Technical Infrastructure
- **Coordination**: Git submodules for multi-repository management
- **Documentation**: Markdown with markdownlint validation
- **Template System**: XML-based embedding (per ADR-002)
- **CLI Framework**: dry-cli with comprehensive command structure
- **HTTP Client**: Faraday with retry middleware and observability (per ADR-010)
- **Testing**: RSpec with VCR for HTTP interaction recording (per ADR-006)
- **Autoloading**: Zeitwerk with proper inflections (per ADR-007)
- **Observability**: dry-monitor for event publishing (per ADR-008)
- **Error Handling**: Centralized ErrorReporter (per ADR-009)

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

## Multi-Repository Architecture

The toolkit uses Git submodules to coordinate four interconnected repositories:

### handbook-meta (Coordination Hub)
- **Purpose**: Central coordination and system-level documentation
- **Contents**: Core docs (what-do-we-build, architecture, blueprint, decisions), meta-level scripts
- **Role**: Provides unified view across all components

### dev-handbook (Workflows & Agents)
- **Purpose**: AI workflow instructions and specialized development agents
- **Contents**: 
  - Self-contained workflows (`.wf.md` files in `workflow-instructions/`)
  - Specialized agents (`.ag.md` files in `.integrations/claude/agents/`)
  - Development guides and templates
- **Integration**: Exposed to Claude Code via commands (`.claude/commands/`)

### dev-tools (Executable Tools)
- **Purpose**: Ruby gem with CLI tools for development automation
- **Contents**: 
  - ATOM-structured Ruby code (atoms/, molecules/, organisms/)
  - CLI executables in `exe/` directory
  - Shell integration scripts (`config/bin-setup-env/setup.fish`)
- **Integration**: Tools added to PATH for direct command-line access

### dev-taskflow (Task Management)
- **Purpose**: Documentation-driven task and release management
- **Contents**:
  - Task organization (backlog/, current/, done/)
  - Release planning and roadmap
  - Project-specific decisions
- **Role**: Central hub for work tracking and planning

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

### Example: Context Loading Flow

A concrete example of how the system components work together:

1. **User Action**: Runs Claude Code and types `/load-context`
2. **Command Mapping**: Claude Code maps to workflow instruction
3. **Tool Execution**: Workflow guides agent to run `context --preset project --output stdout`
4. **Configuration**: Tool reads `.coding-agent/context.yml` for settings
5. **Template Processing**: Based on config, uses template in `docs/context/project.md`
6. **File Embedding**: Template embeds multiple files according to configuration
7. **Command Execution**: Runs shell commands to add dynamic content
8. **Output**: Returns complete context with embedded documents (when `embed_document_source: true`)
9. **Result**: Agent receives pre-structured context, avoiding manual exploration

### Other Key Workflows

**TODO**: Document detailed flows for:
- `work-on-task` workflow - Task execution from selection to completion
- `draft-release` workflow - Release preparation and coordination
- Agent delegation patterns - How agents invoke each other


## Agent Architecture

### Specialized Development Agents

The toolkit includes specialized agents designed for focused development tasks, located in `dev-handbook/.integrations/claude/agents/`. Each agent follows a single-purpose design with standardized interfaces.

#### Agent Categories
- **Task Management**: `task-finder`, `task-creator`, `release-navigator`
- **Git Operations**: `git-all-commit`, `git-files-commit`, `git-review-commit`
- **Development Tools**: `lint-files`, `create-path`, `feature-research`
- **Search & Analysis**: `search` for intelligent code discovery

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

The toolkit is designed exclusively for developer environments:

1. **Repository Setup**: `git submodule update --init --recursive`
2. **Ruby Environment**: Bundle installation in dev-tools directory
3. **Shell Integration**: Source appropriate setup script for your shell
4. **API Configuration**: Set environment variables for LLM providers

This is a developer toolkit - there is no production deployment. All components run locally in the developer's environment.


## Architectural Decisions

All architectural decisions are documented in Architecture Decision Records (ADRs). 

**For actionable decisions and their impacts**, see: `docs/decisions.md`

This consolidated document provides:
- Core decisions that affect development behavior
- Direct impacts on how agents and developers work
- Links to full ADR documents for detailed context

ADRs are organized by scope:
- **System-Level**: `docs/decisions/ADR-*.md` (architecture, workflows)
- **Tools-Specific**: `docs/decisions/ADR-*.t.md` (Ruby gem implementation)

The decisions.md file is automatically maintained by the `update-context-docs` workflow to ensure it stays current with all ADRs.

---

*This document should be updated when significant structural changes are made to the system architecture. For tools-specific technical details, see [Tools Architecture](./architecture-tools.md).*
