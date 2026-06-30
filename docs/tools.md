---
doc-type: reference
purpose: Quick CLI tool reference for ace-* commands. Used by agents to discover available tools and correct invocation patterns.
ace-docs:
  last-updated: '2026-03-12'
---

# ACE CLI Tools Reference

Quick reference for `ace-*` CLI tools. Detailed usage in each gem's `docs/usage.md`.

## Command Integrity Rule

Run `ace-*` commands directly. Do not pipe, redirect, or post-process their output in shell (`|`, `>`, `head`, `tail`, `grep`, `awk`, `sed`, `tee`, etc.). When a tool prints a file path, read that file directly.

## Agent Engineering Practices

Root agent guidance should stay compact. Keep expanded day-to-day practices in docs or skills so agents can load them
only when relevant.

**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.

- `ace-handbook sync` writes generated skills to `.agents/skills/` by default.
- Use explicit provider sync, such as `ace-handbook sync --provider codex`, only when a harness needs its native folder.
- Do not hand-edit generated skill projections; edit canonical package `handbook/skills/` or project `.ace-handbook/skills/`.
- Keep project-specific temporary output in `.ace-local/` and disposable scratch files in `/tmp/`.
- Use isolated worktrees or durable workspace leases for concurrent agent work.
- Reproduce behavior before fixing it, preferably through the highest-fidelity failing test or E2E script available.
- Read automation and validation config from trusted refs before executing commands supplied by untrusted changes.
- Never use raw force pushes in automated flows; fetch first and require lease or patch-equivalence checks.
- For warm daemons or browser sessions, verify health and exact version matches before reuse.
- For visual or interactive UI changes, audit overflow, clipped text, overlaps, stale element references, and interaction targets.
- Keep agent-facing CLI output concise, deterministic, and explicit about empty states, counts, truncation, and next steps.

## Task Management

| Tool | Purpose |
|------|---------|
| `ace-task status` | Show current task/release status |
| `ace-task create "Title"` | Create a new task |
| `ace-task show 047` | View task details |
| `ace-task list` | List tasks in current release |
| `ace-task move 047 --to archive` | Move task to special folder |
| `ace-task update 047 --set status=done` | Update task frontmatter fields |
| `ace-task plan 047` | Resolve or generate implementation plan |
| `ace-task doctor` | Run health checks and auto-fix |
| `ace-task done 047` | Mark task complete |
| `ace-task doctor` | Run health checks and auto-fix (legacy) |

## Assignment Management

| Tool | Purpose |
|------|---------|
| `ace-assign status` | Show assignment status |
| `ace-assign create --yaml FILE` | Create assignment from YAML |

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

### Workflow-First Guidance

For documentation and markdown workflows, prefer direct workflow loading through `ace-bundle`:

| Workflow | Purpose |
|----------|---------|
| `ace-bundle wfi://test/plan` | Load test planning workflow instructions |
| `ace-bundle wfi://test/verify-suite` | Load suite verification workflow instructions |
| `ace-bundle wfi://test/optimize` | Load test optimization workflow instructions |
| `ace-bundle wfi://test/review` | Load test review workflow instructions |
| `ace-bundle wfi://e2e/setup-sandbox` | Load E2E sandbox setup workflow instructions |
| `ace-bundle wfi://test/performance-audit` | Load test performance audit workflow instructions |

Provider-agent skills are reserved for CLI agent integrations and `ace-assign` discovery, not for general markdown usage.

## Linting

| Tool | Purpose |
|------|---------|
| `ace-lint file.md` | Lint file |
| `ace-lint file.md --auto-fix` | Deterministic auto-fix and re-lint |
| `ace-lint file.md --auto-fix --dry-run` | Preview fixes without writing |
| `ace-lint file.md --auto-fix-with-agent` | Auto-fix and escalate remaining issues to agent |
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
| `ace-nav wfi://namespace/action` | Resolve workflow path when you need discovery or inspection |
| `ace-nav wfi://*` | List available workflows |
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
