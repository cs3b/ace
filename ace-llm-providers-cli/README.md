# ace-llm-providers-cli

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-llm-providers-cli.svg)](https://rubygems.org/gems/ace-llm-providers-cli)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

> CLI-backed provider adapters that extend ace-llm with local tool execution.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-llm-providers-cli` extends [ace-llm](../ace-llm) with provider clients that execute through installed CLI tools (Claude, Codex, OpenCode, Gemini, pi, Codex OSS) while preserving the shared command interface. Provider defaults live in versioned YAML, and a health-check command verifies local readiness.

## How It Works

1. The gem registers CLI provider clients on require, making them available to [ace-llm](../ace-llm) automatically.
2. Provider defaults are read from `.ace-defaults/llm/providers/*.yml` and can be overridden through the [ace-support-config](../ace-support-config) cascade.
3. When [ace-llm](../ace-llm) routes a model call, the matching CLI adapter executes a subprocess command and returns a normalized response.

## Use Cases

**Use CLI-native providers through one surface** - run prompts against Claude, Codex, OpenCode, Gemini, pi, and Codex OSS via [ace-llm](../ace-llm) without changing calling conventions.

**Keep provider configuration in versioned YAML** - tune model behavior and provider settings through [ace-support-config](../ace-support-config) instead of custom glue code.

**Diagnose local provider readiness** - run `ace-llm-providers-cli-check` to verify that CLI tools are installed, authenticated, and reachable before starting work.

## Documentation

[ace-llm Usage Guide](../ace-llm/docs/usage.md) | [ace-llm Handbook](../ace-llm/docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
