<div align="center">
  <h1> ACE - Handbook Integration Gemini </h1>

  Gemini CLI provider integration for ACE handbook skills and workflows.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-handbook-integration-gemini"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-handbook-integration-gemini.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

[ace-handbook](../ace-handbook)

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-handbook-integration-gemini` projects canonical ACE handbook skills into Gemini-native manifest assets so that skill invocations from Gemini CLI resolve to the correct provider entrypoints while preserving shared semantics from [ace-handbook](../ace-handbook).

## Use Cases

**Run ACE skill workflows in Gemini-native stacks** - preserve canonical behavior while using Gemini-native projection format, so agents running under Gemini CLI get the same skill intent as any other provider.

**Centralize skill updates** - keep shared definitions in [ace-handbook](../ace-handbook) and avoid provider-specific drift by generating Gemini projections from one canonical source.

**Ship lean provider packs** - support only the provider shims and manifests needed for Gemini compatibility, keeping integration scope minimal.

## Documentation

See [ace-handbook](../ace-handbook) for canonical skill definitions and provider integration patterns.

---

Part of [ACE](../README.md) (Agentic Coding Environment)

