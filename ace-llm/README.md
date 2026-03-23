<div align="center">
  <h1> ACE - LLM </h1>

  Query any LLM from the terminal with one interface across API and CLI providers.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-llm"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-llm.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-llm demo](docs/demo/ace-llm-getting-started.gif)

`ace-llm` gives developers and coding agents one command surface for querying any LLM provider. Address models by alias (`gflash`, `sonnet`), explicit `provider:model` notation, or with thinking levels (`codex:gpt-5:high`) and execution presets (`cc@ro`). Pass prompts and system instructions inline or as file paths. Fallback routing and retry behavior keep prompt workflows resilient.

## How It Works

1. Select a model — by alias, `provider:model`, with a thinking level suffix (`:low`/`:medium`/`:high`), or an `@preset` — and submit a prompt.
2. The provider router resolves the target through [ace-llm-providers-cli](../ace-llm-providers-cli) adapters, applying fallback and retry rules from the [config cascade](../ace-support-config).
3. The response is returned as text, markdown, or JSON with optional token usage metadata.

## Use Cases

**Switch providers with aliases** - use short names like `gflash`, `sonnet`, `opus` instead of full `provider:model` notation. Aliases resolve through versioned YAML in [`.ace-defaults/`](docs/usage.md).

**Control reasoning depth** - append a thinking level (`codex:gpt-5:high`, `claude:sonnet:low`) to tune reasoning budgets. Supported CLI providers: `claude`, `codex` (levels: `low`, `medium`, `high`, `xhigh`).

**Run preset-driven prompts** - apply execution profiles with `@preset` or `--preset`. Built-in presets for CLI providers: `@ro` (read-only), `@rw` (read-write), `@yolo` (full autonomy). Supported by: `claude`, `codex`, `gemini`, `opencode`, `pi`.

**Build resilient prompt workflows** - configure fallback chains and retry behavior through the [config cascade](.ace-defaults/llm/config.yml) so transient provider issues do not block work.

**Power LLM-enhanced flows in sibling packages** - serve as the execution backend for [ace-git-commit](../ace-git-commit), [ace-idea](../ace-idea), [ace-review](../ace-review), [ace-sim](../ace-sim), [ace-prompt-prep](../ace-prompt-prep), and more.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
