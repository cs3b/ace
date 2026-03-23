<div align="center">
  <h1> ACE - LLM Providers CLI </h1>

  CLI-backed provider adapters that extend ace-llm with local tool execution.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-llm-providers-cli"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-llm-providers-cli.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[ace-llm Usage Guide](../ace-llm/docs/usage.md) | [ace-llm Handbook](../ace-llm/docs/handbook.md)
`ace-llm-providers-cli` extends [ace-llm](../ace-llm) with provider clients that execute through installed CLI tools (Claude, Codex, OpenCode, Gemini, pi, Codex OSS) while preserving the shared command interface. Provider defaults live in versioned YAML, and a health-check command verifies local readiness.

## How It Works

1. The gem registers CLI provider clients on require, making them available to [ace-llm](../ace-llm) automatically.
2. Provider defaults are read from `.ace-defaults/llm/providers/*.yml` and can be overridden through the [ace-support-config](../ace-support-config) cascade.
3. When [ace-llm](../ace-llm) routes a model call, the matching CLI adapter executes a subprocess command and returns a normalized response.

## Use Cases

**Use CLI-native providers through one surface** - run prompts against Claude, Codex, OpenCode, Gemini, pi, and Codex OSS via [ace-llm](../ace-llm) without changing calling conventions.

**Keep provider configuration in versioned YAML** - tune model behavior and provider settings through [ace-support-config](../ace-support-config) instead of custom glue code.

**Diagnose local provider readiness** - run `ace-llm-providers-cli-check` to verify that CLI tools are installed, authenticated, and reachable before starting work.

---

Part of [ACE](https://github.com/cs3b/ace)
