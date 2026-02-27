---
doc-type: reference
purpose: Quick CLI tool reference for ace-* commands. Used by agents to discover available tools and correct invocation patterns.
update:
  update_frequency: weekly
  max_lines: 150
  required_sections: []
  last-updated: '2026-02-23'
---

# ACE CLI Tools Reference

Quick reference for `ace-*` CLI tools. Detailed usage in each gem's `docs/usage.md`.

## Command Integrity Rule

Run `ace-*` commands directly. Do not pipe, redirect, or post-process their output in shell (`|`, `>`, `head`, `tail`, `grep`, `awk`, `sed`, `tee`, etc.). When a tool prints a file path, read that file directly.

## Task Management

| Tool | Purpose |
|------|---------|
| `ace-taskflow status` | Show current task/release status |
| `ace-task show 047` | View task details |
| `ace-task list` | List tasks in current release |
| `ace-task done 047` | Mark task complete |
| `ace-taskflow doctor` | Run health checks and auto-fix |

## Assignment Management

| Tool | Purpose |
|------|---------|
| `ace-assign status` | Show assignment status |
| `ace-assign create CONFIG` | Create assignment from YAML |

## Git Operations

| Tool | Purpose |
|------|---------|
| `ace-git-commit` | Generate commit message from changes |
| `ace-git-commit -i "msg"` | Commit with inline message hint |
| `ace-git-commit file.rb lib/` | Commit specific files only |
| `ace-git status` | Show branch, PR, and activity context |
| `ace-git-worktree create --task 081` | Create worktree for task |
| `ace-git-worktree list` | List all worktrees |
| `ace-git-worktree remove --task 081` | Remove task worktree |
| `ace-git-worktree switch 081` | Get worktree path (for cd) |

## Code Review

| Tool | Purpose |
|------|---------|
| `ace-review --preset code-deep --pr 123` | Review PR with preset |
| `ace-review --task 121` | Review task implementation |
| `ace-review --list-presets` | Show available presets |

## Testing

| Tool | Purpose |
|------|---------|
| `ace-test` | Run all tests in current package |
| `ace-test atoms` | Run atom tests only |
| `ace-test ace-bundle` | Run tests in specific package |
| `ace-test-suite` | Run all tests across monorepo |

### Testing Skills

| Skill | Purpose |
|-------|---------|
| `/ace-test-plan` | Plan test coverage before coding |
| `/ace-test-verify-suite` | Audit test suite health (quick/standard/deep) |
| `/ace-test-optimize` | Profile and fix slow tests |
| `/ace-test-review` | Review test PR for quality |
| `/ace-e2e-setup-sandbox` | Set up safe E2E environment |
| `/ace-test-performance-audit` | Generate test performance audit report |

## Linting

| Tool | Purpose |
|------|---------|
| `ace-lint file.md` | Lint file |
| `ace-lint file.md --fix` | Auto-fix lint issues |
| `ace-lint --doctor` | Diagnose lint configuration health |

## Documentation

| Tool | Purpose |
|------|---------|
| `ace-docs status` | Check document status |
| `ace-docs update file.md` | Update document metadata |

## Context & Navigation

| Tool | Purpose |
|------|---------|
| `ace-bundle project` | Load project context |
| `ace-bundle wfi://namespace/action` | Load workflow via protocol |
| `ace-nav wfi://namespace/action` | Get path of resource |
| `ace-nav wfi://*` | List all workflows |
| `ace-search "pattern"` | Search content (regex) |
| `ace-search "*.rb" --files` | Search files (glob) |

## Simulation

| Tool | Purpose |
|------|---------|
| `ace-sim run` | Run scenario simulation with provider comparison |
| `ace-sim run --dry-run` | Non-mutating simulation run |

## Security

| Tool | Purpose |
|------|---------|
| `ace-git-secrets scan` | Scan history for leaked tokens |
| `ace-git-secrets revoke` | Revoke detected tokens |

## Utilities

| Tool | Purpose |
|------|---------|
| `ace-llm "prompt" -m MODEL` | Query LLM provider |
| `ace-b36ts` | Generate timestamp ID (6-char Base36) |
| `ace-b36ts decode ID` | Decode ID to datetime |

---

*Detailed docs: each `ace-*/docs/usage.md`*
