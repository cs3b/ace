---
update:
  update_frequency: weekly
  max_lines: 100
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-12-01'
---

# Project Blueprint: ACE (Agentic Coding Environment)

## What is a Blueprint?

This document provides navigation guidance for the ACE codebase, highlighting what to modify and what to avoid.

## Repository Structure

```
ace-*/          # Ruby gems following ATOM architecture (20+ production gems)
                # ace-support-core, ace-context, ace-taskflow, ace-nav, ace-llm,
                # ace-git-commit, ace-git-worktree, ace-prompt, ace-search,
                # ace-review, ace-docs, ace-lint, ace-test, ace-test-support,
                # ace-llm-providers-cli, ace-support-mac-clipboard
dev-handbook/   # Workflows, agents, guides (migrating to ace-handbook gem)
.ace-taskflow/  # Task and release management
dev-tools/      # Legacy CLI tools (mostly migrated to ace-* gems)
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
- `.ace-taskflow/done/**/*` # Completed tasks
- `.ace-taskflow/v.*/retro/**/*` # Development retrospectives
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should ignore these during normal operations:

- `.ace-taskflow/done/**/*` # Completed tasks and releases
- `.cache/ace-*/**/*` # Cached output from ace tools
- `ace-*/coverage/**/*` # Test coverage reports
- `**/test-reports/**/*` # Test report files
- `tmp/**/*` # Temporary files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `node_modules/**/*` # Node.js dependencies
- `*.bak` # Backup files
- `docs/context/cached/**/*` # Legacy cached context files
