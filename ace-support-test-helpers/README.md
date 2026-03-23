---
doc-type: package-readme
title: ace-support-test-helpers
purpose: Shared test utilities for ACE and support package suites
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-support-test-helpers

> Shared test harness and environment helpers for ACE packages.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-test-helpers` provides reusable helpers for temporary environment setup, assertions, and integration-friendly test scaffolding.

## How It Works

1. Provide base test case abstractions and common helper modules.
2. Manage temporary directories, config fixtures, and environment overrides.
3. Keep tests isolated and reproducible across ACE package boundaries.

## Use Cases

**Write consistent package tests** - share setup patterns and assertions across `ace-support-*`.

**Build integration test flows** - isolate environment variables and filesystem state with reliable helpers.

**Improve CI stability** - reduce flaky test behavior with shared deterministic helpers.

## What It Provides

- Temporary directory and fixture utilities.
- Configuration and environment helper modules.
- Shared base test patterns for support packages.

## Part of ACE

`ace-support-test-helpers` is part of [ACE](../README.md) (Agentic Coding Environment).

## License

MIT
