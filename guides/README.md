# Development Guides

This directory contains comprehensive development guidelines and standards for the project.

## Core Development Process

Our development workflow centers around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases

## Guide Organization

### Meta-Guides
- [Writing Development Guides](docs-dev/guides/writing-guides-guide.md) - How to write effective guides for this toolkit
### Essential Guidelines
- [Coding Standards](docs-dev/guides/coding-standards.md) - Code style and best practices
- [Testing Guidelines](docs-dev/guides/testing.md) - Testing approach and frameworks
- [Documentation Standards](docs-dev/guides/documentation.md) - Documentation requirements
- [Quality Assurance](docs-dev/guides/quality-assurance.md) - Quality control processes
- [Version Control](docs-dev/guides/version-control.md) - Git workflow and commit standards

### Technical Guidelines
- [Error Handling](docs-dev/guides/error-handling.md) - Error handling patterns
- [Performance](docs-dev/guides/performance.md) - Performance optimization guidelines
- [Security](docs-dev/guides/security.md) - Security best practices

### Release Management
- [Release Process](docs-dev/guides/ship-release.md) - Release workflow and checklists
- [Release Documentation Template](docs-dev/guides/prepare-release/v.x.x.x/docs/_template.md) - Standard release documentation structure (Note: The referenced file `prepare-release-documentation.md` does not exist in the provided structure. Pointing to the docs template.)
- [Writing Workflow Instructions](docs-dev/guides/writing-workflow-instructions.md) - How to define AI workflows

## Task & Release Management

Project tasks and release planning are managed within the `docs-project` directory using a simple Kanban-style flow (`backlog/`, `current/`, `done/`) with structured Markdown task files.

Key guides for this process:
- [Project Management Guide](docs-dev/guides/project-management.md): Details the directory structure, task format, and core workflow.
- [Unified Workflow Guide](docs-project/current/v.0.2.0/docs/unified-workflow-guide.md): Outlines the interaction phases and workflow instructions. (Assuming this file exists in docs-project)
- [Release Process](docs-dev/guides/ship-release.md): Covers the steps for finalizing and publishing a release.

The specific documentation artifacts required for a release (e.g., ADRs, test cases, user examples) are determined during the specification phase, guided by the `lets-spec-*` workflow instructions based on the release type (Patch, Feature, Major).
