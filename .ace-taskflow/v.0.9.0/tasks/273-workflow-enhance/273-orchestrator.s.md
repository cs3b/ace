---
id: v.0.9.0+task.273
status: in-progress
priority: medium
estimate: 16h
worktree:
  branch: 273-namespace-workflows-with-domain-prefixes
  path: "../ace-task.273"
  created_at: '2026-02-19 18:46:42'
  updated_at: '2026-02-19 18:46:42'
  target_branch: main
---

# Namespace Workflows with Domain Prefixes

## Overview

Introduce subdirectory-based namespace prefixes to all ~88 workflow files across the monorepo. Currently all workflows are flat in `handbook/workflow-instructions/` with verb-first naming. This causes no domain grouping, name collisions (ace-search's `research.wf.md` is shadowed), and inconsistent patterns.

After this change:
- Workflows live in namespace subdirectories: `handbook/workflow-instructions/task/create.wf.md`
- URIs use slash: `wfi://task/create`, slash commands use hyphen: `ace:task-create`
- 15 namespaces: task, bug, idea, retro, release, git, review, test, e2e, docs, search, handbook, assign, lint, integration
- Multi-item variants use `-batch` suffix
- Namespace browsing: `wfi://task/*` lists all task workflows

## Subtasks

- **01**: (overall behavioral spec — see 273.01 for full mapping tables and design decisions)
- **02**: Verify ProtocolScanner subdirectory resolution (ace-support-nav)
- **03**: Namespace ace-lint workflows (pilot — 2 workflows → `lint/`)
- **04**: Namespace ace-assign workflows (5 → `assign/`)
- **05**: Namespace ace-search workflows (3 → `search/`, fixes shadowing)
- **06**: Namespace ace-review workflows (4 → `review/`)
- **07**: Namespace ace-test workflows (5 → `test/`)
- **08**: Namespace ace-test-runner-e2e workflows (10 → `e2e/`)
- **09**: Namespace ace-docs workflows (12 → `docs/`, includes update-usage and update-roadmap)
- **10**: Namespace ace-git packages workflows (10 → `git/`)
- **11**: Namespace ace-handbook workflows (12 → `handbook/`)
- **12**: Namespace ace-taskflow workflows (23 → `task/`, `bug/`, `idea/`, `retro/`, `release/`)
- **13**: Namespace root and integration workflows (3 → `release/`, `integration/`)
- **14**: Update CLAUDE.md, tools.md, and documentation

## Execution Order

02 (verify) → 03 (pilot) → 04-13 (parallel by package) → 14 (docs, last)

## References

- Plan: `/home/mc/.claude/plans/joyful-tumbling-dongarra.md`
- ProtocolScanner: `ace-support-nav/lib/ace/support/nav/molecules/protocol_scanner.rb`