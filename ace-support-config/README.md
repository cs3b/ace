# ace-support-config

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-support-config.svg)](https://rubygems.org/gems/ace-support-config)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Shared configuration cascade primitives for ACE libraries and tools.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-config` provides layered configuration loading and merging for ACE, resolving values from `.ace` project files, user home defaults, and gem-bundled defaults with deterministic precedence. Used by [ace-llm](../ace-llm), [ace-search](../ace-search), [ace-review](../ace-review), and most other ACE packages.

## How It Works

1. A resolver builds a configuration cascade from the nearest `.ace` directory up to user-home and gem-default layers.
2. Resolved values are merged using configurable merge strategies with deterministic precedence.
3. Consumers access resolved config by namespace, file path, or direct lookup.

## Use Cases

**Load layered configuration safely** - combine project, user, and default values with deterministic precedence for any ACE package.

**Support project-specific overrides** - place `.ace` files near the execution context to customize behavior while keeping defaults stable across tools like [ace-llm](../ace-llm) and [ace-review](../ace-review).

**Resolve namespaces consistently** - access configuration across tools using shared resolver methods, so [ace-llm-providers-cli](../ace-llm-providers-cli) and [ace-search](../ace-search) get the same cascade behavior.

## Documentation

[Usage Guide](docs/usage.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
