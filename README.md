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

Use this full-stack path for a new project (Ruby 3.2+):

1. Add the ACE tools you need:

```bash
bundle add --group "development, test" \
  ace-idea ace-task ace-sim \
  ace-overseer ace-assign ace-git-worktree ace-tmux \
  ace-bundle ace-handbook ace-search ace-docs \
  ace-review ace-lint ace-test-runner ace-test-runner-e2e ace-retro ace-demo \
  ace-git-commit ace-git-secrets ace-git \
  ace-handbook-integration-claude ace-handbook-integration-codex
# Also available: ace-handbook-integration-gemini, ace-handbook-integration-opencode, ace-handbook-integration-pi
```

Dependencies like `ace-llm`, `ace-git`, `ace-tmux`, and all `ace-support-*` gems are pulled in automatically.

2. Install gems:

```bash
bundle install
```

3. Initialize project config (`ace-config` is provided by `ace-support-config`):

```bash
ace-config init
```

4. Sync agent assets:

```bash
ace-handbook sync
```

5. Verify provider discovery and project context:

```bash
ace-llm --list-providers
ace-bundle project
```

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
