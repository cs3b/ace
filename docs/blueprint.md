# Project Blueprint: ACE (Agent Coding Environment)

## What is a Blueprint?

This document provides a concise overview of the project's structure and organization, highlighting key directories and files to help developers (especially AI assistants) quickly understand how to navigate the codebase. It should be updated periodically using the `update-blueprint` workflow.

## Project Organization

This is a **mono-repo** with modular Ruby gems providing the ACE ecosystem:

### Current ace-* Gems (Operational)

- **ace-core/** - Zero-dependency configuration management gem
  - **lib/ace/core/** - ATOM-structured implementation
    - **atoms/** - Pure functions (yaml_parser, env_parser, deep_merger)
    - **molecules/** - Composed operations (yaml_loader, config_finder)
    - **organisms/** - Business logic (config_resolver, environment_manager)
    - **models/** - Data structures (config, cascade_path)
  - **test/** - Minitest test suite (80+ tests)
  - **exe/** - No executables (library gem)

- **ace-context/** - Context loading with smart caching
  - **lib/ace/context/** - ATOM-structured implementation
    - **atoms/** - File utilities and formatters
    - **molecules/** - Context operations (context_chunker, context_merger)
    - **organisms/** - Main context loader
    - **models/** - Data models (context_data, preset)
  - **test/** - Minitest test suite
  - **exe/ace-context** - CLI executable

- **ace-test-runner/** - Test execution with parallel processing
  - **lib/ace/test_runner/** - Test discovery and execution
  - **test/** - Minitest test suite
  - **exe/ace-test** - Individual test runner
  - **exe/ace-test-suite** - CI-optimized suite runner

- **ace-test-support/** - Shared testing infrastructure
  - **lib/ace/test_support/** - Test utilities and helpers
  - **test/** - Minitest test suite (65+ tests)
  - **exe/** - No executables (support library)

### Legacy Components (Being Migrated)

- **dev-handbook/** - Development resources and workflows (Git submodule, migrating to ace-handbook)
  - **workflow-instructions/** - AI agent workflows
  - **templates/** - Document templates
  - **.integrations/claude/agents/** - Specialized agents

- **dev-taskflow/** - Task management (Git submodule, migrating to ace-taskflow)
  - **current/** - Active release work
  - **done/** - Completed releases

- **dev-tools/** - CLI tools (Git submodule, being split into ace-* gems)
  - **exe/** - Legacy executable commands

### Core Documentation

- **docs/** - System-level documentation
  - **decisions/** - Architecture Decision Records (ADRs)
  - **context/** - Context templates and cached output
  - **migrations/** - Documentation migration records

- **.github/** - CI/CD configuration
  - **workflows/ci.yml** - GitHub Actions matrix testing

- **Gemfile** - Root workspace dependencies
- **.bundle/config** - Workspace bundle configuration


## Read-Only Paths

AI agents should treat the following paths as read-only unless explicitly instructed to modify them for specific maintenance or update tasks:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `.github/workflows/**/*` # CI/CD configuration
- `dev-handbook/guides/**/*` # Legacy development guides
- `dev-handbook/workflow-instructions/**/*` # Legacy AI workflow instructions
- `dev-taskflow/done/**/*` # Completed tasks
- `dev-taskflow/current/*/reflections/**/*` # Development reflections
- `*.lock` # Dependency lock files
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should generally ignore the contents of the following paths during normal operations:

- `dev-taskflow/done/**/*` # Completed tasks and releases
- `ace-*/coverage/**/*` # Test coverage reports
- `ace-*/.bundle/**/*` # Gem-specific bundle cache
- `vendor/bundle/**/*` # Bundled dependencies
- `tmp/**/*` # Temporary files
- `log/**/*` # Log files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `.idea/**/*`, `.vscode/**/*` # Editor configurations
- `**/.*.swp`, `**/.*.swo` # Swap files
- `**/.DS_Store` # macOS system files
- `**/Thumbs.db` # Windows system files
- `**/.env` # Environment files
- `**/.env.*` # Environment variants
- `*.session.log` # Session logs
- `*.lock` # Lock files (except for reference)
- `*.tmp` # Temporary files
- `*~` # Backup files
- `docs/context/cached/**/*` # Cached context files (generated)
