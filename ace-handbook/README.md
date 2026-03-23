<div align="center">
  <h1> ACE - Handbook </h1>

  Standardized workflows for creating and managing guides, workflow instructions, and agent definitions.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-handbook"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
![ace-handbook demo](docs/demo/ace-handbook-getting-started.gif)

`ace-handbook` gives ACE teams a shared way to author, review, and maintain handbook assets with consistent quality gates and repeatable delivery workflows. It covers guides (`.g.md`), workflow instructions (`.wf.md`), and agent definitions (`.ag.md`).

## How It Works

1. Author handbook assets using standardized templates and structure conventions for guides, workflows, and agents.
2. Review content through quality-gate workflows that check clarity, formatting, and process compliance.
3. Coordinate multi-step documentation changes through orchestration and research workflows.

## Use Cases

**Author handbook assets with consistent structure** - use `/as-handbook-manage-guides`, `/as-handbook-manage-workflows`, and `/as-handbook-manage-agents` to create and update guides, workflow instructions, and agent definitions with package workflows.

**Review handbook content before publishing** - run `/as-handbook-review-guides` and `/as-handbook-review-workflows` to catch clarity, formatting, and process issues before updates propagate to integrations.

**Coordinate larger handbook deliveries** - use `/as-handbook-update-docs` to plan, execute, and synthesize multi-step documentation changes across package handbook assets.

**Integrate with resource discovery and context loading** - pair with [ace-nav](../ace-nav) for workflow and resource discovery, [ace-bundle](../ace-bundle) for loading complete workflow instructions, and provider integrations (`ace-integration-*`) that project canonical handbook skills into provider-native folders.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)

