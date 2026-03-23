<div align="center">
  <h1> ACE - Support Core </h1>

  Core infrastructure primitives shared by ACE support gems.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-support-core"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-core.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Configuration overview](docs/config.md)
`ace-support-core` centralizes configuration loading, environment handling, and shared runtime behavior used by support libraries. It delegates config resolution through [ace-support-config](../ace-support-config) and exposes stable orchestration points that other `ace-support-*` gems build on.

## Use Cases

**Create consistent package startup behavior** - initialize config, env, and shared context once with core primitives, so gems like [ace-support-cli](../ace-support-cli) and [ace-support-fs](../ace-support-fs) share a single bootstrap path.

**Avoid duplicate configuration logic** - reuse one configuration and environment model across many gems instead of re-implementing loading and resolution in each package.

**Keep support libraries composable** - build package-specific features on top of stable core contracts that provide predictable runtime behavior.

---
[Configuration overview](docs/config.md) | Part of [ACE](https://github.com/cs3b/ace)
