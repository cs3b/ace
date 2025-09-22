# ACE (Agent Coding Environment)

## What We Build 🔍

The **ACE (Agent Coding Environment)** is a mono-repo ecosystem of modular Ruby gems that enable seamless AI-assisted software development. It provides a unified environment where AI agents and human developers interact through the same deterministic CLI surface, combining workflow automation with powerful development tools.

The system bridges the gap between human developers and AI coding agents through:
- **Modular ace-* gems** providing focused, testable functionality
- **Unified CLI tools** accessible to both humans and AI agents
- **ATOM architecture** ensuring clean separation of concerns
- **Configuration cascade** enabling flexible, context-aware settings
- **Documentation-driven development** with integrated task management

By organizing capabilities into specialized gems (ace-core, ace-context, ace-test-runner, etc.), ACE provides a scalable foundation for AI-assisted development that grows with your needs.

## ✨ Key Features

### Core Gems & Capabilities
- **ace-core**: Zero-dependency configuration management with cascade resolution
- **ace-context**: Intelligent context loading with caching and multi-format output
- **ace-test-runner**: Comprehensive test execution with parallel processing
- **ace-test-support**: Shared testing infrastructure and utilities

### Development Features (In Migration)
- **Workflow Automation**: Self-contained AI workflows for autonomous execution (migrating from dev-handbook)
- **Multi-Provider LLM Integration**: Unified interface for various language models (planned: ace-llm)
- **Git Enhancement Tools**: Intelligent commit messages and repository management (planned: ace-git)
- **Task Management System**: Documentation-driven development tracking (migrating from dev-taskflow)
- **Template Management**: Automated synchronization of embedded templates


## Target Use Cases

### Primary Use Cases

- **Automated Development Workflows**: AI coding agents using ace-* commands to perform tasks like loading context, running tests, or managing configuration within CI/CD pipelines or local development environments.
- **Context-Aware Development**: Developers and agents loading project-specific context with ace-context for better understanding and decision-making.
- **Comprehensive Test Execution**: Running tests across multiple gems with ace-test-runner, supporting parallel execution and detailed reporting.
- **Configuration Management**: Using ace-core's cascade resolution to manage settings across project hierarchies.

### Secondary Use Cases

- **Modular Gem Integration**: Developers extending ACE by creating new ace-* gems following the established ATOM architecture.
- **CI/CD Pipeline Integration**: Automated testing across multiple Ruby versions using the integrated GitHub Actions workflow.

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

- Context: Priya uses ACE gems as a foundation for building standardized, testable, and extendable developer tools. The ATOM architecture and mono-repo structure make it easy to add new gems and integrate with existing systems.


## Project Boundaries

### Distribution Model

ACE uses a **mono-repo architecture** with modular Ruby gems, providing clear separation of concerns while maintaining simple dependency management. This replaces the previous multi-repository submodule approach, offering better integration and easier maintenance.

### What We Build

- **Modular Ruby gems** (ace-*) providing focused, testable functionality with ATOM architecture
- **Unified CLI surface** where agents and humans use the same deterministic tools
- **Configuration cascade system** (.ace/) enabling context-aware settings management
- **Comprehensive test infrastructure** with parallel execution and CI/CD integration
- **Development automation tools** for context loading, testing, and configuration
- **Migration path** from legacy dev-* structure to modern ace-* gem ecosystem
- **Extensible foundation** for adding new ace-* gems as capabilities grow


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

ACE aims to become the standard foundation for AI-assisted software development through its modular gem ecosystem. We envision expanding the ace-* gem family to cover all aspects of development automation, with each gem providing focused functionality that integrates seamlessly. Future additions will include ace-git for enhanced version control, ace-llm for multi-provider AI integration, and ace-handbook for workflow management, creating a comprehensive environment where human creativity and AI capabilities complement each other perfectly.


---

*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*
