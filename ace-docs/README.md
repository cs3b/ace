<h1 align="center">ace-docs</h1>

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-docs"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-docs.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

  Keep documentation current by tracking freshness, detecting drift, and generating actionable updates.
</p>

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

![ace-docs demo](docs/demo/ace-docs-getting-started.gif)

`ace-docs` provides a practical maintenance loop for teams that need package docs to stay aligned with fast-moving code and workflow changes. It uses frontmatter-based freshness tracking, targeted change analysis, and LLM-assisted update guidance to keep documentation in sync.

## How It Works

1. Discover and scan markdown documentation across package roots, tracking freshness through frontmatter metadata.
2. Analyze per-document changes since last update to identify stale files and prioritize update targets.
3. Generate targeted update guidance or validate cross-document consistency before release.

## Use Cases

**Prioritize documentation updates based on real drift** - identify which files are stale, what changed since last update, and where to focus first using [`ace-docs`](docs/usage.md) freshness tracking.

**Generate targeted update guidance for specific documents** - run LLM-assisted analysis with [ace-bundle](../ace-bundle) and [ace-llm](../ace-llm) context to propose concrete doc revisions.

**Catch cross-document inconsistencies before release** - validate metadata and compare documents to find conflicts across package documentation sets before publishing.

**Enforce docs quality in release loops** - pair with [ace-lint](../ace-lint) for markdown checks and use `ace-docs` update workflows to keep guides, READMEs, and references in sync.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
