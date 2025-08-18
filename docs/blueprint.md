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
