<div align="center">
  <h1> ACE - Handbook Integration Codex </h1>

  Codex CLI provider integration for ACE handbook skills and workflows.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-handbook-integration-codex"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook-integration-codex.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[ace-handbook](../ace-handbook)
`ace-handbook-integration-codex` maps canonical ACE handbook skills into Codex-compatible projection assets so that skill invocations from Codex CLI resolve correctly while keeping semantics unchanged from the definitions in [ace-handbook](../ace-handbook).

## Use Cases

**Run handbook workflows in Codex contexts** - keep the same behavior while using Codex-native execution entrypoints, so agents running under Codex CLI get the same skill intent as any other provider.

**Avoid duplication across providers** - update canonical skill definitions once in [ace-handbook](../ace-handbook) and generate Codex-specific projections automatically from shared contracts.

**Keep integration delivery minimal** - maintain a focused provider shim layer with only the manifests and projection assets needed for Codex compatibility.

---

Part of [ACE](https://github.com/cs3b/ace)
