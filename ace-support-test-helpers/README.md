<div align="center">
  <h1> ACE - Support Test Helpers </h1>

  Shared test harness and environment helpers for ACE packages.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-support-test-helpers"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-test-helpers.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Documentation](#documentation)
`ace-support-test-helpers` provides reusable helpers for temporary environment setup, assertions, and integration-friendly test scaffolding so that ACE packages share consistent test patterns without duplicating boilerplate.

## Use Cases

**Write consistent package tests** - share base test case abstractions, setup patterns, and assertions across `ace-support-*` and other ACE packages via common helper modules.

**Build integration test flows** - isolate environment variables, filesystem state, and config fixtures with reliable temporary-directory and override helpers used alongside [ace-test-runner](../ace-test-runner).

**Improve CI stability** - reduce flaky test behavior with shared deterministic helpers for directory management, configuration, and environment cleanup.

---
[Documentation](#documentation) | Part of ACE
