<div align="center">
  <h1> ACE - Support FS </h1>

  File system primitives for ACE path resolution and project root discovery.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-support-fs"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-fs.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-fs` provides reusable filesystem helpers for path expansion, root detection, and directory traversal. It handles the platform and context differences so packages like [ace-support-config](../ace-support-config) and [ace-search](../ace-search) can resolve paths safely from any working directory.

## Use Cases

**Resolve paths safely across subdirectories** - use consistent path expansion for tools that move across project subdirectories, including protocol-aware path handling.

**Detect workspace boundaries** - infer project root from marker files without shell-specific assumptions, so [ace-search](../ace-search) and [ace-support-config](../ace-support-config) scope correctly.

**Build config scans** - discover and rank candidate configuration directories during resolution, supporting the cascade logic in [ace-support-config](../ace-support-config).

---

Part of [ACE](https://github.com/cs3b/ace)
