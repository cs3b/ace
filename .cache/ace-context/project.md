# Context

## Metadata

- **embed_document_source**: true
- **frontmatter**: {"description" => "project wide context"}
- **preset_name**: project

## Files

<file path="docs/what-do-we-build.md">
# Coding Agent Workflow Toolkit

## What We Build 🔍

The **Coding Agent Workflow Toolkit** is a comprehensive meta-system that provides both **development handbook workflows** and **executable tools** to enable seamless AI-assisted software development. It combines structured workflow instructions for autonomous AI agents with a robust CLI toolkit (Coding Agent Tools - CAT) that provides tools for LLM integration, Git automation, and project management.

The system bridges the gap between human developers and AI coding agents by offering:
- **Standardized workflow instructions** that AI agents can execute independently
- **Predictable CLI tools** for common development operations
- **Documentation-driven task management** integrated with executable tooling
- **Multi-provider LLM integration** with cost tracking and caching

By providing both the "what to do" (workflows) and "how to do it" (tools), the toolkit enables developers and AI agents to collaborate effectively on higher-value design and coding activities.

## ✨ Key Features

### Workflow Instructions & Agents
- **Self-Contained AI Workflows**: Structured workflow instructions that AI agents can execute independently
- **Specialized Development Agents**: Task-focused agents for Git operations, task management, code review, and more
- **Development Handbook**: Comprehensive guides, templates, and best practices for consistent development
- **Documentation-Driven Task Management**: Organized approach to tracking and managing development work
- **Template Synchronization**: Automated management of embedded templates across workflows

### Executable Tools & Automation
- **Multi-Provider LLM Communication**: Unified interface for interacting with various language models
- **Enhanced Git Workflow Automation**: Tools for intelligent commit messages and repository management
- **Task Management Utilities**: Commands for navigating and tracking development tasks
- **Code Review Automation**: Tools for systematic code quality improvement
- **Offline Support**: Full capability to work with local language models for privacy and speed


## Target Use Cases

### Primary Use Cases

- **Automated Development Workflows**: AI coding agents using CAT commands to perform tasks like committing code, querying models, or finding the next work item within CI/CD pipelines or local development environments.
- **Accelerated Project Setup**: Developers quickly initializing Git repositories and setting up remotes with standardized commands.
- **Streamlined Commit Process**: Developers generating informative and consistent commit messages automatically based on their code changes and intent.
- **Efficient Task Navigation**: Developers and agents easily identifying and tracking development tasks within a structured documentation system.

### Secondary Use Cases

- **Offline AI Interaction**: Developers and agents interacting with local language models via LM Studio for rapid iteration or sensitive tasks.
- **Integrating with Documentation**: Utilizing CAT commands to manage task backlogs defined within documentation files.

## User Personas

### Primary Users

**Alex – AI Coding Agent**: An automated system designed to perform coding tasks.

- Needs: A deterministic and stable CLI surface to reliably execute development and operations steps.
- Goals: Successfully complete assigned coding and Dev Ops tasks without manual intervention.
- Pain Points: Brittle and inconsistent ad-hoc shell scripts that cause workflow failures.

**Sam – Senior Dev**: An experienced software engineer focused on efficient development.

- Needs: Rapidly set up new project remotes, easily craft descriptive and atomic commits.
- Goals: Reduce time spent on routine Git and project setup chores; maintain a clean and traceable commit history.
- Pain Points: Forgetting push URLs for new repositories, struggling to write clear and concise commit messages for complex changes.

### Secondary Users

**Priya – DX Engineer**: An engineer focused on improving the developer experience.

- Context: Priya uses CAT as a foundation for building standardized, testable, and extendable developer tools and workflows within their organization. They need a framework that follows Ruby best practices and is easy to integrate and extend.


## Project Boundaries

### Distribution Model

The Coding Agent Workflow Toolkit uses a **multi-repository architecture** coordinated through Git submodules, enabling both comprehensive development environment setup and flexible library integration when needed.

