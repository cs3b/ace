# Coding Agent Workflow Toolkit

## What We Build 🔍

The **Coding Agent Workflow Toolkit** is a comprehensive meta-system that provides both **development handbook workflows** and **executable tools** to enable seamless AI-assisted software development. It combines structured workflow instructions for autonomous AI agents with a robust Ruby gem (Coding Agent Tools - CAT) that provides CLI tools for LLM integration, Git automation, and project management.

The system bridges the gap between human developers and AI coding agents by offering:
- **Standardized workflow instructions** that AI agents can execute independently
- **Predictable CLI tools** for common development operations
- **Documentation-driven task management** integrated with executable tooling
- **Multi-provider LLM integration** with cost tracking and caching

By providing both the "what to do" (workflows) and "how to do it" (tools), the toolkit enables developers and AI agents to collaborate effectively on higher-value design and coding activities.

## ✨ Key Features

### Workflow Instructions & Documentation
- **Self-Contained AI Workflows**: 19+ structured workflow instructions (.wf.md) that AI agents can execute independently
- **Development Handbook**: Comprehensive guides, templates, and best practices organized by language and technology
- **Documentation-Driven Task Management**: Structured task organization with backlog/, current/, done/ workflow
- **Template Synchronization**: Embedded document templates with automatic synchronization

### Executable Tools (Ruby Gem - CAT)
- **Multi-Provider LLM Communication**: Unified interface supporting Google Gemini, OpenAI, Anthropic, Mistral, Together AI, and LM Studio
- **Model Discovery and Management**: List and filter available models from different providers with caching support
- **Cost Tracking & Analytics**: Comprehensive usage tracking with cost calculation using LiteLLM pricing database
- **Enhanced Git Workflow Automation**: 25+ CLI tools including intelligent commit message generation, multi-repo operations, and GitHub integration
- **Intelligent Navigation**: Smart project navigation with path resolution, task management, and directory listing
- **Task Management Utilities**: Commands to identify next actionable tasks, review recent work, and manage release cycles
- **Code Review Automation**: Interactive and batch code review tools with synthesis capabilities
- **Standardized Interface**: Consistent CLI and API surface designed for both human and AI agent interaction
- **Offline Support**: Full offline capability with local LM Studio integration and XDG-compliant caching

## Core Design Principles

### System-Level Principles
- **Meta-Repository Architecture**: Multi-repository coordination using Git submodules for clear separation of concerns
- **Workflow Self-Containment**: AI workflows must be completely independent and executable without external dependencies
- **Documentation-Driven Development**: Workflows, tasks, and processes are documented first, then implemented
- **AI-Native Design**: Built specifically with autonomous AI agent capabilities and limitations in mind

### Implementation Principles (Ruby Gem)
- **ATOM Architecture**: Structured around Atoms, Molecules, Organisms, and Ecosystems for maintainability, testability, and clear separation of concerns
- **Test-Driven Development**: High emphasis on testing with comprehensive unit and integration test coverage using RSpec
- **Predictable CLI**: Designing commands with ergonomic flags suitable for both human and agent interaction
- **Modularity**: Components are designed with explicit boundaries and dependency injection
- **Ruby Best Practices**: Adhering to standard Ruby conventions and practices
- **Security-First**: Multi-layered security framework with path validation, sanitization, and secure logging

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

## Success Metrics

### Primary Metrics

- **Time-to-Commit**: Reduce median time from code change to committed diff by **30%** within the pilot team (Target: ≤ 70% of original time).
- **Agent Adoption**: ≥ **80%** of automated CI runs invoke at least one CAT command.

### Secondary Metrics

- **Support Load**: ≤ **2** support tickets per week related to Git setup or task selection after 1 month post-launch.
- **Reliability**: CLI commands succeed ≥ **99%** over 1,000 automated invocations in testing/monitoring.

## Technology Philosophy

### Core Technology Choices

- **Primary Language**: Ruby - Chosen for its expressiveness, developer productivity, and suitability for scripting and tooling development.
- **Runtime**: MRI (C Ruby) ≥ 3.2 - Standard and widely adopted Ruby implementation.

### Technical Principles

- **ATOM Architecture**: Guiding principle for structuring the codebase into distinct, testable layers.
- **Focus on CLI/API**: Prioritizing a stable and well-documented interface for programmatic and human use.
- **External Dependency Management**: Explicitly managing dependencies and aiming for minimal, well-vetted external libraries.

## Project Boundaries

### Distribution Architecture

The Coding Agent Workflow Toolkit employs a **submodule-based distribution model** that reflects its nature as a comprehensive development environment rather than a single-purpose library:

- **Primary Distribution**: Multi-repository coordination via Git submodules (handbook-meta as coordination repository)
- **Component Repositories**: 
  - `dev-handbook/` - Development resources, workflows, guides, and templates
  - `dev-tools/` - Core Ruby gem with CLI tools and executables
  - `dev-taskflow/` - Task management, project planning, and release coordination
- **Secondary Distribution**: Traditional Ruby gem publication for library integration scenarios
- **Target Environment**: Complete development environments with integrated toolchain, task management, and documentation

This approach enables coordinated development across interconnected components while maintaining flexibility for library-style integration when needed.

### What We Build

