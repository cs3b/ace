# Project Blueprint: Coding Agent Tools Ruby Gem

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Core Project Documents

- [What We Build](./what-do-we-build.md) - Project vision and goals
- [Architecture](./architecture.md) - System design and implementation principles

## Project Organization

```
coding-agent-tools/
├── bin/                      # Development tools and binstubs
│   ├── build                 # Build and verify gem installation
│   ├── console               # Ruby console with gem loaded
│   ├── cr                    # Code review prompt generator
│   ├── cr-docs               # Documentation review generator
│   ├── gc                    # Git commit with standardized format
│   ├── gl                    # Get recent git log
│   ├── lint                  # Run StandardRB code quality checks
│   ├── rc                    # Get current release context
│   ├── setup                 # Initial development setup
│   ├── tal                   # List all tasks
│   ├── test                  # Run RSpec test suite
│   ├── tn                    # Find next unblocked task
│   ├── tnid                  # Generate next task ID
│   ├── tr                    # List recent tasks
│   └── tree                  # Display filtered project structure
├── docs/                     # Product documentation
│   ├── architecture.md       # Technical design and patterns
│   ├── blueprint.md          # This file - project navigation
│   ├── what-do-we-build.md   # Product vision and goals
│   ├── DEVELOPMENT.md        # Development workflow guide
│   ├── SETUP.md              # Environment setup instructions
│   ├── dev-guides/           # Technical deep-dive guides
│   └── llm-integration/      # LLM feature documentation
├── docs-dev/                 # Development resources (Git submodule)
│   ├── guides/               # Best practices and standards
│   ├── tools/                # Utility scripts for workflows
│   └── workflow-instructions/ # AI agent workflow definitions
├── docs-project/             # Project management
│   ├── backlog/              # Future release tasks
│   ├── current/              # Active release work
│   ├── done/                 # Completed releases
│   ├── decisions/            # Architecture Decision Records
│   └── roadmap.md            # Strategic planning
├── exe/                      # Gem executables (user commands)
│   ├── llm-gemini-models     # List Gemini models
│   ├── llm-gemini-query      # Query Gemini API
│   ├── llm-lmstudio-models   # List LM Studio models
│   └── llm-lmstudio-query    # Query LM Studio
├── lib/                      # Ruby gem source code
│   └── coding_agent_tools/   # Main gem module
│       ├── atoms/            # Basic utilities
│       ├── molecules/        # Composed operations
│       ├── organisms/        # Business logic
│       ├── ecosystems/       # Complete workflows
│       ├── models/           # Data structures
│       ├── cli/              # CLI command classes
│       ├── middlewares/      # Cross-cutting concerns
│       └── *.rb              # Core files
├── spec/                     # Test suite
│   ├── unit/                 # Unit tests by component
│   ├── integration/          # Integration tests
│   ├── cli/                  # CLI tests
│   ├── support/              # Test helpers
│   └── cassettes/            # VCR recordings
├── .github/                  # GitHub configuration
│   ├── workflows/            # CI/CD pipelines
│   └── CONTRIBUTING.md       # Contribution guidelines
├── CHANGELOG.md              # Version history
├── README.md                 # Project overview
├── Gemfile                   # Ruby dependencies
├── coding_agent_tools.gemspec # Gem specification
└── LICENSE                   # MIT license
```

## View Complete Directory Structure

To see the complete filtered directory structure, run:

```bash
bin/tree
```

This will show all project files while filtering out temporary files, session logs, and other non-essential directories.

## Key Project-Specific Files

- [Product Requirements Document (PRD)](../PRD.md) - Primary source of truth for project goals and requirements
- [Main README](../README.md) - Project overview, installation, runtime configuration, and user-facing documentation
- [Development Guide](../docs/DEVELOPMENT.md) - Development environment setup, testing, build tools, and contributor workflow
- [Workflow Instructions](../docs-dev/workflow-instructions/README.md) - Entry point for understanding available AI workflows
- [Project Guides](../docs-dev/guides/README.md) - Development standards and best practices
- `coding_agent_tools.gemspec` - Ruby gem definition and dependencies
- `Gemfile` - Bundler dependency management

