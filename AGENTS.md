# Repository Guidelines

Read `CLAUDE.md` first. The only additional guidance here is specific to Codex sandbox execution.

## Codex Sandbox (mise)
Always run `ace-*` commands via `mise exec --` so the repo PATH/env is applied.

## ACE CLI Command Integrity (Hard Rule)

`ace-*` commands are already optimized for agentic execution. Run them directly and do not wrap or transform their terminal output.

- **MUST** invoke directly: `mise exec -- ace-...`
- **MUST NOT** use shell output manipulation on `ace-*` invocations:
  - pipes: `|`, `|&`
  - redirects: `>`, `>>`, `2>`, `&>`
  - post-processors: `head`, `tail`, `grep`, `awk`, `sed`, `tee`, `xargs`
  - command substitution/backgrounding: `$()`, backticks, trailing `&`
- **MUST** read referenced output files directly when an `ace-*` command prints a path (for example `.cache/ace-bundle/project.md`)
- **MUST NOT** create extra temp capture files for `ace-*` output (including in `/tmp` or `.cache`) unless user explicitly asks for export/logging
- If a violation happens, rerun the command in compliant form immediately and continue from the canonical output

## Scoped Commits (ace-git-commit)
When user requests a scoped commit/release:
- Do not revert unrelated working-tree changes.
- Use path-scoped commit commands, e.g. `mise exec -- ace-git-commit <path1> <path2> ...`.
- Treat unrelated modified files as acceptable background state unless user explicitly asks to clean/revert them.

## Temporary Files

When creating temporary files (debugging output, environment captures, test artifacts):

- **Do NOT** write temporary files to the project root directory
- **DO** use one of these locations:
  - `/tmp/` - For system temporary files
  - `.cache/<subfolder>/` - For project-specific cached data (e.g., `.cache/ace-test-e2e/`)

This prevents accidental commits and keeps the repository clean.
