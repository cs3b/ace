# ace-support-fs

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-support-fs.svg)](https://rubygems.org/gems/ace-support-fs)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

> File system primitives for ACE path resolution and project root discovery.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-fs` provides reusable filesystem helpers for path expansion, root detection, and directory traversal. It handles the platform and context differences so packages like [ace-support-config](../ace-support-config) and [ace-search](../ace-search) can resolve paths safely from any working directory.

## Use Cases

**Resolve paths safely across subdirectories** - use consistent path expansion for tools that move across project subdirectories, including protocol-aware path handling.

**Detect workspace boundaries** - infer project root from marker files without shell-specific assumptions, so [ace-search](../ace-search) and [ace-support-config](../ace-support-config) scope correctly.

**Build config scans** - discover and rank candidate configuration directories during resolution, supporting the cascade logic in [ace-support-config](../ace-support-config).

## Documentation

API reference in source: `lib/ace/support/fs`

---

Part of [ACE](../README.md) (Agentic Coding Environment)
