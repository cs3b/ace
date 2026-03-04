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

## Skill First Execution (Hard Rule)

If a user names a skill (for example `$ace-git-create-pr`) or the task clearly matches an available skill, the skill is mandatory and takes precedence over manual command execution.

Execution order:
1. Match named or clearly relevant skill(s)
2. Load each selected skill's `SKILL.md` instructions
3. Run the skill workflow instruction(s)
4. Use manual commands only when no applicable skill exists or the skill is unavailable

Before any non-read command, perform a quick skill check:
- List candidate skills for the task
- Select the chosen skill (or state "no applicable skill found")
- Proceed only after this check

Planning-time requirement:
- Planning is execution of process knowledge. Before drafting or finalizing any plan, run the same skill check used for execution.
- For each chosen skill, load workflow instructions (`mise exec -- ace-bundle wfi://...`) when available.
- If protocol lookup fails, read the referenced workflow file directly and continue with that as the source of truth.
- Every substantial plan must include a short `Skills Applied` section listing which skills/workflows were loaded.

Fail-closed rule:
- A plan is incomplete if a clearly relevant skill was not loaded.
- If this is discovered later, stop and restart planning from the applicable skill outputs.

Violation recovery:
- If manual execution starts and a matching skill is identified later, stop manual flow
- Run the matching skill workflow
- Continue from skill outputs as the source of truth

## Temporary Files

When creating temporary files (debugging output, environment captures, test artifacts):

- **Do NOT** write temporary files to the project root directory
- **DO** use one of these locations:
  - `/tmp/` - For system temporary files
  - `.cache/<subfolder>/` - For project-specific cached data (e.g., `.cache/ace-test-e2e/`)

This prevents accidental commits and keeps the repository clean.
