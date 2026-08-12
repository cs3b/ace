# Repository Guidelines

Agent guidance for the Coding Agent Workflow Toolkit (ACE) repository.

Skills live only in `.agents/skills/` (synced with `ace-handbook sync`). Do not use or recreate harness-native skill trees such as `.codex/skills/` or `.claude/skills/`.

See `docs/tools.md#agent-engineering-practices` for expanded day-to-day agent practices.

**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.

## Principles

- Do not preserve backward compatibility (pre-1.0; see ADR-024). Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers from a working end-to-end core. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries; lean on dependencies already in the project before inventing or adding packages.
- Make architectural decisions for the long term. Do not accept intentional stopgaps meant to be replaced later.
- Study how established products solve the problem before designing. Adopt proven patterns rather than inventing from scratch.

## Commands

| Type | Where | Prefix | Examples |
|------|-------|--------|----------|
| Skill / slash | Chat | `/as-` | `/as-task-work 148`, `/as-git-commit` |
| CLI | Terminal | `ace-` | `ace-task show 148`, `ace-test atoms`, `ace-bundle project` |

- Skills under `.agents/skills/*` → follow that skill's `SKILL.md`.
- Tests: always `ace-test` / `ace-test-suite` — never `bundle exec rake test` or raw `bundle exec ruby` for package tests.
- Project context: `ace-bundle project` (do not duplicate it in responses).

## Hard rules

- Run `ace-*` commands directly. Do not pipe, redirect, or post-process their output; when they print a path, read that file. Do not create extra capture files for `ace-*` output unless the user asks.
- Never reset or discard unrelated changes. Use path-scoped commits: `ace-git-commit <paths…>`.
- Temp files: `.ace-local/<subfolder>/` or `/tmp/` — never the project root.
- Skill-first: if a user names a skill or the task clearly matches one, load and follow it before ad-hoc work. Full planning/execution protocol: `docs/tools.md#agent-engineering-practices`.
