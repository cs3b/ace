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

Coding agents can write code, but they operate in a vacuum. They can't manage tasks, load project context, run structured reviews, or follow multi-step pipelines — you end up doing all of that manually:

- Your tasks live in a SaaS dashboard your agent can't see
- Context is scattered across files the agent doesn't know to load
- Review feedback is verbal and untracked — nothing saved, nothing actionable
- Multi-step workflows require you to babysit every transition

ACE gives agent harnesses like Claude Code and Codex CLI the workflow layer they're missing — task pipelines, context bundles, review presets, and skills — as standard CLI commands both you and your agents run the same way.

## What ACE Does

**Tasks and ideas as files your agent can read** — capture ideas, draft them into task specs with subtask trees, and track progress — all as markdown files in your repo that any agent can read and act on.

```bash
ace-idea create "Add retry logic to webhook delivery" --tags reliability
ace-task create "Implement webhook retry" --priority high
```

[`ace-task`](ace-task/) | [`ace-idea`](ace-idea/)

**One command from task to shipped PR** — provision an isolated worktree, open a tmux window, and kick off a multi-step assignment that walks through implement, test, review, and ship. A retrospective is generated when done.

```bash
ace-overseer work-on --task 8r3
```

[`ace-overseer`](ace-overseer/) orchestrates [`ace-assign`](ace-assign/), [`ace-git-worktree`](ace-git-worktree/), and [`ace-tmux`](ace-tmux/)

**Multi-model code review with tracked feedback** — run the same diff through multiple LLM providers, compare their analysis, and track suggestions through a verified/pending/resolved lifecycle. Presets control what each review focuses on — correctness, security, or polish.

```bash
ace-review --preset code-deep --pr 123
```

[`ace-review`](ace-review/)

**Context loading on demand** — pull project context, workflow instructions, and guides through a protocol system (`wfi://`, `guide://`, `tmpl://`). Bundle them for agents or load them yourself.

```bash
ace-bundle wfi://task/work
```

[`ace-bundle`](ace-bundle/) | [`ace-handbook`](ace-handbook/) | [`ace-search`](ace-search/)

## Quick Start

Start fast with a quick win:

```bash
gem install ace-git-commit
ace-git-commit -i "fix auth token refresh"
```

For the full idea → task → assignment → verify → ship flow, read the [Quick Start guide](docs/quick-start.md).

## Install

```bash
gem install ace-git-commit    # smart commits, zero config
gem install ace-overseer      # full orchestrator stack
```

Ruby 3.2+ required. Each ace-* gem installs independently — start with one tool and add more as you need them. See the [Quick Start](docs/quick-start.md) for a complete walkthrough.

## Principles

- **CLI-first, agent-agnostic** — every tool is a standard CLI command; if it can run bash, it can use ACE
- **Everything in git** — tasks, workflows, configs, and review sessions are markdown and YAML files in your repo
- **Transparent and inspectable** — dry-run support, readable configs, saved sessions; when something breaks, you can trace it
- **Customizable cascade** — each package ships defaults; override at user (`~/.ace/`) or project (`.ace/`) level without forking

## The Toolkit

**Plan** — [`ace-idea`](ace-idea/) capture and shape ideas | [`ace-task`](ace-task/) markdown task specs with subtasks | [`ace-retro`](ace-retro/) retrospectives

**Build** — [`ace-overseer`](ace-overseer/) orchestrate full task pipelines | [`ace-assign`](ace-assign/) multi-step assignments | [`ace-git-worktree`](ace-git-worktree/) isolated worktrees | [`ace-git-commit`](ace-git-commit/) intention-aware commits

**Review** — [`ace-review`](ace-review/) multi-model preset reviews | [`ace-test-runner`](ace-test-runner/) smart test execution | [`ace-lint`](ace-lint/) linting | [`ace-docs`](ace-docs/) doc freshness tracking

**Context** — [`ace-bundle`](ace-bundle/) context assembly | [`ace-handbook`](ace-handbook/) workflows, guides, templates, skills | [`ace-search`](ace-search/) codebase search | [`ace-llm`](ace-llm/) multi-provider LLM queries

**Secure** — [`ace-git-secrets`](ace-git-secrets/) credential leak scanning and revocation

40+ packages total, including shared libraries and [agent platform integrations](ace-handbook-integration-claude/). See [Tools Reference](docs/tools.md) for the complete inventory.

## Agent Platform Support

ACE skills project natively to multiple agent platforms. Install an integration package and workflows, guides, and skills appear in your agent's expected directory structure:

[Claude Code](ace-handbook-integration-claude/) | [Codex CLI](ace-handbook-integration-codex/) | [Gemini CLI](ace-handbook-integration-gemini/) | [OpenCode](ace-handbook-integration-opencode/) | [pi-agent](ace-handbook-integration-pi/)

---

[Quick Start](docs/quick-start.md) | [Vision](docs/vision.md) | [Architecture](docs/architecture.md) | [Tools Reference](docs/tools.md)
