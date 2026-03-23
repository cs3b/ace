# ace-support-mac-clipboard

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

<p align="center">
[![Gem Version](https://img.shields.io/gem/v/ace-support-mac-clipboard.svg)](https://rubygems.org/gems/ace-support-mac-clipboard)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
</p>

> macOS clipboard support for text, files, and image payloads used by ACE tools.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-mac-clipboard` integrates with macOS `NSPasteboard` so ACE tools can consume richer clipboard inputs than plain text. It handles screenshots, Finder file selections, and formatted content, presenting normalized Ruby structures to downstream packages.

## Use Cases

**Attach image and context content from clipboard** - support screenshot-based and file-based workflows in ACE tools like [ace-prompt-prep](../ace-prompt-prep) without manual file handling.

**Handle Finder selections and formatted text** - process files and rich content from macOS pasteboard without manual conversion steps.

**Keep platform details isolated** - encapsulate macOS-specific clipboard behavior in one package so the rest of ACE stays platform-neutral.

## Documentation

API reference in source: `lib/ace/support/mac_clipboard`

---

Part of [ACE](../README.md) (Agentic Coding Environment)
