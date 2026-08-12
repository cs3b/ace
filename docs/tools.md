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
only when relevant. Add a rule to `AGENTS.md` only after an agent repeatedly gets something wrong; aim to keep the root file under ~80 lines.

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

### Command types

| Type | Environment | Prefix | Example |
|------|-------------|--------|---------|
| Skill / slash command | Chat | `/as-` | `/as-task-work 121` |
| CLI tool | Terminal | `ace-` | `ace-task show 121` |

Examples: `/as-task-work 148`, `/as-git-commit`, `/as-review-pr 90`, `ace-task show 148`, `ace-git-commit --staged`, `ace-review --preset pr`, `ace-test atoms`.

### Bundle shortcuts

- `>project` → `ace-bundle project`
- `>guide://markdown-style` → `ace-bundle guide://markdown-style`
- `>>git/commit` → load and run `ace-bundle wfi://git/commit`

Skills under `.agents/skills/*` → follow the skill `SKILL.md`. Workflow loading → `ace-bundle` / `ace-bundle wfi://…`.

### Workflow context embedding

When workflows are invoked via `/as-command`, they may include embedded context (`embed_document_source: true`).

1. Check for embedded XML sections like `<current_repository_status>` or `<available_presets>`
2. Use that context instead of running redundant commands
3. Reference embedded sections explicitly in responses

For full patterns, run `ace-bundle guide://workflow-context-embedding`.

### ACE CLI command integrity

`ace-*` commands are optimized for agentic execution. Run them directly and do not wrap or transform their terminal output.

- **MUST** invoke directly: `ace-...`
- **MUST NOT** use shell output manipulation on `ace-*` invocations: pipes (`|`, `|&`), redirects (`>`, `>>`, `2>`, `&>`), post-processors (`head`, `tail`, `grep`, `awk`, `sed`, `tee`, `xargs`), command substitution/backgrounding (`$()`, backticks, trailing `&`)
- **MUST** read referenced output files directly when an `ace-*` command prints a path (for example `.ace-local/bundle/project.md`)
- **MUST NOT** create extra temp capture files for `ace-*` output unless the user explicitly asks for export/logging
- If a violation happens, rerun the same `ace-*` command in compliant form immediately and treat that rerun as source of truth

Never reset or discard changes you didn't make — use `ace-git-commit $paths` to commit only your changes. For scoped commit/release requests, treat unrelated modified files as acceptable background state unless the user asks to clean them.

### Skill-first planning and execution

If a user names a skill (for example `/as-github-pr-create`) or the task clearly matches an available skill, that skill is mandatory and takes precedence over ad-hoc/manual flow.

**Planning phase (mandatory load, optional run)** — before drafting or finalizing any substantial plan:

1. Match named or clearly relevant skill(s)
2. Load each selected skill's `SKILL.md`
3. Load referenced workflow/guidance resources (`wfi://`, `guide://`, `tmpl://`) when available
4. Decide per skill: **Load-only** (shape the plan) or **Run** (execute the workflow when that validates assumptions better)
5. Include a short `Skills Applied` section: `Loaded:`, `Executed:` (or `none`), `Why not executed:` when a relevant skill stayed load-only

A substantial plan is incomplete if a clearly relevant skill was not loaded. If discovered later, stop and re-plan from skill-informed context.

**Execution phase** — before any non-read command:

1. Run a quick skill check and list candidate skills
2. Load selected `SKILL.md` instructions
3. Run selected skill workflow(s) as primary path
4. Use manual commands only when no applicable skill exists or a skill is unavailable/blocked
5. If manual fallback is used, state the reason briefly in status updates

If manual execution starts and a matching skill is identified later: stop manual flow, run the matching skill workflow, continue from skill outputs as source of truth.

### Search and research

- `/as-search-run` — code/file search and discovery
- `/as-search-research` — multi-search analysis and synthesis
- `/as-search-feature-research` — feature gap analysis and implementation patterns

### Testing

Always use `ace-test` instead of `bundle exec rake test` or raw `bundle exec ruby` for package tests:

- `ace-test` — run all tests in current package
- `ace-test test/file_test.rb` — run a single test file
- `ace-test atoms` — run a test group
- `ace-test molecules --profile 10` — profile slowest tests
- `ace-test-suite` — validate the entire monorepo before commits

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
