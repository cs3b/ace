# ace-support-cli

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-support-cli.svg)](https://rubygems.org/gems/ace-support-cli)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Shared command primitives for consistent ACE CLI behavior.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-cli` is the foundation layer for ACE commands, providing metadata-driven command definitions, parser behavior, and execution orchestration. Packages like [ace-llm](../ace-llm), [ace-review](../ace-review), and [ace-search](../ace-search) build their CLI surfaces on top of these shared primitives.

## How It Works

1. Package commands extend shared `Command` base classes and define arguments/options declaratively.
2. Parsers normalize argv into structured Ruby types and route to a command registry.
3. Runners execute command objects with consistent help, error, and exit semantics.

## Use Cases

**Build a new ACE CLI tool quickly** - reuse shared conventions for command declaration, option parsing, and execution so new packages like [ace-retro](../ace-retro) or [ace-sim](../ace-sim) get consistent behavior from day one.

**Standardize command behavior across packages** - enforce predictable option parsing, help text, and exit codes for both human and agent callers.

**Keep agent invocations safe** - preserve a stable CLI contract so coding agents can call `ace-*` tools reliably in mixed human/agent workflows.

## Documentation

API reference in source: `lib/ace/support/cli`

---

Part of [ACE](../README.md) (Agentic Coding Environment)
