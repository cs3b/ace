---
doc-type: user
title: ace-git-worktree Handbook Catalog
purpose: Catalog of ace-git-worktree workflows, skills, and agents
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git-worktree Handbook Catalog

Reference for package-owned handbook resources in `ace-git-worktree/handbook/`.

## Skills

| Skill | What it does |
|-------|--------------|
| `as-git-worktree` | Run the top-level task-aware worktree workflow |
| `as-git-worktree-create` | Create task-aware, PR-aware, or branch-based worktrees |
| `as-git-worktree-manage` | List, switch, prune, and remove existing worktrees |

## Workflow Instructions

| Protocol Path | Purpose | Invoked by |
|---------------|---------|------------|
| `wfi://git/worktree` | Load the main worktree workflow entry point | `as-git-worktree` |
| `wfi://git/worktree-create` | Guide task-aware or branch-based creation flows | `as-git-worktree-create` |
| `wfi://git/worktree-manage` | Guide list, switch, remove, prune, and config flows | `as-git-worktree-manage` |

## Agents

* `handbook/agents/worktree.ag.md` for focused worktree command execution

## Related Docs

* [Getting Started](getting-started.md)
* [CLI Usage Reference](usage.md)
* Load workflows directly with `ace-bundle`, for example `ace-bundle wfi://git/worktree`
