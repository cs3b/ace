# ace-support-core

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-support-core.svg)](https://rubygems.org/gems/ace-support-core)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

> Core infrastructure primitives shared by ACE support gems.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-core` centralizes configuration loading, environment handling, and shared runtime behavior used by support libraries. It delegates config resolution through [ace-support-config](../ace-support-config) and exposes stable orchestration points that other `ace-support-*` gems build on.

## Use Cases

**Create consistent package startup behavior** - initialize config, env, and shared context once with core primitives, so gems like [ace-support-cli](../ace-support-cli) and [ace-support-fs](../ace-support-fs) share a single bootstrap path.

**Avoid duplicate configuration logic** - reuse one configuration and environment model across many gems instead of re-implementing loading and resolution in each package.

**Keep support libraries composable** - build package-specific features on top of stable core contracts that provide predictable runtime behavior.

## Documentation

[Configuration overview](docs/config.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
