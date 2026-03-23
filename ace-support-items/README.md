<div align="center">
  <h1> ACE - Support Items </h1>

  Shared primitives for scanning, resolving, and sanitizing ACE item stores.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-support-items"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-items.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Documentation](#documentation)
`ace-support-items` standardizes directory scanning, shortcut resolution, and slug handling for ACE item workflows. It provides the low-level store operations that packages like [ace-task](../ace-task) and [ace-retro](../ace-retro) build their item management on.

## Use Cases

**Parse and resolve ACE task/idea shortcuts** - map compact IDs to canonical b36ts item paths, powering the shorthand lookups in [ace-task](../ace-task).

**Handle special item directories consistently** - support shared folder conventions across tools so scanners in [ace-retro](../ace-retro) and [ace-task](../ace-task) discover items the same way.

**Normalize metadata safely** - sanitize slugs and arguments before persistence, preventing malformed entries in item stores.

---
[Documentation](#documentation) | Part of [ACE](https://github.com/cs3b/ace)
