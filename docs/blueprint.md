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
ace-*/          # Ruby gems following ATOM architecture (25+ production gems)
                # Each gem includes handbook/ for workflows, guides, templates
                # Key gems: ace-handbook, ace-taskflow, ace-context, ace-nav,
                # ace-git, ace-git-commit, ace-review, ace-docs, ace-lint,
                # ace-search, ace-llm, ace-test-runner
.ace-taskflow/  # Task and release management
.claude/        # Claude Code integration (commands and agent symlinks)
.ace/           # Configuration cascade root
docs/           # System documentation and ADRs
.github/        # CI/CD workflows
_legacy/        # Archived content (dev-handbook, dev-tools)
```

For detailed architecture and ATOM pattern, see [architecture.md](architecture.md).

## Read-Only Paths

AI agents should treat these as read-only unless explicitly instructed to modify:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `ace-*/handbook/**/*` # Gem workflows, guides, templates
- `.github/workflows/**/*` # CI/CD configuration
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
- `_legacy/**/*` # Archived content (dev-handbook, dev-tools)
