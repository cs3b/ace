[← Back to docs-dev root](../README.md) ▸ Guides

# Development Guides

This directory contains comprehensive development guidelines and standards for the project.

## Core Development Process

Our development workflow centers around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases

## Guide Organization

### Meta & Process Guides
- [Writing Development Guides](./writing-guides-guide.md) - How to write effective guides for this toolkit.
- [Writing Workflow Instructions](./writing-workflow-instructions.md) - How to define AI workflows.
- [Project Management Guide](./project-management.md): Details task management, directory structure, and core workflow.

### Technical & Language Guides

- **[Coding Standards](./coding-standards.md)** - Code style and general best practices.
  - [Ruby Coding Standards](./coding-standards/ruby.md)
- **[Documentation Standards](./documentation.md)** - Documentation requirements and structure.
- **[Error Handling](./error-handling.md)** - Error handling patterns and strategies.
- **[Performance](./performance.md)** - Performance optimization guidelines.
- **[Quality Assurance](./quality-assurance.md)** - Quality control processes and standards.
- **[Security](./security.md)** - Security best practices and considerations.
- **[Testing Guidelines](./testing.md)** - General testing approach and philosophy.
  - [Ruby RSpec Guide](./testing/ruby-rspec.md)
  - [Rust Testing Guide](./testing/rust.md)
  - [TypeScript (Bun) Guide](./testing/typescript-bun.md)
- **[Troubleshooting Workflow](./troubleshooting-workflow.md)** - High-level workflow for debugging and problem-solving.
- **[Version Control](./version-control.md)** - Git workflow and commit standards.

### Development Tools
- **[Development Tools Guide](./tools-guide.md)** - Best practices for creating, maintaining, and using development tools.

### Release Management
- **[Release Process](./ship-release.md)** - Release workflow, versioning, and checklists.
- **[Release Documentation Template](./prepare-release/v.x.x.x/docs/_template.md)** - Standard release documentation structure.

## Task & Release Management

Project tasks and release planning are managed within the `docs-project` directory using a simple Kanban-style flow (`backlog/`, `current/`, `done/`) with structured Markdown task files.

Key guides for this process:
- [Project Management Guide](./project-management.md): Details the directory structure, task format, and core workflow.
- [Release Process](./ship-release.md): Covers the steps for finalizing and publishing a release.

The specific documentation artifacts required for a release (e.g., ADRs, test cases, user examples) are determined during the specification phase, guided by the `lets-spec-*` workflow instructions based on the release type (Patch, Feature, Major).
