<div align="center">
  <h1> ACE - Support Mac Clipboard </h1>

  macOS clipboard support for text, files, and image payloads used by ACE tools.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-support-mac-clipboard"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-mac-clipboard.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

**macOS only.** `ace-support-mac-clipboard` integrates with macOS `NSPasteboard` so ACE tools can consume richer clipboard inputs than plain text. It handles screenshots, Finder file selections, and formatted content, presenting normalized Ruby structures to downstream packages.

## Use Cases

**Attach image and context content from clipboard** - support screenshot-based and file-based workflows in ACE tools like [ace-prompt-prep](../ace-prompt-prep) without manual file handling.

**Handle Finder selections and formatted text** - process files and rich content from macOS pasteboard without manual conversion steps.

**Keep platform details isolated** - encapsulate macOS-specific clipboard behavior in one package so the rest of ACE stays platform-neutral.

---

Part of [ACE](https://github.com/cs3b/ace)
