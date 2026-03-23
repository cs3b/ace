<div align="center">
  <h1> ACE - LLM </h1>

  Query any LLM from the terminal with one interface across API and CLI providers.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-llm"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-llm.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-llm demo](docs/demo/ace-llm-getting-started.gif)

`ace-llm` gives developers and coding agents one command surface for multi-provider prompting, alias-based model selection, fallback routing, and structured output handling. Switch between providers without changing calling conventions, and keep prompt workflows resilient with automatic retry and fallback behavior.

## How It Works

1. Select a model using aliases or explicit provider:model notation and submit a prompt via [`ace-llm`](docs/usage.md).
2. The provider router resolves the target through [ace-llm-providers-cli](../ace-llm-providers-cli) adapters, applying fallback and retry rules from [ace-support-config](../ace-support-config) cascade.
3. The response is returned in your chosen format (text, markdown, or JSON) with optional cost and token usage metadata.

## Use Cases

**Run the same prompt across different providers** - switch models quickly with aliases while keeping one command shape and consistent output controls, powered by [ace-llm-providers-cli](../ace-llm-providers-cli) adapters.

**Build resilient prompt workflows** - configure fallback and retry behavior through [ace-support-config](../ace-support-config) so transient provider issues do not block interactive development or automation.

**Capture responses for downstream tooling** - emit plain text, markdown, or JSON outputs for handoff into docs, reviews via [ace-review](../ace-review), and scripted workflows.

**Execute preset-driven prompts** - apply named execution profiles with `@preset` or `--preset` for repeatable, team-shared prompt configurations.

**Power LLM-enhanced flows in sibling packages** - serve as the execution backend for prompt enhancement in [ace-prompt-prep](../ace-prompt-prep), simulation chains in [ace-sim](../ace-sim), and multi-model review in [ace-review](../ace-review).

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
