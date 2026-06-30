# Repository Guidelines

ACE generated this starter guidance from `ace-support-core` defaults.
Customize it for your repository-specific rules and workflows.
Refresh the starter version with `bundle exec ace-config sync ace-support-core --force`.
Run `bundle exec ace-handbook sync` separately to refresh generated `.agents/skills`.

Read `CLAUDE.md` first.
See `docs/tools.md#agent-engineering-practices` for expanded day-to-day agent practices.

**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.

## ACE CLI Command Integrity

Run `ace-*` commands directly. Do not pipe, redirect, or post-process `ace-*` output.

- Run `ace-*` commands directly.
- When an `ace-*` command prints a file path, read that file directly.
- Use `.ace-local/` for project-local ACE artifacts and `/tmp/` for disposable temporary files.

## Working Rules

- Keep repository-specific guidance in this file.
- Do not overwrite unrelated user-owned content when refreshing generated bootstrap files.
- Use `ace-test` for tests when ACE packages provide test targets.
