<div align="center">
  <h1> ACE - Bundle </h1>

  Assemble project context for agents and developers in one command.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-bundle"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-bundle.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
![ace-bundle demo](docs/demo/ace-bundle-getting-started.gif)

`ace-bundle` helps developers and coding agents load consistent, reusable project context from presets, files, and protocol URLs while staying inside terminal-native workflows. It supports preset composition, protocol loading, smart caching, and optional compression to keep payloads manageable for LLM workflows.

## How It Works

1. Specify inputs as preset names (`project`, `code-review`), file paths, or protocol URLs (`wfi://`, `guide://`, `tmpl://`, `prompt://`).
2. ace-bundle resolves, merges, and assembles the inputs into structured section-based output with intelligent caching.
3. Output is delivered inline or cached to `.ace-local/bundle/`, optionally compressed through [ace-compressor](../ace-compressor) for large payloads.

## Use Cases

**Load baseline project context before coding sessions** - run [`ace-bundle project`](docs/usage.md) to gather architecture docs, conventions, and current repository state into a single context payload.

**Pull workflow instructions and guides by protocol URL** - run `ace-bundle wfi://assign/drive` (or `guide://...`, `tmpl://...`, `prompt://...`) to retrieve canonical handbook resources resolved by [ace-support-nav](../ace-support-nav).

**Compose team and task context without manual copy-paste** - combine presets and explicit files in one call to produce targeted context bundles for reviews, implementation, or debugging with [ace-git](../ace-git) metadata when needed.

**Handle large context safely in agent loops** - rely on inline-or-cache output behavior and optional compression through [ace-compressor](../ace-compressor) to keep payloads manageable for LLM workflows.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of ACE
