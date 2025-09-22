# Project Blueprint: ACE (Agent Coding Environment)

## What is a Blueprint?

This document provides navigation guidance for the ACE codebase, highlighting what to modify and what to avoid.

## Repository Structure

```
ace-*/          # Ruby gems following ATOM architecture
dev-handbook/   # Workflows, agents, guides (legacy, migrating to ace-handbook)
dev-taskflow/   # Task management (legacy, migrating to ace-taskflow)
dev-tools/      # CLI tools (legacy, being split into ace-* gems)
.claude/        # Claude Code integration (commands and agent symlinks)
.ace/           # Configuration cascade root
docs/           # System documentation and ADRs
.github/        # CI/CD workflows
```

For detailed architecture and ATOM pattern, see [architecture.md](architecture.md).

## Read-Only Paths

AI agents should treat these as read-only unless explicitly instructed to modify:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `.github/workflows/**/*` # CI/CD configuration
- `dev-handbook/guides/**/*` # Development guides
- `dev-handbook/workflow-instructions/**/*` # AI workflow instructions
- `dev-taskflow/done/**/*` # Completed tasks
- `dev-taskflow/current/*/reflections/**/*` # Development reflections
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should ignore these during normal operations:

- `dev-taskflow/done/**/*` # Completed tasks and releases
- `ace-*/coverage/**/*` # Test coverage reports
- `vendor/bundle/**/*` # Bundled dependencies
- `tmp/**/*` # Temporary files
- `log/**/*` # Log files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `.idea/**/*`, `.vscode/**/*` # Editor configurations
- `**/.*.swp`, `**/.*.swo` # Swap files
- `**/.DS_Store` # macOS system files
- `**/.env`, `**/.env.*` # Environment files
- `*.session.log` # Session logs
- `*.tmp` # Temporary files
- `docs/context/cached/**/*` # Cached context files (generated)