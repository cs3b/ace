<div align="center">
  <h1> ACE - Handbook </h1>

  Standardized workflows for creating and managing guides, cookbooks, workflow instructions, and agent definitions.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-handbook"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-handbook demo](docs/demo/ace-handbook-getting-started.gif)

`ace-handbook` gives ACE teams a shared way to author, review, and maintain handbook assets with consistent quality gates and repeatable delivery workflows. It covers guides (`.g.md`), cookbooks (`.cookbook.md`), workflow instructions (`.wf.md`), and agent definitions (`.ag.md`).

## How It Works

1. Author handbook assets using standardized templates and structure conventions for guides, workflows, and agents.
2. Review content through quality-gate workflows that check clarity, formatting, and process compliance.
3. Coordinate multi-step documentation changes through orchestration and research workflows.

## Use Cases

**Author handbook assets with consistent structure** - use `/as-handbook-manage-guides`, `/as-handbook-manage-cookbooks`, `/as-handbook-manage-workflows`, and `/as-handbook-manage-agents` to create and update guides, cookbooks, workflow instructions, and agent definitions with package workflows.

**Review handbook content before publishing** - run `/as-handbook-review-guides`, `/as-handbook-review-cookbooks`, and `/as-handbook-review-workflows` to catch clarity, formatting, and process issues before updates propagate to integrations.

**Coordinate larger handbook deliveries** - use `/as-handbook-update-docs` to plan, execute, and synthesize multi-step documentation changes across package handbook assets.

**Integrate with resource discovery and context loading** - pair with [ace-nav](../ace-support-nav) for workflow and resource discovery, [ace-bundle](../ace-bundle) for loading complete workflow instructions, and provider integrations (`ace-handbook-integration-*`) that project canonical handbook skills into provider-native folders.

**Sync and inspect provider integrations** - run `ace-handbook sync` to project canonical skills into provider-native folders and `ace-handbook status` to check integration health across all configured providers.

**Extend handbook content in normal projects** - put project-specific workflows, guides, cookbooks, templates, and skills under `.ace-handbook/` and discover them with protocol URLs (`wfi://`, `guide://`, `cookbook://`, `tmpl://`, `skill://`). See [Usage Guide](docs/usage.md) for path conventions.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
