# ace-support-items

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-support-items.svg)](https://rubygems.org/gems/ace-support-items)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Shared primitives for scanning, resolving, and sanitizing ACE item stores.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-items` standardizes directory scanning, shortcut resolution, and slug handling for ACE item workflows. It provides the low-level store operations that packages like [ace-task](../ace-task) and [ace-retro](../ace-retro) build their item management on.

## Use Cases

**Parse and resolve ACE task/idea shortcuts** - map compact IDs to canonical b36ts item paths, powering the shorthand lookups in [ace-task](../ace-task).

**Handle special item directories consistently** - support shared folder conventions across tools so scanners in [ace-retro](../ace-retro) and [ace-task](../ace-task) discover items the same way.

**Normalize metadata safely** - sanitize slugs and arguments before persistence, preventing malformed entries in item stores.

## Documentation

API reference in source: `lib/ace/support/items`

---

Part of [ACE](../README.md) (Agentic Coding Environment)