### What We Build

- **Comprehensive workflow instruction system** with self-contained AI workflows that agents can execute independently
- **Specialized AI agents** designed for focused development tasks, compatible with multiple AI platforms
- **Development handbook** providing guides, templates, and best practices for consistent development
- **CLI toolkit** (Coding Agent Tools) with executables for development automation and LLM integration
- **Multi-provider LLM integrations** supporting both online and offline language models
- **Documentation-driven task management** system for organizing and tracking development work
- **Multi-repository coordination** enabling seamless work across interconnected components


## Value Proposition

### Problems We Solve

1. **Inconsistent Automation**: Replaces ad-hoc, project-specific scripts with a standardized, testable, and maintainable toolkit.
2. **Agent Orchestration Gap**: Provides coding agents with reliable, deterministic tools to perform common development and Dev Ops tasks they currently struggle with.
3. **Dev Ops Overhead**: Automates routine tasks like repository creation and commit message generation, reducing manual effort for developers.

### Unique Advantages

- **AI-Native Design**: Built specifically with the needs of AI coding agents in mind, offering a robust and predictable interface.
- **Documentation-Driven**: Designed to integrate with documentation-based workflows and task management.
- **Opinionated but Extendable**: Provides strong conventions while allowing for customization and extension of specific tools and workflows.
- **Offline Capability**: Supports interaction with local LLMs for enhanced privacy and speed.

## Future Vision

The Coding Agent Workflow Toolkit aims to become the standard foundation for AI-assisted software development, enabling seamless collaboration between human developers and AI agents. We envision a future where development teams leverage intelligent automation for routine tasks while focusing their expertise on creative problem-solving and system design.


---

*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*

</file>

<file path="docs/architecture.md">
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
- **Purpose**: CLI tools submodule for development automation
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
2. **Ruby Environment**: Bundle installation in dev-tools submodule directory
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
- **Tools-Specific**: `docs/decisions/ADR-*.t.md` (dev-tools implementation)

The decisions.md file is automatically maintained by the `update-context-docs` workflow to ensure it stays current with all ADRs.

---

*This document should be updated when significant structural changes are made to the system architecture. For tools-specific technical details, see [Tools Architecture](./architecture-tools.md).*

</file>

<file path="docs/decisions.md">
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
</file>

<file path="docs/blueprint.md">
# Project Blueprint: Coding Agent Workflow Toolkit (Meta)

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Project Organization

This is a **meta-repository** using Git submodules to organize different aspects of the workflow toolkit:

