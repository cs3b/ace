<div align="center">
  <h1> ACE - Prompt Prep </h1>

  Prepare prompts in a structured workspace with optional LLM enhancement and bundled project context.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-prompt-prep"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-prompt-prep.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
![ace-prompt-prep demo](docs/demo/ace-prompt-prep-getting-started.gif)

`ace-prompt-prep` helps developers and coding agents keep prompt authoring repeatable: initialize templates, archive every revision, enrich prompt context with [ace-bundle](../ace-bundle), and optionally run enhancement through [ace-llm](../ace-llm). Use `/as-prompt-prep` to drive the full workflow from inside a coding agent.

## How It Works

1. Initialize a prompt workspace from templates with `ace-prompt-prep setup`, optionally scoping to a task via `--task` and [ace-task](../ace-task).
2. Process the prompt to inject bundled context from [ace-bundle](../ace-bundle) sources, archive the previous version, and write output.
3. Optionally enhance the prompt through [ace-llm](../ace-llm) with `--enhance` and model selection before handing it to an agent or API.

## Use Cases

**Keep prompt history without manual bookkeeping** - initialize and process prompts in a stable workspace where archives and `_previous.md` are maintained automatically.

**Improve prompt quality before execution** - run `--enhance` with model selection via [ace-llm](../ace-llm) to rewrite prompts for clarity and completeness before handing them to an agent.

**Inject project context directly into prompts** - use `bundle` frontmatter sources so prompts include selected files, presets, and command output from [ace-bundle](../ace-bundle) at processing time.

**Scope prompts to tasks** - use `--task` to route prompt workspaces into [ace-task](../ace-task) directories, keeping prompts connected to delivery work alongside [ace-git](../ace-git) branch workflows.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)

