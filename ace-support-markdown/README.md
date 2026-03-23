<h1 align="center">ace-support-markdown</h1>

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

<a href="https://rubygems.org/gems/ace-support-markdown"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-support-markdown.svg" /></a>
<a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
<a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

  Safe, composable markdown editing tools for ACE libraries and docs.
</p>

[Documentation](#documentation)

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

`ace-support-markdown` provides atomic document editing with frontmatter and section-level updates while preserving document integrity. It is the shared editing layer that packages like [ace-task](../ace-task) and [ace-docs](../ace-docs) depend on for safe, repeatable content mutations.

## Use Cases

**Safely update task and docs content** - use frontmatter and section editing primitives to apply metadata and content changes without risking accidental corruption during automated or agent-driven edits.

**Generate documents programmatically** - build reproducible markdown output with builder-like APIs used by [ace-task](../ace-task) for spec files and [ace-docs](../ace-docs) for generated documentation.

**Preserve history during edits** - maintain backup and rollback safety for write-heavy operations so that tools like [`ace-task`](../ace-task) can update specs confidently in batch workflows.

## Documentation

Command help: `ace-support-markdown` is a library package; see inline API docs and tests for usage.

---

Part of [ACE](../README.md) (Agentic Coding Environment)
