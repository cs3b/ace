# Repository Guidelines

Agent guidance for the Coding Agent Workflow Toolkit (ACE) repository.

Skills live only in `.agents/skills/` (synced with `ace-handbook sync`). Do not use or recreate harness-native skill trees such as `.codex/skills/` or `.claude/skills/`.

See `docs/tools.md#agent-engineering-practices` for expanded day-to-day agent practices.

**Cost Bias Override:** do not optimize for human work-weeks or token budgets — choose the technically correct path (full coverage, proper refactors, robust design) even when it costs more turns.

## Command Types

This project has two distinct types of commands:

### Chat Skills / Slash Commands

**Run from:** agent chat  
**Prefix:** `/as-`  
**Purpose:** Invoke AI-assisted workflows with full agent context  

Examples:
- `/as-task-work 148` — work on a specific task with full context
- `/as-git-commit` — generate an intelligent commit with LLM assistance
- `/as-review-pr 90` — review a pull request with AI analysis
- `/as-task-draft` — draft a new task specification

### CLI Tools (Terminal Commands)

**Run from:** terminal  
**Prefix:** `ace-`  
**Purpose:** Deterministic operations for direct execution  

Examples:
```bash
ace-task show 148
ace-git-commit --staged
ace-review --preset pr
ace-test atoms
```

| Type | Environment | Prefix | Example |
|------|-------------|--------|---------|
| Skill / slash command | Chat | `/as-` | `/as-task-work 121` |
| CLI tool | Terminal | `ace-` | `ace-task show 121` |

## Special Shortcut Conventions

#### `>` use ace-bundle to load content

`>project` → `ace-bundle project`  
`>guide://markdown-style` → `ace-bundle guide://markdown-style`

#### `>>` read content from ace-bundle and run instructions

`>>git/commit` → load and run `ace-bundle wfi://git/commit`

## Command Recognition

- Skills under `.agents/skills/*` → follow the skill `SKILL.md`
- Workflow loading → `ace-bundle` / `ace-bundle wfi://…`

## Workflow Context Embedding

When workflows are invoked via `/as-command`, they may include embedded context (`embed_document_source: true`).

Agents should:
1. Check for embedded XML sections like `<current_repository_status>` or `<available_presets>`
2. Use that context instead of running redundant commands
3. Reference embedded sections explicitly in responses

For full patterns, run `ace-bundle guide://workflow-context-embedding`.

## ACE CLI Command Integrity (Hard Rule)

`ace-*` commands are already optimized for agentic execution. Run them directly and do not wrap or transform their terminal output.

- **MUST** invoke directly: `ace-...`
- **MUST NOT** use shell output manipulation on `ace-*` invocations:
  - pipes: `|`, `|&`
  - redirects: `>`, `>>`, `2>`, `&>`
  - post-processors: `head`, `tail`, `grep`, `awk`, `sed`, `tee`, `xargs`
  - command substitution/backgrounding: `$()`, backticks, trailing `&`
- **MUST** read referenced output files directly when an `ace-*` command prints a path (for example `.ace-local/bundle/project.md`)
- **MUST NOT** create extra temp capture files for `ace-*` output (including in `/tmp` or `.cache`) unless the user explicitly asks for export/logging
- If a violation happens, rerun the same `ace-*` command in compliant form immediately and treat that rerun as source of truth

Never reset or discard changes you didn't make — use `ace-git-commit $paths` to commit only your changes.

## Scoped Commits (ace-git-commit)

When the user requests a scoped commit/release:
- Do not revert unrelated working-tree changes.
- Use path-scoped commit commands, e.g. `ace-git-commit <path1> <path2> ...`.
- Treat unrelated modified files as acceptable background state unless the user explicitly asks to clean/revert them.

## Skill-First Planning and Execution (Hard Rule)

If a user names a skill (for example `/as-github-pr-create`) or the task clearly matches an available skill, that skill is mandatory and takes precedence over ad-hoc/manual flow.

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
  - `/tmp/` — system temporary files
  - `.ace-local/<subfolder>/` — project-specific cached data (e.g., `.ace-local/test-e2e/`)

## Testing Constraints

**CRITICAL:** NEVER use `bundle exec rake test` or `bundle exec ruby` for running tests in this project.

**ALWAYS use `ace-test` instead:**

- `ace-test` — run all tests in current package
- `ace-test test/file_test.rb` — run a single test file
- `ace-test atoms` — run a test group
- `ace-test molecules --profile 10` — profile slowest tests
- `ace-test-suite` — validate the entire monorepo before commits

## Search & Research Commands

- `/as-search-run` — code/file search and discovery
- `/as-search-research` — multi-search analysis and synthesis
- `/as-search-feature-research` — feature gap analysis and implementation patterns

## Project Context

For comprehensive project details, run: `ace-bundle project`.

Do not duplicate project context in responses — reference ace-bundle output.
