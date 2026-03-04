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
- **MUST** read referenced output files directly when an `ace-*` command prints a path (for example `.ace-local/bundle/project.md`)
- **MUST NOT** create extra temp capture files for `ace-*` output (including in `/tmp` or `.cache`) unless user explicitly asks for export/logging
- If a violation happens, rerun the command in compliant form immediately and continue from the canonical output

## Scoped Commits (ace-git-commit)
When user requests a scoped commit/release:
- Do not revert unrelated working-tree changes.
- Use path-scoped commit commands, e.g. `mise exec -- ace-git-commit <path1> <path2> ...`.
- Treat unrelated modified files as acceptable background state unless user explicitly asks to clean/revert them.

## Skill-First Planning and Execution (Hard Rule)

If a user names a skill (for example `/ace-github-pr-create`) or the task clearly matches an available skill, that skill is mandatory and takes precedence over ad-hoc/manual flow.

### Planning phase (mandatory load, optional run)

Before drafting or finalizing any substantial plan:

1. Match named or clearly relevant skill(s)
2. Load each selected skill's `SKILL.md`
3. Load referenced workflow/guidance resources (`wfi://`, `guide://`, `tmpl://`) when available
4. Decide per skill:
   - **Load-only mode**: use skill/workflow knowledge to shape the plan without running the full workflow
   - **Run mode**: execute the full skill workflow when that produces better planning artifacts or validates assumptions
5. Include a short `Skills Applied` section in the plan:
   - `Loaded:` skills/resources read for planning
   - `Executed:` workflows actually run (or `none`)
   - `Why not executed:` brief reason when a relevant skill stayed load-only

Planning fail-closed rule:
- A substantial plan is incomplete if a clearly relevant skill was not loaded.
- If discovered later, stop and re-plan from skill-informed context.

### Execution phase (skill workflow first)

Before any non-read command:

1. Run a quick skill check and list candidate skills
2. Load selected `SKILL.md` instructions
3. Run selected skill workflow(s) as primary path
4. Use manual commands only when:
   - no applicable skill exists, or
   - a skill is unavailable/blocked
5. If manual fallback is used, state the reason briefly in status updates.

Execution violation recovery:
- If manual execution starts and a matching skill is identified later:
  - stop manual flow
  - run the matching skill workflow
  - continue from skill outputs as source of truth

## Temporary Files

When creating temporary files (debugging output, environment captures, test artifacts):

- **Do NOT** write temporary files to the project root directory
- **DO** use one of these locations:
  - `/tmp/` - For system temporary files
  - `.ace-local/<subfolder>/` - For project-specific cached data (e.g., `.ace-local/test-e2e/`)

This prevents accidental commits and keeps the repository clean.

## Test Execution Policy

- `mise exec -- ace-test` and `mise exec -- ace-test-suite` are allowed by default when applicable.
- Do **not** run `ace-test-e2e`, `ace-test-e2e-suite`, or other E2E runners unless the user explicitly asks.
