# ace-bundle

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-bundle.svg)](https://rubygems.org/gems/ace-bundle)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Assemble project context for agents and developers in one command.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Configuration Reference](docs/configuration.md) | [Handbook Reference](docs/handbook.md)

![ace-bundle demo](docs/demo/ace-bundle-getting-started.gif)

`ace-bundle` helps developers and coding agents load consistent, reusable project context from presets, files, and protocol URLs while staying inside terminal-native workflows.

## Use Cases

**Load baseline project context before coding sessions** - run `ace-bundle project` to gather architecture docs, conventions, and current repository state.

**Pull workflow instructions and guides by protocol URL** - run `ace-bundle wfi://assign/drive` (or `guide://...`, `tmpl://...`, `prompt://...`) to retrieve canonical handbook resources resolved by [ace-support-nav](../ace-support-nav).

**Compose team and task context without manual copy/paste** - combine presets and explicit files in one call to produce targeted context bundles for reviews, implementation, or debugging with [ace-git](../ace-git) metadata when needed.

**Handle large context safely in agent loops** - rely on inline-or-cache output behavior and optional compression through [ace-compressor](../ace-compressor) to keep payloads manageable for LLM workflows.

## Features

- Preset composition for reusable context packs (project, code-review, security-review, team) with intelligent merging.
- Protocol loading from `wfi://`, `guide://`, `prompt://`, and `tmpl://`.
- Smart caching with auto-format threshold and artifacts in `.ace-local/bundle/`.
- Mixed input support (preset names, file paths, and protocol URLs) in one invocation.
- Section-based output for structured, tool-processable context.
- Optional exact or agent-mode compression through ace-compressor integration.
- Built-in presets for base onboarding, development, reviews, and team flows.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Configuration Reference](docs/configuration.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-bundle --help`

## Part of ACE

`ace-bundle` is part of [ACE](../README.md) (Agentic Coding Environment).
