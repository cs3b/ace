<div align="center">
  <h1> ACE - Search </h1>

  Unified codebase search -- one command that auto-detects files or content.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-search"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-search.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-search demo](docs/demo/ace-search-getting-started.gif)

`ace-search` gives developers and coding agents a single search entry point that chooses file or content mode automatically (DWIM — Do What I Mean), keeps search scope predictable from any directory, and exposes fast output modes for workflow automation. Use `/as-search-run` for quick searches, `/as-search-research` for multi-search analysis, or `/as-search-feature-research` for implementation gap analysis.

## How It Works

1. Submit a query to [`ace-search`](docs/usage.md) and DWIM detection picks content search (ripgrep) or file search (fd) based on the pattern.
2. Scope filters like `--staged`, `--tracked`, or `--changed` constrain results to Git-relevant files via [ace-git](../ace-git).
3. Results are returned in your chosen format (text, JSON, YAML, count, or files-with-matches) for human review or downstream automation.

## Use Cases

**Find code patterns without deciding tooling first** - run `ace-search "TODO"` or `ace-search "*.rb"` and let DWIM detection pick the right backend automatically.

**Constrain investigations to meaningful working sets** - combine `--staged`, `--tracked`, or `--changed` to inspect only [ace-git](../ace-git)-relevant files during reviews and refactors.

**Feed downstream tooling and automation** - use `--json`, `--yaml`, `--count`, or `--files-with-matches` for machine-readable pipelines and scripted checks.

**Standardize repeat searches across teams** - apply named presets with `--preset` via [ace-support-config](../ace-support-config) for consistent daily scans and focused research queries.

**Run multi-search research from an agent** - use `/as-search-research` to execute multiple related searches and synthesize findings, or `/as-search-feature-research` to analyze implementation gaps.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
