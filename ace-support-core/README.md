<div align="center">
  <h1> ACE - Support Core </h1>

  Core infrastructure primitives shared by ACE support gems.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-support-core"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-core.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-core` centralizes configuration loading, environment handling, and shared runtime behavior used by support libraries. It delegates config resolution through [ace-support-config](../ace-support-config) and exposes stable orchestration points that other `ace-support-*` gems build on.

## How It Works

1. Provide a shared bootstrap path for config, env, and runtime context so every `ace-support-*` gem starts from the same foundation.
2. Delegate cascaded configuration resolution through [ace-support-config](../ace-support-config) so packages inherit project, user, and gem-level defaults automatically.
3. Provide shared runtime/config primitives consumed by `ace-support-config`, which owns the `ace-config` CLI.

## Testing

This package uses the batch-2 deterministic testing contract:

- `ace-test ace-support-core` runs the default `fast` loop from `test/fast/`.
- `ace-test ace-support-core feat` runs deterministic feature coverage from `test/feat/`.
- `ace-test ace-support-core all` runs both deterministic layers.

`ace-support-core` does not define package-owned `test/e2e/` scenarios in this migration.

## Use Cases

**Create consistent package startup behavior** - initialize config, env, and shared context once with core primitives, so gems like [ace-support-cli](../ace-support-cli) and [ace-support-fs](../ace-support-fs) share a single bootstrap path.

**Avoid duplicate configuration logic** - reuse one configuration and environment model across many gems instead of re-implementing loading and resolution in each package.

**Keep support libraries composable** - build package-specific features on top of stable core contracts that provide predictable runtime behavior.

---
[Configuration overview](docs/config.md) | [`ace-config` usage](../ace-support-config/docs/usage.md) | Part of [ACE](https://github.com/cs3b/ace)
