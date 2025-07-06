# Project Blueprint: Coding Agent Workflow Toolkit (Meta)

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](./what-do-we-build.md) - Project vision and goals
- [Architecture](./architecture.md) - System design and implementation principles

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

- **dev-tools/** - Ruby gem with CLI tools for LLM integration (Git submodule)
  - **lib/** - Ruby gem source code, organized by the ATOM architecture pattern
  - **spec/** - RSpec test files (unit, integration, CLI)
  - **exe/** - Executable CLI tools for LLM integration

- **docs/** - Core project documentation (permanent reference materials)
  - **decisions/** - Architecture Decision Records (ADRs)
  - **migrations/** - Documentation migration records

- **bin/** - Project automation scripts and Git shortcuts

## View Complete Directory Structure

To see the complete filtered directory structure, run:

```bash
bin/tree
```

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

- [Main README](../README.md) - Project overview and quick start
- [CLAUDE.md](../CLAUDE.md) - Project instructions for Claude Code
- [Workflow Instructions](../dev-handbook/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](../dev-handbook/guides/README.md) - Development standards and best practices
- `package.json` - Node.js dependencies (for markdownlint)
- `dev-tools/coding_agent_tools.gemspec` - Ruby gem definition and dependencies
- `dev-tools/Gemfile` - Bundler dependency management for dev-tools submodule

## Technology Stack

- **Primary Language**: Ruby (>= 3.2) for dev-tools submodule
- **Documentation**: Markdown with markdownlint for quality control
- **Architecture Pattern**: ATOM (Action, Transformation, Operation, Model) for dev-tools
- **Key Libraries/Tools**: 
  - Ruby: Bundler, RSpec, Aruba, RuboCop (in dev-tools)
  - Node.js: markdownlint-cli for documentation quality
  - Git submodules for project organization
- **Integrations**: Google Gemini API, LM Studio (local), Git CLI, GitHub REST API (via dev-tools)

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
- `dev-tools/lib/**/*` # Ruby gem source code (submodule)
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

## Entry Points

### Development

```bash
# Run all tests (executes bin/lint for this project)
bin/test

# Run linting (markdownlint + custom Ruby scripts)
bin/lint

# Build project (placeholder - this is a documentation project)
bin/build

# Get project tree structure
bin/tree
```

### Common Workflows

- **Find Next Task**: Use `bin/tn` to identify the next unblocked task to work on
- **Summarize Recent Work**: Use `bin/tr` to see recently completed or updated tasks
- **Get Current Release**: Use `bin/rc` to get current release context
- **Multi-repo Git Operations**: Use `bin/gs`, `bin/gl`, `bin/gc`, `bin/gp`, `bin/gpull` for operations across all 4 repositories
- **Template Synchronization**: Use `bin/markdown-sync-embedded-documents` to sync embedded templates
- **Query LLM**: Use `dev-tools/exe/llm-query` to interact with language models

### Git Submodules

```bash
# Initialize all submodules
git submodule update --init --recursive

# Work in a specific submodule
cd dev-handbook  # or dev-taskflow, dev-tools
# Make changes and commit from within submodule
```

## Dependencies

### Runtime Dependencies

- **Git**: Required for submodule operations and version control
- **Ruby (>= 3.2)**: Required for dev-tools submodule utilities
- **Node.js**: Required for markdownlint documentation quality control
- **Bundler**: For Ruby gem dependency management in dev-tools

### Development Dependencies

- **markdownlint-cli**: For documentation quality control
- **RSpec**: For testing in dev-tools submodule
- **RuboCop**: For code quality in dev-tools submodule
- **Custom Ruby scripts**: For project-specific linting and utilities

## Submodules

This project uses 3 Git submodules plus the root repository (4 total repositories):

### dev-handbook

- Path: `dev-handbook`
- Repository: [External repository]
- Purpose: Development guides and workflow instructions for AI agents
- **Important**: Commits for this submodule must be made from within the submodule directory

### dev-taskflow

- Path: `dev-taskflow`
- Repository: [External repository]
- Purpose: Task management structure with backlog/, current/, done/ organization
- **Important**: Commits for this submodule must be made from within the submodule directory

### dev-tools

- Path: `dev-tools`
- Repository: [External repository]
- Purpose: Ruby gem with CLI tools for LLM integration and development automation
- **Important**: Commits for this submodule must be made from within the submodule directory

---

*This blueprint should be updated when significant structural changes are made to the project. Use the `update-blueprint` workflow to keep it current.*
