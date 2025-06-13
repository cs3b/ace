# Project Blueprint: Coding Agent Tools Ruby Gem

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](./what-do-we-build.md) - Project vision and goals
- [Architecture](./architecture.md) - System design and implementation principles

## Project Organization

This project follows a documentation-first approach with these primary directories:

- **docs-dev/** - Development resources and workflows (Git submodule)
  - **guides/** - Best practices and standards for development
  - **tools/** - Utility scripts to support development workflows (e.g., for task management, tree display)
  - **workflow-instructions/** - Structured commands for AI agents
  - **zed/** - Editor integration (if applicable)

- **docs-project/** - Project-specific documentation, task management, and decisions
  - **backlog/** - Pending tasks for future releases
  - **current/** - Active release cycle work
  - **done/** - Completed releases and tasks
  - **decisions/** - Architecture Decision Records (ADRs)

- **bin/** - Executable scripts (binstubs/wrappers) for project automation (e.g., `bin/test`, `bin/tn`)

- **exe/** - Primary gem executables (e.g., `exe/llm-gemini-query`)

- **lib/** - Ruby gem source code, organized by the ATOM architecture pattern with subdirectories for `atoms/`, `molecules/`, `organisms/`, `cli/`, `models/`, and cross-cutting concerns like `middlewares/`.

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
- [Main README](../../README.md) - Project overview, installation, runtime configuration, and user-facing documentation
- [Development Guide](../../docs/DEVELOPMENT.md) - Development environment setup, testing, build tools, and contributor workflow
- [Workflow Instructions](../../docs-dev/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](../../docs-dev/guides/README.md) - Development standards and best practices
- `coding_agent_tools.gemspec` - Ruby gem definition and dependencies
- `Gemfile` - Bundler dependency management

## Technology Stack

- **Primary Language**: Ruby (>= 3.4.2)
- **Architecture Pattern**: ATOM (Action, Transformation, Operation, Model), Zeitwerk for efficient code loading, and dry-monitor for observability
- **Runtime Dependencies**: Faraday (HTTP client), dry-cli (CLI framework), dry-configurable (configuration management), addressable (URI parsing and manipulation)
- **Development Tools**: RSpec, StandardRB, VCR, WebMock, Zeitwerk
- **Integrations**: Google Gemini API, LM Studio (local), Git CLI, GitHub REST API

### Documentation Separation

- **README.md**: Contains runtime information, installation instructions, basic usage, and configuration for end users
- **docs/DEVELOPMENT.md**: Contains development environment setup, testing frameworks, build tools, and contributor guidelines

## Read-Only Paths

AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks. Modifying these files without careful consideration can break core project workflows or documentation standards.

- `docs-dev/guides/**/*`
- `docs-dev/workflow-instructions/**/*`
- `docs-dev/tools/_binstubs/**/*`
- `docs-dev/guides/initialize-project-templates/**/*`
- `docs-project/decisions/**/*` (Modify only when adding or updating ADRs)
- `docs-project/done/**/*` (Completed tasks should not be modified)
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

- `docs-project/done/**/*` # Completed tasks (already read-only, but explicitly ignored for general tasks)
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
- **Query LLM**: Use `exe/llm-gemini-query` or `bin/lms-studio-query` to interact with language models.
- **Generate Documentation Review**: Use `bin/cr-docs` to create comprehensive documentation update prompts from code diffs.

Refer to the [Architecture document](./architecture.md#command-line-tools-bin) for a more detailed list and description of `bin/` commands.

## Dependencies

### Runtime Dependencies

- **Ruby** (>= 3.2)
- **Bundler** - Dependency management
- **faraday** - Flexible HTTP client library.
- **zeitwerk** - Efficient and thread-safe code loader.
- **dry-monitor** - Event-based monitoring and instrumentation toolkit.
- **dry-configurable** - Provides configuration capabilities for Ruby objects.
- **addressable** - URI manipulation library.

### Development Dependencies

- **RSpec** - Testing framework.
- **RuboCop / StandardRB** - Code style linter and formatter.
- **VCR** - Records and replays HTTP interactions for tests.
- **WebMock** - Stubs and sets expectations on HTTP requests.
- `docs-dev/tools/*` scripts (used by some `bin/` wrappers).

See `coding_agent_tools.gemspec` and `Gemfile` for complete dependency specifications.

## Submodules

### docs-dev

- Path: `docs-dev`
- Repository: [Repository URL - assumed external]
- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
- **Important**: Commits for this submodule must be made from within the submodule directory (`../../docs-dev`).

---

*This blueprint serves as a quick reference and guide for automated agents. It should be updated if the project structure, key technologies, or operational guidelines change significantly.*