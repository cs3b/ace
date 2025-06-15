# Coding Agent Tools Ruby Gem

## What We Build 🔍

The **Coding Agent Tools (CAT)** project provides a Ruby gem and associated command-line interface (CLI) tools designed to streamline development workflows for both human developers and autonomous AI coding agents. Its core purpose is to enable seamless interaction with local projects, Git repositories, and task backlogs by offering a predictable and standardized set of commands and a programmable API. By automating routine Dev Ops tasks like querying LLMs, generating commit messages, creating repositories, and navigating task queues, CAT frees up developers and agents to concentrate on higher-value design and coding activities.

## ✨ Key Features

- **LLM Communication**: Implemented CLI commands (`llm-gemini-query`, `lms-studio-query`) for interacting with Google Gemini and local LM Studio models.
- **Model Discovery and Management**: List and filter available models from different providers, with the ability to select specific models for queries using the --model flag.
- **LM Studio Integration**: Direct integration with local LM Studio models for offline LLM queries without requiring API keys.
- **Git Workflow Automation**: Tools for creating GitHub repositories (`github-repository-create`) and generating intelligent Git commit messages based on diffs and intentions (`git-commit-with-message`).
- **Task Management Utilities**: Commands (`tn`, `tr`, `rc`) to help developers and agents identify the next actionable task, review recent tasks, and manage release directories, often integrating with documentation-based task backlogs.
- **Standardized Interface**: Provides a consistent CLI and API surface for automation, reducing reliance on ad-hoc scripts.
- **Offline Support**: Enables querying local language models via LM Studio.

## Core Design Principles

- **ATOM Architecture**: Structured around the Action, Transformation, Operation, and Model pattern for maintainability, testability, and clear separation of concerns.
- **Test-Driven Development**: High emphasis on testing with a goal of 100% unit and integration test coverage using RSpec.
- **Predictable CLI**: Designing commands with ergonomic flags suitable for both human and agent interaction.
- **Modularity**: Components are designed with explicit boundaries and dependency injection.
- **Ruby Best Practices**: Adhering to standard Ruby conventions and practices.

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

### What We Build
- A Ruby gem (`coding_agent_tools`) installable via standard Ruby package managers (RubyGems, Bundler).
- A suite of CLI executables (`bin/`) for common Dev Ops and task management workflows, including `exe/llm-gemini-query`.
- Core ATOM components, including:
  - **Atoms**: `EnvReader`, `HTTPClient`, `JSONFormatter`
  - **Molecules**: `APICredentials`, `HTTPRequestBuilder`, `APIResponseParser`
  - **Organisms**: `GeminiClient`, `PromptProcessor`
- An internal API used by the CLI, which can potentially be exposed for programmatic use.
- Integrations with Google Gemini API and local LM Studio API.
- Integrations with Git CLI and GitHub REST API (v3).
- Tools to interact with documentation-based task backlogs (e.g., in `docs-project`).
- Comprehensive unit and integration tests.
- Documentation (`docs-project/`) detailing usage and architecture.

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
- **Ruby ≥ 3.2**: The required runtime environment.
- **Google Gemini API**: Required for online LLM interactions.
- **LM Studio**: Required for local, offline LLM interactions.
- **Git CLI**: Fundamental command-line tool interacted with by the gem.
- **GitHub REST API (v3)**: Used for repository creation.
- **`docs-dev/tools/*` scripts**: Utility scripts assumed to be present in the `docs-dev` submodule for certain operations (like task utilities).

### Ecosystem Integration
- **Git/GitHub**: Deep integration for repository management and commit workflows.
- **Task Backlogs (Docs-based)**: Designed to work with tasks defined in documentation files (`docs-project/`).
- **CI/CD Pipelines**: Intended to be invoked as part of automated workflows.
- **AI Coding Agents**: Primary users and integrators of the tools.

## Submodules

### docs-dev
- Path: `docs-dev`
- Repository: [Repository URL - assumed external]
- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
- **Important**: Commits for this submodule must be made from within the submodule directory.

---

*This document should be updated as the project evolves and new insights are gained about user needs and project direction.*