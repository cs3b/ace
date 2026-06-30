<div align="center">
  <h1>ACE - Agentic Coding Environment</h1>

  Workflow harness for coding agents — and the developers who work with them.

  <img src="docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>
</div>

[Quick Start](docs/quick-start.md) | [Vision](docs/vision.md) | [Architecture](docs/architecture.md) | [Tools Reference](docs/tools.md)
> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

## The Problem

Coding agents can write code, but they still lack the workflow layer around the code:

- Your tasks live in a SaaS dashboard your agent can't see
- Context is scattered across files the agent doesn't know to load
- Review feedback is verbal and untracked — nothing saved, nothing actionable
- Multi-step workflows require you to babysit every transition

ACE gives agent harnesses like Claude Code and Codex CLI the workflow layer they're missing — task pipelines, context bundles, review presets, and skills — as standard CLI commands both you and your agents run the same way.

## What ACE Does

**Tasks and ideas as files your agent can read**

- Capture ideas and turn them into task specs with subtasks.
- Track progress in markdown files that live in your repo.
- Let any agent read the same task state you do.

```bash
ace-idea create "Add retry logic to webhook delivery" --tags reliability
ace-task create "Implement webhook retry" --priority high
```

[`ace-task`](ace-task/) | [`ace-idea`](ace-idea/)

**One command from task to shipped PR**

- Provision an isolated worktree.
- Open a tmux window for focused execution.
- Kick off a multi-step assignment that runs implement, test, review, and ship.

```bash
ace-overseer work-on --task 8r3
```

[`ace-overseer`](ace-overseer/) orchestrates [`ace-assign`](ace-assign/), [`ace-git-worktree`](ace-git-worktree/), and [`ace-tmux`](ace-tmux/)

**Multi-model code review with tracked feedback**

- Run the same diff through multiple LLM providers.
- Compare review output side by side.
- Track suggestions through a verified, pending, and resolved lifecycle.

```bash
ace-review --preset code-deep --pr 123
```

[`ace-review`](ace-review/)

**Context loading on demand**

- Load project context, workflow instructions, and guides through `wfi://`, `guide://`, and `tmpl://`.
- Bundle context for agents or load it directly yourself.

```bash
ace-bundle wfi://task/work
```

[`ace-bundle`](ace-bundle/) | [`ace-handbook`](ace-handbook/) | [`ace-search`](ace-search/)

## Install

Ruby 3.2+ required.

Choose one setup path:

- **Minimal (first-use default):** task specs, context loading, provider access, and one agent integration.
- **Full-stack:** complete ACE workflow surface (assign/overseer/review/tmux/tests/docs/retro/demo/git helpers).

### What this will create

Before you run setup, expect these repository artifacts:

