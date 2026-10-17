---
doc-type: bundle
title: 'Project Blueprint: ACE (Agentic Coding Environment)'
purpose: 'Navigation map for the ACE repository: paths, state owners, and read-only areas.'
ace-docs:
  last-updated: '2026-10-17'
  last-checked: '2026-10-17'
---

# Project Blueprint: ACE (Agentic Coding Environment)

## What is a Blueprint?

A blueprint is a navigation guide - not architecture documentation. It tells AI agents and developers what paths exist, which to treat carefully, and which to ignore. For architecture decisions and design patterns, see [architecture.md](architecture.md). For the canonical lab state-owner map and executable flow, see [lab-flow.md](lab-flow.md).

## Repository Structure

```
ace-*/          # Ruby gems following ATOM architecture (25+ production gems)
                # Each gem includes handbook/ for workflows, guides, templates
                # Workflow files use namespaced paths: handbook/workflow-instructions/<namespace>/<action>.wf.md
                # Key gems: ace-handbook, ace-task, ace-assign, ace-overseer, ace-hitl,
                # ace-idea, ace-bundle, ace-nav, ace-git, ace-git-commit, ace-git-worktree,
                # ace-review, ace-docs, ace-lint, ace-search, ace-llm,
                # ace-test (documentation), ace-test-runner (CLI), ace-runtime
.ace-tasks/     # Project task specs and release history (tracked; ace-task)
.ace/           # Project configuration cascade root (tracked; configuration only)
.ace-handbook/  # Project-owned handbook overrides (guides/workflows/skills)
.ace-local/     # Local untracked state (assignments, HITL events, review sessions, private _overseer)
.ace-wt/        # Task worktrees, one per project task
.agents/skills/ # Default generated ACE skill projection
.claude/        # Claude Code integration (explicit provider sync only)
.codex/         # Codex integration (explicit provider sync only)
.ace-bin/       # Shared scripts for non-package CLI helpers
docs/           # System documentation and ADRs
.github/        # CI/CD workflows
_legacy/        # Archived content (dev-handbook, dev-tools)
```

## State owners

Persisted lab state has one write location and one owner:

- `.ace-tasks/` -- project tasks (ace-task).
- `.ace-local/overseer/tasks/` -- private untracked `_overseer` list

  (`ace-task --in _overseer`).

- `.ace-local/assign/` -- assignment plan and step state (ace-assign).
- `.ace-local/coworker/` -- reserved L3 coworker configuration.
- `.ace-local/hitl/` -- HITL event files (ace-hitl).
- `.ace-wt/<task>/` -- one worktree per project task (ace-git-worktree).

Explicit non-owners: no journal, authority/admission service, listener/daemon,
topology registry, queue engine, or extra state cache/broker. tmux, Herdr, and
Hermes are transports only.

## Read-Only Paths

AI agents should treat these as read-only unless explicitly instructed to modify:

- `docs/decisions/**/*` # Architecture Decision Records
- `docs/migrations/**/*` # Documentation migration records
- `ace-*/lib/**/*` # Gem source code (modify only for bug fixes)
- `ace-*/test/**/*` # Gem test files (modify only for test updates)
- `ace-*/handbook/**/*` # Gem workflows, guides, templates
- `.github/workflows/**/*` # CI/CD configuration
- `Gemfile.lock` # Root workspace lock file

## Ignored Paths

AI agents should ignore these during normal operations:

- `.ace-tasks/_archive/**/*` # Archived task history (history only, not current owners)
- `.ace-local/**/*` # Local untracked state (assignments, HITL, review, private _overseer)
- `.ace-wt/**/*` # Task worktrees
- `ace-*/coverage/**/*` # Test coverage reports
- `**/test-reports/**/*` # Test report files
- `tmp/**/*` # Temporary files
- `.git/**/*` # Git internals
- `.bundle/**/*` # Bundle cache
- `node_modules/**/*` # Node.js dependencies
- `*.bak` # Backup files
- `_legacy/**/*` # Archived content (dev-handbook, dev-tools)

## ace-design

`ace-design/` owns shared site/app design workflows and source skills, contextual cards and benchmark fixtures. Ruby ATOM layers validate sessions/catalogs and orchestrate CLI commands; `browser/preview.mjs` uses Node HTTP, while the separate pinned Playwright/axe runner produces inspection evidence. The agent owns design generation and feedback. Runtime dependencies and evidence are local under `.ace-local/design/`; native design is future work.
