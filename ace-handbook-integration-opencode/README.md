# ace-handbook-integration-opencode

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-handbook-integration-opencode.svg)](https://rubygems.org/gems/ace-handbook-integration-opencode)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

> OpenCode provider integration for ACE handbook skills and workflows.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-opencode` provides OpenCode-focused handbook manifests and projection artifacts so that canonical ACE skills invoked from OpenCode resolve to the correct provider entrypoints while preserving shared semantics from [ace-handbook](../ace-handbook).

## Use Cases

**Run ACE workflows from OpenCode integrations** - keep canonical skill intent while targeting OpenCode entrypoints, so agents running under OpenCode get the same behavior as any other provider.

**Adapt quickly to provider-specific layouts** - update projection assets inside this package instead of rewriting handbook logic, keeping changes isolated from [ace-handbook](../ace-handbook) canonical definitions.

**Keep provider layers small** - isolate integration glue from core handbook behavior with a focused set of manifests and projection assets.

## Documentation

See [ace-handbook](../ace-handbook) for canonical skill definitions and provider integration patterns.

---

Part of [ACE](../README.md) (Agentic Coding Environment)
