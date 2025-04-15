# Development Guides

This directory contains comprehensive development guidelines and standards for the project.

## Core Development Process

Our development workflow centers around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases

## Guide Organization

### Essential Guidelines
- [Coding Standards](coding-standards.md) - Code style and best practices
- [Testing Guidelines](testing.md) - Testing approach and frameworks
- [Documentation Standards](documentation.md) - Documentation requirements
- [Quality Assurance](quality-assurance.md) - Quality control processes
- [Version Control](version-control.md) - Git workflow and commit standards

### Technical Guidelines
- [Error Handling](error-handling.md) - Error handling patterns
- [Performance](performance.md) - Performance optimization guidelines
- [Security](security.md) - Security best practices

### Release Management
- [Release Process](ship-release.md) - Release workflow and checklists
- [Release Documentation Template](prepare-release/prepare-release-documentation.md) - Standard release documentation structure

## Task & Release Management

Project tasks and release planning are managed within the `../project/` directory using a simple Kanban-style flow (`backlog/`, `current/`, `done/`) with structured Markdown task files.

Key guides for this process:
- [Project Management Guide](project-management.md): Details the directory structure, task format, and core workflow.
- [Unified Workflow Guide](../project/current/v.0.2.0/docs/unified-workflow-guide.md): Outlines the interaction phases and commands.
- [Release Process](ship-release.md): Covers the steps for finalizing and publishing a release.

The specific documentation artifacts required for a release (e.g., ADRs, test cases, user examples) are determined during the specification phase, guided by the `lets-spec-*` commands based on the release type (Patch, Feature, Major).