- **dev-handbook/** - Development resources and workflows (Git submodule)
  - **guides/** - Best practices and standards for development
  - **tools/** - Utility scripts to support development workflows
  - **workflow-instructions/** - Structured commands for AI agents
  - **templates/** - Project templates and document templates
  - **zed/** - Editor integration

- **dev-taskflow/** - Project-specific documentation and task management (Git submodule)
  - **backlog/** - Pending tasks for future releases
  - **current/** - Active release cycle work
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **dev-tools/** - CLI tools submodule for LLM integration (Git submodule)
  - **lib/** - Ruby source code, organized by the ATOM architecture pattern
    - **coding_agent_tools/** - Main module
      - **atoms/** - Basic utilities and low-level components
      - **molecules/** - Composed operations and behavior-oriented helpers
      - **organisms/** - Business logic and complex orchestration
      - **ecosystems/** - Complete workflows and system-level coordination
      - **models/** - Data structures and pure data carriers
      - **cli/** - CLI command classes
      - **middlewares/** - Cross-cutting concerns
  - **spec/** - RSpec test files (unit, integration, CLI)
  - **exe/** - Executable CLI tools for LLM integration (25+ commands)
  - **docs/** - Tools-specific documentation (moved from root)

- **docs/** - Core project documentation (permanent reference materials)
  - **decisions/** - Architecture Decision Records (ADRs)
  - **migrations/** - Documentation migration records


## Read-Only Paths

AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `dev-handbook/guides/**/*` # Development guides (submodule)
- `dev-handbook/workflow-instructions/**/*` # AI workflow instructions (submodule)
- `dev-handbook/templates/**/*` # Project templates (submodule)
- `dev-taskflow/done/**/*` # Completed tasks should not be modified
- `dev-taskflow/current/*/handbook_review/**/*` # Historical review snapshots
- `dev-taskflow/*/handbook_review/**/*` # All historical review snapshots
- `dev-tools/lib/**/*` # Ruby source code (submodule)
- `dev-tools/spec/**/*` # Test files (submodule)
- `dev-tools/exe/**/*` # CLI executables (submodule)
- `*.lock` # Dependency lock files
- `package-lock.json` # Node.js dependency lock
- `dev-tools/Gemfile.lock` # Ruby dependency lock

## Ignored Paths

AI agents should generally ignore the contents of the following paths during normal operations:

- `dev-taskflow/done/**/*` # Completed tasks and releases
- `dev-taskflow/sessions/**/*` # Session logs
- `node_modules/**/*` # Node.js dependencies
- `dev-tools/vendor/**/*` # Bundler dependencies
- `tmp/**/*` # Temporary files
- `log/**/*` # Log files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `coverage/**/*` # Test coverage reports
- `.idea/**/*`, `.vscode/**/*` # Editor configurations
- `**/.*.swp`, `**/.*.swo` # Swap files
- `**/.DS_Store` # macOS system files
- `**/Thumbs.db` # Windows system files
- `**/.env` # Environment files
- `**/.env.*` # Environment variants
- `*.session.log` # Session logs
- `*.lock` # Lock files
- `*.tmp` # Temporary files
- `*~` # Backup files

</file>

<file path="docs/tools.md">
# Coding Agent Tools - Development Tools Reference

## Main Cheat-sheet

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| **`search`** | **Unified intelligent search** | **`--files`, `--preset`, `--fzf`** |
| `code-review` | Preset-based code review | `--preset`, `--context` |
| `code-review-synthesize` | Review synthesis tool | `--format` |
| `create-path` | Create files/directories | `--force`, `--content` |
| `git-add` | Enhanced git add | `--patch`, `--all` |
| `git-commit` | Enhanced git commit | `--intention`, `--no-edit` |
| `git-fetch` | Enhanced git fetch | `--all`, `--prune` |
| `git-log` | Enhanced git log | `--oneline`, `--graph` |
| `git-pull` | Enhanced git pull | `--rebase`, `--ff-only` |
| `git-push` | Enhanced git push | `--force`, `--dry-run` |
| `git-status` | Enhanced git status | `--verbose`, `--short` |
| `git-tag` | Enhanced git tag | `--annotate`, `--delete` |
| `handbook` | Development handbook access | `sync-templates` |
| `llm-query` | Unified LLM query | `--model`, `--output` |
| `nav-ls` | Enhanced directory listing | `--long`, `--all` |
| `nav-path` | Intelligent path navigation | `task`, `file` |
| `nav-tree` | Enhanced project tree | `--context`, `--depth` |
| `reflection-synthesize` | Reflection report generator | `--session`, `--focus` |
| `release-manager` | Release management | `current`, `report` |
| `task-manager` | Project task management | `--filter`, `--sort` |

## Persona Cheat-sheets

### AI Agent

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `task-manager` | Manage tasks | `--filter`, `--sort` |
| `llm-query` | Query AI models | `--model`, `--output` |
| `nav-path` | Navigate paths | `task`, `file` |
| `release-manager` | Manage releases | `current`, `report` |

### Human Developer

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `code-review` | Review code | `--preset`, `--model` |
| `handbook` | Access guides | `sync-templates` |
| `reflection-synthesize` | Generate reports | `--session`, `--focus` |

### Git Power-User

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `git-add` | Stage files | `--patch`, `--all` |
| `git-commit` | Smart commit | `--intention` |
| `git-status` | Check status | `--verbose` |
| `git-tag` | Manage tags | `--annotate` |

### Release Manager

| Tool | Purpose | Key Flags |
|------|---------|-----------|
| `release-manager` | Coordinate releases | `current`, `report` |
| `task-manager` | Track deliverables | `--filter`, `--sort` |

## Setup Requirements

### Dependencies

* **Ruby** >= 3.2.0
* **Bundler** for dependency management
* **Git** CLI for repository operations
* **dev-handbook** submodule for task management utilities

### Environment Setup

```bash
# Initial setup (run from dev-tools/ directory)
cd dev-tools && bundle install

