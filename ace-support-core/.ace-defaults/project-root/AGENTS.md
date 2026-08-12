# Repository Guidelines

ACE generated this starter guidance from `ace-support-core` defaults.
Customize it for your repository-specific rules and workflows.
Refresh the starter version with `bundle exec ace-config sync ace-support-core --force`.
Run `bundle exec ace-handbook sync` separately to refresh generated `.agents/skills`.

See `docs/tools.md#agent-engineering-practices` for expanded day-to-day agent practices.

**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.

## Principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets current requirements. Avoid speculative abstractions, configuration, and indirection.
- Grow the system in layers from a working end-to-end core. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries; lean on dependencies already in the project before inventing or adding packages.
- Make architectural decisions for the long term. Do not accept intentional stopgaps meant to be replaced later.
- Study how established products solve the problem before designing. Adopt proven patterns rather than inventing from scratch.

## Hard rules

- Run `ace-*` commands directly. Do not pipe, redirect, or post-process their output; when they print a path, read that file.
- Use `.ace-local/` for project-local ACE artifacts and `/tmp/` for disposable temps.
- Prefer `ace-test` / `ace-test-suite` over raw `bundle exec` tests when those targets exist.
