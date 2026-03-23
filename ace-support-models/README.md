<div align="center">
  <h1> ACE - Support Models </h1>

  Shared model metadata and pricing helpers for ACE provider tooling.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-support-models"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-models.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-models` normalizes provider and model metadata into a single canonical source so ACE tools that reason about LLM capabilities, pricing, and compatibility do not duplicate catalogs or drift out of sync.

## Use Cases

**Resolve model metadata consistently** - avoid duplicated model catalogs across ACE features by querying one shared registry used by [ace-llm](../ace-llm) and [ace-review](../ace-review).

**Calculate usage expectations** - support stable cost and compatibility assumptions during tool workflows with shared pricing and capability primitives.

**Share validation rules** - apply one metadata model for provider and model checks so that [ace-llm-providers-cli](../ace-llm-providers-cli) and other provider-aware packages stay aligned.

---

Part of [ACE](https://github.com/cs3b/ace)
