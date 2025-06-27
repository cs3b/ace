# Project Blueprint: Coding Agent Tools Ruby Gem

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](./what-do-we-build.md) - Project vision and goals
- [Architecture](./architecture.md) - System design and implementation principles

## Project Organization

This project follows a documentation-first approach with these primary directories:

- **dev-handbook/** - Development resources and workflows (Git submodule)
  - **guides/** - Best practices and standards for development
  - **tools/** - Utility scripts to support development workflows (e.g., for task management, tree display)
  - **workflow-instructions/** - Structured commands for AI agents
  - **zed/** - Editor integration (if applicable)

- **dev-taskflow/** - Project-specific documentation, task management, and decisions
  - **backlog/** - Pending tasks for future releases
  - **current/** - Active release cycle work
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **bin/** - Executable scripts (binstubs/wrappers) for project automation (e.g., `bin/test`, `bin/tn`)

- **lib/** - Ruby gem source code, organized by the ATOM architecture pattern

- **spec/** - RSpec test files (unit, integration, CLI)

<!-- Add your project-specific directories here -->

## View Complete Directory Structure

To see the complete filtered directory structure, run:

```bash
bin/tree
```

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

- [Product Requirements Document (PRD)](../../PRD.md) - Primary source of truth for project goals and requirements
- [Main README](../../README.md) - Project overview and quick start
- [Workflow Instructions](../../dev-handbook/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](../../dev-handbook/guides/README.md) - Development standards and best practices
- `coding_agent_tools.gemspec` - Ruby gem definition and dependencies
- `Gemfile` - Bundler dependency management

## Technology Stack

- **Primary Language**: Ruby (>= 3.2)
- **Architecture Pattern**: ATOM (Action, Transformation, Operation, Model)
- **Key Libraries/Tools**: Bundler, RSpec, Aruba, RuboCop
- **Integrations**: Google Gemini API, LM Studio (local), Git CLI, GitHub REST API

## Read-Only Paths

AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks. Modifying these files without careful consideration can break core project workflows or documentation standards.

- `dev-handbook/guides/**/*`
- `dev-handbook/workflow-instructions/**/*`
- `dev-tools/exe-old/_binstubs/**/*`
- `dev-handbook/guides/initialize-project-templates/**/*`
- `dev-taskflow/decisions/**/*` (Modify only when adding or updating ADRs)
- `dev-taskflow/done/**/*` (Completed tasks should not be modified)
- `lib/**/*` (Treat the core gem implementation as stable unless working on a specific feature or bug fix requiring changes here)
- `spec/**/*` (Treat tests as read-only unless writing new tests or fixing broken ones related to code changes)
- `.gitignore` (Modify carefully when adding/removing ignored patterns)
- `Gemfile.lock` (Manage dependencies via `bundle add`/`remove` or explicit instruction)
- `bin/*` (Modify only when updating binstub templates or adding new project-specific scripts)
- `*.lock` # Dependency lock files (e.g., Gemfile.lock)
- `dist/**/*` # Built artifacts
- `build/**/*` # Build output
- `pkg/**/*` # Gem packages

## Ignored Paths

AI agents should generally ignore the contents of the following paths during tasks such as searching for tasks, summarizing project state, or performing code analysis, unless the task explicitly requires interacting with these directories (e.g., cleaning build artifacts). These paths often contain transient data, dependencies, or build artifacts.

- `dev-taskflow/done/**/*` # Completed tasks (already read-only, but explicitly ignored for general tasks)
- `vendor/**/*` (Bundler dependencies)
- `tmp/**/*`
- `log/**/*`
- `.git/**/*`
- `.bundle/**/*`
- `coverage/**/*` (Test coverage reports)
- `node_modules/**/*` (If applicable for frontend/tooling)
- `.idea/**/*`, `.vscode/**/*` (Editor specific configurations)
- `**/.*.swp`, `**/.*.swo` (Swap files)
- `/.DS_Store` (macOS system files)
- `**/Thumbs.db` (Windows system files)
- `**/.env` # Environment files
- `**/.env.*` # Environment variants
- `*.session.log`
- `*.lock`
- `*.tmp`
- `*~` # Backup files

## Entry Points

### Development

```bash
# Run the test suite
bin/test

# Run code quality checks
bin/lint

# Build the gem
bin/build
```

*(Note: `bin/run` might be used for specific entry points if defined)*

### Common Workflows

- **Find Next Task**: Use `bin/tn` to identify the next unblocked task to work on.
- **Summarize Recent Work**: Use `bin/tr` to see recently completed or updated tasks.
- **Commit Changes**: Use `bin/git-commit-with-message` to stage changes and generate a commit message.
- **Query LLM**: Use `bin/llm-gemini-query` or `bin/lms-studio-query` to interact with language models.

Refer to the [Architecture document](./architecture.md#command-line-tools-bin) for a more detailed list and description of `bin/` commands.

## Dependencies

### Runtime Dependencies (Key Examples)

- Ruby (>= 3.2)
- Bundler
- Gems for Google Gemini API interaction
- Gems/tools for LM Studio interaction
- Standard system Git CLI
- Gems for GitHub REST API interaction (e.g., octokit)

### Development Dependencies (Key Examples)

- RSpec
- Aruba
- RuboCop
- `dev-tools/exe-old/*` scripts (used by some `bin/` wrappers)

## Submodules

### dev-handbook

- Path: `dev-handbook`
- Repository: [Repository URL - assumed external]
- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
- **Important**: Commits for this submodule must be made from within the submodule directory (`../../dev-handbook`).

---

*This blueprint serves as a quick reference and guide for automated agents. It should be updated if the project structure, key technologies, or operational guidelines change significantly.*