#### Meta-System Components
- A comprehensive **workflow instruction system** with 19+ self-contained AI workflows
- **Development handbook** with guides, templates, and best practices
- **Documentation-driven task management** with structured release cycles
- **Multi-repository coordination tools** for managing the entire ecosystem

#### Ruby Gem (CAT) Components
- A Ruby gem (`coding_agent_tools`) installable via standard Ruby package managers (RubyGems, Bundler)
- A suite of **25+ CLI executables** for development automation and LLM integration
- Core **ATOM architecture components**:
  - **Atoms**: `XDGDirectoryResolver`, `SecurityLogger`, `EnvReader`
  - **Molecules**: `CacheManager`, `MetadataNormalizer`, `APICredentials`, `HTTPRequestBuilder`
  - **Organisms**: `GoogleClient`, `LMStudioClient`, `OpenaiClient`, `AnthropicClient`, `PromptProcessor`
  - **Ecosystems**: Complete workflow orchestration and system-level coordination
- **Multi-provider LLM integrations**: Google Gemini, OpenAI, Anthropic, Mistral, Together AI, LM Studio
- **Enhanced Git/GitHub integration** with intelligent automation
- **XDG-compliant caching system** with automatic migration
- **Comprehensive cost tracking** using LiteLLM pricing database
- **Security framework** with path validation and sanitized logging
- **Comprehensive unit and integration tests** with VCR cassette management
- **Extensive documentation** including architecture guides, user documentation, and API references

### What We Don't Build (v1)

- SDKs or libraries in languages other than Ruby.
- A full-featured graphical user interface (GUI) for Git or task management.
- Direct integrations with proprietary LLM endpoints other than those specified (e.g., direct OpenAI calls within the gem, although wrappers could be built by users).
- Real-time collaborative editing features.
- A complete replacement for robust ticketing systems (Jira, Asana, etc.), but rather a tool to interact with backlog information potentially stored elsewhere or locally in docs.

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

### Short-term Goals (Complete by ~Aug 2025 - v1.0.0)

- Achieve GA for core LLM communication commands.
- Finalize and release GitHub repository creation and commit generator tools.
- Implement and stabilize task utility commands (`tn`, `tr`, `rc`).
- Reach ≥ 95% test coverage.
- Publish stable v1.0.0 to RubyGems.

### Medium-term Goals (6-12 months post-v1)

- Gather user feedback and prioritize feature requests.
- Explore integrations with other LLM providers (if needed and not proprietary).
- Enhance task management features, potentially integrating with external systems.
- Improve performance and scalability.

### Long-term Vision (1+ years)

- Become a standard tool in AI-assisted Ruby development workflows.
- Potentially explore mechanisms for cross-language support (e.g., via a shared core or well-defined API boundaries).
- Expand the suite of automated Dev Ops and development tasks supported.

## Dependencies and Ecosystem

### Key Dependencies

#### Runtime Requirements
- **Ruby ≥ 3.2**: The required runtime environment for the tools
- **Node.js**: Required for markdownlint documentation quality control
- **Git CLI**: Fundamental command-line tool for repository operations

#### External Service Integrations
- **LLM Providers**: 
  - Google Gemini API (online)
  - OpenAI API (online)
  - Anthropic API (online)
  - Mistral API (online)
  - Together AI API (online)
  - LM Studio (local/offline)
- **GitHub REST API (v3)**: Used for repository creation and management
- **LiteLLM Pricing Database**: For accurate cost tracking across all providers

#### Development Dependencies
- **Ruby Ecosystem**: Bundler, RSpec, StandardRB, Faraday, dry-cli, VCR, WebMock
- **Documentation**: markdownlint-cli for quality control
- **Security**: Gitleaks for secrets scanning

### Ecosystem Integration

- **Multi-Repository Development**: Seamless coordination across handbook, tools, and taskflow repositories
- **AI Coding Agents**: Primary users and integrators designed for autonomous operation
- **Human Developer Workflows**: Enhanced productivity tools for manual development tasks
- **Git/GitHub**: Deep integration for repository management, commit workflows, and multi-repo operations
- **Documentation-Driven Development**: Tight integration between workflows, tasks, and executable tools
- **CI/CD Pipelines**: Designed to be invoked as part of automated workflows and deployment processes
- **Development Environments**: Complete integration with XDG-compliant caching and configuration standards

## Submodules

This project uses 3 Git submodules plus the root repository (4 total repositories):

### dev-handbook
- **Path**: `dev-handbook/`
- **Repository**: External repository for development resources
- **Purpose**: Contains development resources, guides, workflow instructions, templates, and best practices used by both developers and AI agents
- **Key Contents**: Self-contained AI workflows, development guides, project templates, editor integrations
- **Important**: Commits for this submodule must be made from within the submodule directory

### dev-tools
- **Path**: `dev-tools/`
- **Repository**: External repository for the Ruby gem
- **Purpose**: Core Ruby gem with CLI tools, LLM integrations, and development automation
- **Key Contents**: ATOM-structured Ruby code, 25+ CLI executables, comprehensive test suite, security framework
- **Important**: Commits for this submodule must be made from within the submodule directory

### dev-taskflow
- **Path**: `dev-taskflow/`
- **Repository**: External repository for task management
- **Purpose**: Project-specific task management, release planning, and project coordination
- **Key Contents**: Structured task organization (backlog/current/done), release planning, project decisions
- **Important**: Commits for this submodule must be made from within the submodule directory

---

*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*