# Load Ruby console with gem loaded
cd dev-tools && bundle exec irb -r ./lib/coding_agent_tools
```

## Gem Executables

### `search` – Fast unified search for files and content
<details><summary>Details</summary>

```bash
search [PATTERN] [OPTIONS]
```

**Key flags:** `--files` (file search), `--preset NAME` (use preset), `--fzf` (interactive)

**Example:**
```bash
search "TODO" --preset todo  # Find all TODO comments
```
</details>

### `code-review` – Preset-based code review with context integration
<details><summary>Details</summary>

```bash
code-review [OPTIONS]
```

**Key flags:** `--preset NAME` (review preset), `--context FILE` (context file)

**Example:**
```bash
code-review --preset architecture  # Review architecture changes
```
</details>

### `code-review-synthesize` – Synthesize code review results
<details><summary>Details</summary>

```bash
code-review-synthesize [OPTIONS]
```

**Key flags:** `--format FORMAT` (output format)

**Example:**
```bash
code-review-synthesize --format markdown  # Generate markdown report
```
</details>

### `create-path` – Create files/directories with templates
<details><summary>Details</summary>

```bash
create-path PATH [OPTIONS]
```

**Key flags:** `--force` (overwrite), `--content TEXT` (file content)

**Example:**
```bash
create-path docs/new-guide.md --content "# Guide"  # Create with content
```
</details>

### `git-add` – Enhanced git add with smart staging
<details><summary>Details</summary>

```bash
git-add [FILES] [OPTIONS]
```

**Key flags:** `--patch` (interactive), `--all` (all changes)

**Example:**
```bash
git-add --patch  # Interactive staging
```
</details>

### `git-commit` – Enhanced git commit with intentions
<details><summary>Details</summary>

```bash
git-commit [OPTIONS]
```

**Key flags:** `--intention TYPE` (commit type), `--no-edit` (skip editor)

**Example:**
```bash
git-commit --intention fix  # Create fix commit
```
</details>

### `git-fetch` – Enhanced git fetch
<details><summary>Details</summary>

```bash
git-fetch [OPTIONS]
```

**Key flags:** `--all` (all remotes), `--prune` (remove deleted)

**Example:**
```bash
git-fetch --all --prune  # Fetch all and cleanup
```
</details>

### `git-log` – Enhanced git log display
<details><summary>Details</summary>

```bash
git-log [OPTIONS]
```

**Key flags:** `--oneline` (compact), `--graph` (show graph)

**Example:**
```bash
git-log --oneline --graph  # Visual commit history
```
</details>

### `git-pull` – Enhanced git pull
<details><summary>Details</summary>

```bash
git-pull [OPTIONS]
```

**Key flags:** `--rebase` (rebase instead), `--ff-only` (fast-forward only)

**Example:**
```bash
git-pull --rebase  # Pull with rebase
```
</details>

### `git-push` – Enhanced git push
<details><summary>Details</summary>

```bash
git-push [OPTIONS]
```

**Key flags:** `--force` (force push), `--dry-run` (preview)

**Example:**
```bash
git-push --dry-run  # Preview push changes
```
</details>

### `git-status` – Enhanced git status
<details><summary>Details</summary>

```bash
git-status [OPTIONS]
```

**Key flags:** `--verbose` (detailed), `--short` (compact)

**Example:**
```bash
git-status --short  # Compact status view
```
</details>

### `git-tag` – Enhanced git tag management
<details><summary>Details</summary>

```bash
git-tag [TAGNAME] [OPTIONS]
```

**Key flags:** `--annotate` (annotated tag), `--delete` (delete tag)

**Example:**
```bash
git-tag v1.0.0 --annotate  # Create annotated tag
```
</details>

### `handbook` – Development handbook access
<details><summary>Details</summary>

```bash
handbook [COMMAND] [OPTIONS]
```

**Key flags:** `sync-templates` (sync templates)

**Example:**
```bash
handbook sync-templates  # Sync project templates
```
</details>

### `llm-query` – Unified LLM query interface
<details><summary>Details</summary>

```bash
llm-query PROMPT [OPTIONS]
```

**Key flags:** `--model NAME` (model selection), `--output FILE` (save output)

**Examples:**
```bash
llm-query "Explain this code" --model gpt4     # Query with GPT-4
llm-query "Review this code" codex:o3          # Query with Codex o3
llm-query "Hello world" codex:o3-mini         # Query with Codex o3-mini
llm-query "Local help" codexoss:llama3        # Query with Codex OSS (Ollama)
```
</details>

### `nav-ls` – Enhanced directory listing
<details><summary>Details</summary>

```bash
nav-ls [PATH] [OPTIONS]
```

**Key flags:** `--long` (detailed), `--all` (show hidden)

**Example:**
```bash
nav-ls --long --all  # Detailed listing with hidden files
```
</details>

### `nav-path` – Intelligent path navigation
<details><summary>Details</summary>

```bash
nav-path COMMAND [ARGS]
```

**Key flags:** `task` (find task), `file` (find file)

**Example:**
```bash
nav-path file blueprint  # Find blueprint file
```
</details>

### `nav-tree` – Enhanced project tree view
<details><summary>Details</summary>

```bash
nav-tree [PATH] [OPTIONS]
```

**Key flags:** `--context` (with context), `--depth N` (tree depth)

**Example:**
```bash
nav-tree --depth 2  # Show 2-level tree
```
</details>

### `reflection-synthesize` – Generate reflection reports
<details><summary>Details</summary>

```bash
reflection-synthesize [OPTIONS]
```

**Key flags:** `--session ID` (session), `--focus AREA` (focus area)

**Example:**
```bash
reflection-synthesize --session today  # Today's reflection
```
</details>

### `release-manager` – Release management tool
<details><summary>Details</summary>

```bash
release-manager COMMAND [OPTIONS]
```

**Key flags:** `current` (current release), `report` (generate report)

**Example:**
```bash
release-manager current  # Show current release
```
</details>

### `task-manager` – Project task management
<details><summary>Details</summary>

```bash
task-manager [COMMAND] [OPTIONS]
```

**Key flags:** `--filter STATUS` (filter tasks), `--sort FIELD` (sort by)

**Example:**
```bash
task-manager --filter pending  # Show pending tasks
```
</details>

## Workflow Integration

### Finding Files
```bash
search "*.rb" --files  # Find Ruby files
nav-path file spec  # Navigate to spec file
```

### Managing Tasks
```bash
task-manager --filter pending  # List pending tasks
nav-path task 001  # Navigate to task
```

### Git Workflow
```bash
git-status --short  # Quick status check
git-add --patch  # Interactive staging
git-commit --intention feat  # Feature commit
```

### Code Review
```bash
code-review --preset security  # Security review
code-review-synthesize  # Generate report
```
</file>

## Commands

<output command="git status --short" success="true">

 M Gemfile
 M Gemfile.lock
 M ace-core/test-reports/latest
 M ace-test-runner/lib/ace/test_runner/suite/display_manager.rb
 M ace-test-runner/lib/ace/test_runner/suite/process_monitor.rb
 M ace-test-runner/lib/ace/test_runner/suite/result_aggregator.rb
 M ace-test-support/lib/ace/test_support/test_environment.rb
 M docs/context/project.md
 M mise.toml
?? .cache/
?? .github/
?? CI.md
?? Rakefile
?? ace-test-support/test/
?? run_all_tests.rb
?? test_auto_discovery_feature.rb
?? test_auto_discovery_final.rb
?? test_discovery_debug.rb

</output>

<output command="task-manager recent --limit 3" success="true">

Status: 12 done, 4 pending (16 total)
Recent Tasks (3/501 shown):
==================================================
v.0.9.0+task.016 * DONE * 1 hours ago * Implement Smart Caching for ace-context
  dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.016-implement-smart-caching-for-ace-context.md
v.0.9.0+task.005 * DONE * 3 hours ago * Create ace-context Gem
  dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.005-create-ace-context-gem.md
v.0.9.0+task.008 * PENDING * 3 hours ago * Configure .ace for This Project
  dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.008-configure-ace-for-this-project.md

</output>

<output command="task-manager next --limit 3" success="true">

Status: 12 done, 4 pending (16 total)
Next Tasks (3 shown):
==================================================
v.0.9.0+task.006 * PENDING * 1 days ago * Create ace-capture Gem
  dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.006-create-ace-capture-gem.md
v.0.9.0+task.007 * PENDING * 1 days ago * Create ace-git Gem with ace-gc Only
  dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.007-create-ace-git-gem-with-ace-gc.md
v.0.9.0+task.008 * PENDING * 3 hours ago * Configure .ace for This Project
  dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems/tasks/v.0.9.0+task.008-configure-ace-for-this-project.md

</output>

<output command="release-manager current" success="true">

Current Release Information:
========================================
  Name:      v.0.9.0-mono-repo-multiple-gems
  Version:   v.0.9.0
  Path:      /Users/mc/Ps/ace-meta/dev-taskflow/current/v.0.9.0-mono-repo-multiple-gems
  Status:    active
  Tasks:     16
  Created:   2025-09-19 17:32:53
  Modified:  2025-09-19 17:04:08

</output>

<output command="eza -R -1 -L 2 --git-ignore --absolute $PROJECT_ROOT_PATH" success="true">

/Users/mc/Ps/ace-meta/ace-context
/Users/mc/Ps/ace-meta/ace-core
/Users/mc/Ps/ace-meta/ace-test-runner
/Users/mc/Ps/ace-meta/ace-test-support
/Users/mc/Ps/ace-meta/BACKWARD_COMPATIBILITY_IMPLEMENTATION.md
/Users/mc/Ps/ace-meta/bin
/Users/mc/Ps/ace-meta/CHANGELOG.md
/Users/mc/Ps/ace-meta/CI.md
/Users/mc/Ps/ace-meta/CLAUDE.md
/Users/mc/Ps/ace-meta/dev-handbook
/Users/mc/Ps/ace-meta/dev-local
/Users/mc/Ps/ace-meta/dev-taskflow
/Users/mc/Ps/ace-meta/dev-tools
/Users/mc/Ps/ace-meta/docs
/Users/mc/Ps/ace-meta/Gemfile
/Users/mc/Ps/ace-meta/Gemfile.lock
/Users/mc/Ps/ace-meta/mise.toml
/Users/mc/Ps/ace-meta/Rakefile
/Users/mc/Ps/ace-meta/README.md
/Users/mc/Ps/ace-meta/run_all_tests.rb
/Users/mc/Ps/ace-meta/test_auto_discovery_feature.rb
/Users/mc/Ps/ace-meta/test_auto_discovery_final.rb
/Users/mc/Ps/ace-meta/test_backward_compatibility.rb
/Users/mc/Ps/ace-meta/test_discovery_debug.rb
/Users/mc/Ps/ace-meta/test_template_discovery.rb

</output>

<output command="date" success="true">

Sun Sep 21 02:01:02 WEST 2025

</output>