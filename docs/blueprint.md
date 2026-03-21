---
doc-type: bundle
title: "Project Blueprint: ACE (Agentic Coding Environment)"
purpose: Documentation for docs/blueprint.md
ace-docs:
  last-updated: '2026-03-04'
---

# Project Blueprint: ACE (Agentic Coding Environment)

## What is a Blueprint?

A blueprint is a navigation guide - not architecture documentation. It tells AI agents and developers what paths exist, which to treat carefully, and which to ignore. For architecture decisions and design patterns, see [architecture.md](architecture.md).

## Repository Structure

```
ace-*/          # Ruby gems following ATOM architecture (25+ production gems)
                # Each gem includes handbook/ for workflows, guides, templates
                # Workflow files use namespaced paths: handbook/workflow-instructions/<namespace>/<action>.wf.md
                # Key gems: ace-handbook, ace-taskflow, ace-idea, ace-bundle, ace-nav,
                # ace-git, ace-git-commit, ace-review, ace-docs, ace-lint,
                # ace-search, ace-llm, ace-test (documentation), ace-test-runner (CLI)
.ace-taskflow/  # Task and release management
.claude/        # Claude Code integration (commands and agent symlinks)
.ace/           # Configuration cascade root
docs/           # System documentation and ADRs
.github/        # CI/CD workflows
_legacy/        # Archived content (dev-handbook, dev-tools)
```

## Read-Only Paths

AI agents should treat these as read-only unless explicitly instructed to modify:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `ace-*/handbook/**/*` # Gem workflows, guides, templates
- `.github/workflows/**/*` # CI/CD configuration
- `.ace-taskflow/v.*/retro/**/*` # Development retrospectives
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should ignore these during normal operations:

- `.ace-taskflow/done/**/*` # Completed tasks and releases
- `.ace-local/**/*` # Cached output from ace tools (e.g., .ace-local/review/, .ace-local/lint/)
- `ace-*/coverage/**/*` # Test coverage reports
- `**/test-reports/**/*` # Test report files
- `tmp/**/*` # Temporary files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `node_modules/**/*` # Node.js dependencies
- `*.bak` # Backup files
- `_legacy/**/*` # Archived content (dev-handbook, dev-tools)
