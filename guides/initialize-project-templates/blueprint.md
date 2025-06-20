# Project Blueprint: [Project Name]

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](docs/what-do-we-build.md) - Project vision and goals
- [Architecture](docs/architecture.md) - System design and implementation principles
- [Blueprint](docs/blueprint.md) - Project structure and organization


## Project Organization

<!-- Describe your project's main directory structure -->

This project follows a documentation-first approach with these primary directories:

- **docs-dev/** - Development resources and workflows
  - **guides/** - Best practices and standards for development
  - **tools/** - Utility scripts to support development workflows
  - **workflow-instructions/** - Structured commands for AI agents
  - **zed/** - Editor integration (if applicable)

- **docs-project/** - Project-specific documentation
  - **current/** - Active release cycle work
  - **backlog/** - Pending tasks for future releases
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **bin/** - Executable scripts for project management and automation

- **src/** - Source code (adjust directory names as needed)
  - **[component1]/** - Core functionality
  - **[component2]/** - Additional features
  - **utils/** - Shared utilities

- **tests/** - Test files and test utilities

- **config/** - Configuration files

<!-- Add your project-specific directories here -->

## View Complete Directory Structure

To see the complete filtered directory structure, run:

```bash
bin/tree
```

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

<!-- List important files that developers should know about -->

- [Workflow Instructions](docs-dev/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](docs-dev/guides/README.md) - Development standards and best practices
- [Configuration](README.md) - Configuration documentation (if applicable)

## Technology Stack

<!-- Summarize the main technologies used -->

- **Primary Language**: [e.g., JavaScript, Python, Rust]
- **Framework**: [e.g., React, Django, Axum]
- **Database**: [e.g., PostgreSQL, MongoDB, SQLite]
- **Key Libraries**: [List important dependencies]
- **Development Tools**: [e.g., Docker, Webpack, Cargo]

## Read-Only Paths

This section lists files and directories that the agent should treat as read-only. Attempts to modify these paths should be flagged or prevented.

<!-- Add project-specific read-only paths -->
- `docs-project/decisions/**/*`
- `docs-project/done/**/*`
- `*.lock` # Dependency lock files
- `dist/**/*` # Built artifacts
- `build/**/*` # Build output

## Ignored Paths

This section lists files, directories, or glob patterns that the agent should ignore entirely during its operations (e.g., when searching, reading, or editing files).

- `docs-project/done/**/*` # Default: Protects completed tasks and releases
- `**/node_modules/**`
- `**/.git/**`
- `**/__pycache__/**`
- `**/target/**` # Rust build artifacts
- `**/dist/**` # Built distributions
- `**/build/**` # Build artifacts
- `**/.env` # Environment files
- `**/.env.*` # Environment variants
- `*.session.log`
- `*.lock`
- `*.tmp`
- `*~` # Backup files
- `**/.DS_Store` # macOS system files
- `**/Thumbs.db` # Windows system files

## Entry Points

<!-- Document the main ways to start or interact with the project -->

### Development

```bash
# Start development server
bin/run

# Run tests
bin/test

# Build for production
bin/build
```

### Common Workflows

- **New Feature**: Use `bin/tn` to find next task, follow task workflow
- **Bug Fix**: Create task in backlog, prioritize, implement
- **Documentation**: Update relevant files in `docs-project/`

## Dependencies

<!-- List major external dependencies and their purposes -->

### Runtime Dependencies

- [Library 1]: Purpose and version constraints
- [Library 2]: Purpose and version constraints

### Development Dependencies

## Submodules

<!-- Document any Git submodules used -->

### docs-dev (if applicable)

- Path: `docs-dev`
- Repository: [Repository URL]
- Purpose: Development workflows and guides
- **Important**: Commits for this submodule must be made from within the submodule directory

### [Other Submodules]

- Path: `[path]`
- Repository: [Repository URL]
- Purpose: [Description]

---

*This blueprint should be updated when significant structural changes are made to the project. Use the `update-blueprint` workflow to keep it current.*
