<h1 align="center">ACE - Agentic Coding Environment</h1>

<p align="center">
  <img src="docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

  CLI tools designed for developers, ready for agents.
</p>

[Vision](docs/vision.md) | [Architecture](docs/architecture.md) | [Quick Start Tutorial](docs/quick-start.md)
> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

Developers and AI agents now work side by side, but most tooling was built for one or the other. GUI dashboards lock out agents, verbose APIs overwhelm humans, and scattered tools force both to context-switch. ACE is a set of CLI tools that both developers and agents use the same way - same commands, same config, same file-based output. It gives coding agent harnesses like Claude Code and Codex CLI the workflow infrastructure they need - task pipelines, context bundles, review presets, and skills - without coupling to any single agent platform.

## Values

- **CLI-first, agent-agnostic** - every tool is a standard CLI command that any agent can run - if it can run bash, it can use ACE
- **Everything lives in git** - tasks, workflows, guides, templates, skills, and configuration are markdown or YAML files in your repo, not locked in a SaaS dashboard
- **Agent-friendly output** - commands produce concise, progressive output with file paths for details - agents read only what they need instead of parsing walls of text
- **Transparent and inspectable** - dry-run support, readable YAML configs, review sessions saved as files
- **Customizable at every level** - each package ships with defaults; override configuration, prompts, workflows, or skills at user (`~/.ace/`) or project (`.ace/`) level without forking
- **Provider freedom** - swap LLM providers or CLI agents without changing your workflow

## What ACE Does

**Plan and track work** - capture ideas, draft them into task specs, break them into subtask trees, generate implementation plans, and track progress - all as markdown files in your repo. [`ace-idea`](ace-idea/) and [`ace-task`](ace-task/)

**Run a full task pipeline** - one command provisions an isolated worktree, opens a tmux window, and starts a multi-step assignment that walks through implement, test, release, review, and ship. Generates a retrospective when done. [`ace-overseer`](ace-overseer/) orchestrates [`ace-git-worktree`](ace-git-worktree/), [`ace-tmux`](ace-tmux/), [`ace-assign`](ace-assign/), and [`ace-retro`](ace-retro/).

**Review code across models** - run the same diff through multiple LLM providers, compare their feedback, and apply the best suggestions. Configurable presets control what each review cycle focuses on - correctness, quality, or polish. [`ace-review`](ace-review/)

**Generate commits from changes** - stage your work and get a structured commit message derived from the actual diff, scoped per package. [`ace-git-commit`](ace-git-commit/)

**Load context on demand** - pull project context, workflow instructions, and guides through a protocol system (`wfi://`, `guide://`, `tmpl://`). Discover available resources, resolve them to files, and bundle them for agents or developers. [`ace-bundle`](ace-bundle/), [`ace-nav`](ace-support-nav/), and [`ace-search`](ace-search/)

**Test consistently** - run tests across the monorepo with a single command that handles dependency resolution, profiling, and reporting. [`ace-test`](ace-test/) and [`ace-test-runner`](ace-test-runner/)

**Maintain documentation** - track document freshness, analyze what needs updating after code changes, and lint markdown files. [`ace-docs`](ace-docs/) and [`ace-lint`](ace-lint/)

**Organize project knowledge** - a handbook system ships workflows, guides, templates, and skills per package, with agent platform integrations that project skills to Claude Code, Codex, Gemini, and others. [`ace-handbook`](ace-handbook/)

## Tools

**Git and security** - [`ace-git`](ace-git/) branch and PR context | [`ace-git-secrets`](ace-git-secrets/) token leak scanning

**LLM and prompts** - [`ace-llm`](ace-llm/) provider queries | [`ace-prompt-prep`](ace-prompt-prep/) prompt context assembly | [`ace-compressor`](ace-compressor/) context compression

**Simulation and demos** - [`ace-sim`](ace-sim/) scenario simulation | [`ace-demo`](ace-demo/) demo recording

**Internals** - [`ace-b36ts`](ace-b36ts/) compact timestamp IDs
