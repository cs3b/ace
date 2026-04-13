# Repository Guidelines

Read `CLAUDE.md` first.

## ACE CLI Command Integrity

Run `ace-*` commands directly. Do not pipe, redirect, or post-process `ace-*` output.

- Run `ace-*` commands directly.
- When an `ace-*` command prints a file path, read that file directly.
- Use `.ace-local/` for project-local ACE artifacts and `/tmp/` for disposable temporary files.

## Working Rules

- Keep repository-specific guidance in this file.
- Do not overwrite unrelated user-owned content when refreshing generated bootstrap files.
- Use `ace-test` for tests when ACE packages provide test targets.