- `.ace/` (project-level ACE overrides/config when you sync package config)
- Agent skill directories from installed integrations (for example `.codex/skills/`, `.claude/skills/`)
- Optional `AGENTS.md`, `CLAUDE.md`, and `docs/tools.md` starter guidance with ACE provenance, customization notes,
  expanded [agent engineering practices](docs/tools.md#agent-engineering-practices), and refresh commands when you also
  sync `ace-support-core` project-root templates
  (existing user-authored guidance is preserved)
- `Gemfile` and `Gemfile.lock` dependency updates from `bundle add`/`bundle install`

### 1. Add the ACE tools you need

Minimal path:

```bash
bundle add --group "development, test" \
  ace-task ace-bundle ace-handbook ace-llm ace-llm-providers-cli \
  ace-handbook-integration-codex
# Optional integrations: ace-handbook-integration-claude, ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi
```

Full-stack path:

```bash
bundle add --group "development, test" \
  ace-idea ace-task ace-sim \
  ace-overseer ace-assign ace-git-worktree ace-tmux \
  ace-bundle ace-handbook ace-search ace-docs ace-llm ace-llm-providers-cli \
  ace-review ace-lint ace-test-runner ace-test-runner-e2e ace-retro ace-demo \
  ace-git-commit ace-git-secrets ace-git \
  ace-handbook-integration-claude ace-handbook-integration-codex
# Also available: ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi
```

Dependencies like `ace-git`, `ace-tmux`, and all `ace-support-*` gems are pulled in automatically.

If you install only the minimal path, advanced workflow commands (for example `ace-assign`, `ace-overseer`, and review/test orchestration commands) require adding full-stack packages later.

### 2. Install gems

```bash
bundle install
```

### 3. Sync CLI provider config (`ace-config` is provided by `ace-support-config`)

```bash
bundle exec ace-config sync ace-llm-providers-cli
```

If you also want ACE to generate starter `AGENTS.md`, `CLAUDE.md`, and `docs/tools.md` guidance in the repository
root, sync the `ace-support-core` project-root templates as a separate step:

```bash
bundle exec ace-config sync ace-support-core
```

### 4. Sync agent assets

```bash
bundle exec ace-handbook sync
```

Use `bundle exec` for the repo-local quick-start path so copied commands resolve to the ACE gems installed in this
project, not an older or differently configured global install. Advanced environments that intentionally use binstubs,
shell wrappers, or globally installed ACE executables can still run bare `ace-*` commands by choice.

Most ACE tools run from packaged `.ace-defaults`; sync additional package config only when you want project-local
overrides. `bundle exec ace-handbook sync` projects agent skill folders (for example `.claude/skills/` and
`.codex/skills/`).

When you sync `ace-support-core`, ACE creates compact `AGENTS.md` and `CLAUDE.md` starter files plus `docs/tools.md`
for longer day-to-day guidance. The root files hold must-read agent rules, while
[`docs/tools.md#agent-engineering-practices`](docs/tools.md#agent-engineering-practices) holds expanded practices for
workspace safety, debugging, push safety, daemon reuse, UI review, and agent-facing CLI output. Use
`bundle exec ace-config sync ace-support-core --force` to refresh generated starter content and
`bundle exec ace-handbook sync` when you want to refresh projected skill folders.

### 5. Verify setup, provider discovery, and project context

```bash
bundle exec ace-llm --list-providers
bundle exec ace-config doctor
bundle exec ace-bundle project
```

Run these checks in order:

- `bundle exec ace-llm --list-providers` is the discovery command. It shows which providers are available and prints
  setup hints, but it does not prove a configured role can execute end-to-end.
- `bundle exec ace-config doctor` is the setup readiness command. It validates the quick-start path, including local
  setup artifacts, provider package availability, config hygiene, and provider execution readiness. Use
  `bundle exec ace-config doctor --no-probe` when you want the readiness check without live provider pings.
- `bundle exec ace-bundle project` confirms context loading after setup is ready.

If CLI providers appear unavailable in `--list-providers`, confirm `ace-llm-providers-cli` is included in your install
list. Missing credentials or local CLI account access are setup readiness issues that `ace-config doctor` reports as
actionable guidance. API-only setups can still pass readiness even when unrelated CLI providers are inactive.

If `bundle install` fails immediately after a large ACE release, rerun with:

```bash
bundle install --full-index
```

Use `--full-index` only as temporary RubyGems propagation mitigation, then return to normal `bundle install`.

## Principles

- **CLI-first, agent-agnostic** — every tool is a standard CLI command; if it can run bash, it can use ACE
- **Everything in git** — tasks, workflows, configs, and review sessions are markdown and YAML files in your repo
- **Transparent and inspectable** — dry-run support, readable configs, saved sessions; when something breaks, you can trace it
- **Customizable cascade** — each package ships defaults; override at user (`~/.ace/`) or project (`.ace/`) level without forking

## The Toolkit

- **Plan**: [`ace-idea`](ace-idea/) to capture and shape ideas, [`ace-task`](ace-task/) for markdown task specs with subtasks, [`ace-sim`](ace-sim/) for scenario simulation.
- **Build**: [`ace-overseer`](ace-overseer/) to orchestrate task pipelines, [`ace-assign`](ace-assign/) for multi-step assignments, [`ace-git-worktree`](ace-git-worktree/) for isolated worktrees.
- **QA**: [`ace-review`](ace-review/) for multi-model preset reviews, [`ace-test-runner`](ace-test-runner/) for smart test execution, [`ace-lint`](ace-lint/) for linting, [`ace-retro`](ace-retro/) for retrospectives, [`ace-demo`](ace-demo/) for terminal demo recording.
- **Git**: [`ace-git-commit`](ace-git-commit/) for intention-aware commits, [`ace-git-secrets`](ace-git-secrets/) for credential leak scanning and revocation.
- **Context**: [`ace-bundle`](ace-bundle/) for context assembly, [`ace-handbook`](ace-handbook/) for workflows, guides, templates, and skills, [`ace-search`](ace-search/) for codebase search, [`ace-docs`](ace-docs/) for doc freshness tracking.

40+ packages total, including shared libraries and [agent platform integrations](ace-handbook-integration-claude/). See [Tools Reference](docs/tools.md) for the complete inventory.

## Agent Platform Support

ACE skills project natively to multiple agent platforms. Install an integration package and workflows, guides, and skills appear in your agent's expected directory structure.

- [Claude Code](ace-handbook-integration-claude/)
- [Codex CLI](ace-handbook-integration-codex/)
- [Gemini CLI](ace-handbook-integration-gemini/)
- [OpenCode](ace-handbook-integration-opencode/)
- [pi-agent](ace-handbook-integration-pi/)

---

[Quick Start](docs/quick-start.md) | [Vision](docs/vision.md) | [Architecture](docs/architecture.md) | [Tools Reference](docs/tools.md)
