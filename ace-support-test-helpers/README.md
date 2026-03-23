# ace-support-test-helpers

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-support-test-helpers.svg)](https://rubygems.org/gems/ace-support-test-helpers)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

> Shared test harness and environment helpers for ACE packages.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-test-helpers` provides reusable helpers for temporary environment setup, assertions, and integration-friendly test scaffolding so that ACE packages share consistent test patterns without duplicating boilerplate.

## Use Cases

**Write consistent package tests** - share base test case abstractions, setup patterns, and assertions across `ace-support-*` and other ACE packages via common helper modules.

**Build integration test flows** - isolate environment variables, filesystem state, and config fixtures with reliable temporary-directory and override helpers used alongside [ace-test-runner](../ace-test-runner).

**Improve CI stability** - reduce flaky test behavior with shared deterministic helpers for directory management, configuration, and environment cleanup.

## Documentation

API usage is documented inline; see tests and source for integration examples.

---

Part of [ACE](../README.md) (Agentic Coding Environment)