## Technology Stack

- **Primary Language**: Ruby (>= 3.2)
- **Architecture Pattern**: ATOM (Action, Transformation, Operation, Model)
- **Key Dependencies**: Faraday, dry-cli, RSpec, VCR
- **External Integrations**: Google Gemini API, LM Studio, Git/GitHub

For detailed technology stack information, dependency versions, and architectural patterns, see the [Architecture document](./architecture.md#technology-stack).

## Read-Only Paths

AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks. Modifying these files without careful consideration can break core project workflows or documentation standards.

- `docs-dev/**/*` (Entire submodule is read-only)
- `docs/architecture-decisions/**/*` (Modify only when adding ADRs)
- `docs-project/done/**/*` (Completed tasks should not be modified)
- `lib/**/*` (Treat the core gem implementation as stable unless working on a specific feature or bug fix requiring changes here)
- `spec/**/*` (Treat tests as read-only unless writing new tests or fixing broken ones related to code changes)
- `.gitignore` (Modify carefully when adding/removing ignored patterns)
- `Gemfile.lock` (Manage dependencies via `bundle add`/`remove` or explicit instruction)
- `bin/*` (Modify only when updating binstub templates or adding new project-specific scripts)

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
- `dist/**/*` # Built artifacts
- `build/**/*` # Build output
- `pkg/**/*` # Gem packages

## Entry Points

### Command Structure: bin/ vs exe/

The project has two distinct directories for executable commands:

- **`bin/`**: Development tools used when working on the project itself
- **`exe/`**: The actual gem executables that users will run after installing the gem

Note: Currently in transition - some user-facing commands are still in `bin/` but will eventually be moved to `exe/` or replaced with binstubs pointing to `exe/` commands.

### Development Tools (bin/)

Tools for project development and maintenance:

```bash
# Testing and code quality
bin/test              # Run the test suite
bin/lint              # Run StandardRB code quality checks
bin/build             # Build the gem and verify installation

# Task management (wraps docs-dev tools)
bin/tn                # Find next unblocked task
bin/tr                # List recent tasks
bin/tal               # List all tasks
bin/tnid              # Generate next task ID
bin/rc                # Get current release context

# Git workflow
bin/gl                # Get recent git log
bin/gc                # Git commit with standardized format
bin/cr                # Generate code review prompt
bin/cr-docs           # Generate documentation review prompt

# Utilities
bin/tree              # Display filtered project structure
bin/console           # Ruby console with gem loaded
```

### Gem Executables (exe/)

User-facing commands provided by the gem:

```bash
# LLM Integration
exe/llm-gemini-query      # Query Google Gemini models
exe/llm-gemini-models     # List available Gemini models
exe/llm-lmstudio-query    # Query local LM Studio models
exe/llm-lmstudio-models   # List available LM Studio models

# Future commands (planned)
# exe/github-repository-create
# exe/git-commit-with-message
```

### Common Workflows

- **Find Next Task**: Use `bin/tn` to identify the next unblocked task to work on
- **Run Tests**: Use `bin/test` to ensure code quality before committing
- **Query LLMs**: Use `exe/llm-gemini-query "your prompt"` or `exe/llm-lmstudio-query "your prompt"`
- **List Models**: Use `exe/llm-gemini-models` or `exe/llm-lmstudio-models` to see available models
- **Code Review**: Use `bin/cr` to generate a code review prompt from git diff
- **Commit Changes**: Use `bin/gc -i "your intention"` for standardized commits



## Submodules

### docs-dev

- Path: `docs-dev`
- Repository: [Repository URL - assumed external]
- Purpose: Contains development resources, guides, workflow instructions, tools, and templates used by the project and AI agents.
- **Important**: Commits for this submodule must be made from within the submodule directory (`../docs-dev`).

---

*This blueprint serves as a quick reference and guide for automated agents.*
