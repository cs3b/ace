---
doc-type: template
title: Package README
purpose: Selling-page README template for ACE packages
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

<div align="center">
  <h1> ACE - {package-title} </h1>

  {one-sentence tagline}

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/{package-name}"><img alt="Gem Version" src="https://img.shields.io/gem/v/{package-name}.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>
</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)


<!-- Nav row: pipe-separated links above the demo. Always use "Handbook - Skills, Agents, Templates"
     as the expanded label so readers know what the handbook contains.
     Place above the demo so readers find docs before scrolling. -->

![demo](docs/demo/{package-name}-getting-started.gif)

<!-- Keep {package-title} as humanized package name, e.g. `ACE - Task` or `ACE - Test Runner E2E`. -->
<!-- If this package has no docs/ directory, use only:
Part of [ACE](https://github.com/cs3b/ace)
and do not add documentation links in the footer. -->

<!-- Include GIF for CLI tools. Omit for support libraries and integrations. -->

<!-- Intro paragraph: 2-4 sentences that describe the problem space and what the package
     does about it. Do NOT list subcommands or features here — Use Cases covers those.
     Weave the value proposition naturally instead of splitting into Problem/Solution.
     IMPORTANT: Read the implementation code before describing features - do not write from plan notes. -->

## How It Works

<!-- Mermaid diagram OR 3-step numbered list.
     Show the mental model, not the implementation.
     Optional - include only when the mental model isn't obvious from Use Cases.

     Example Mermaid (add as a fenced mermaid code block):
       graph LR
         A[Input] then B[Process] then C[Output]
     Replace "then" with the Mermaid arrow syntax. -->

## Use Cases

<!-- Each entry: **bold title** - description paragraph.
     Inline references:
       - Skills: always use `/as-` prefix (e.g., `/as-task-draft`)
       - CLI commands: link to usage docs (e.g., [`ace-task create`](docs/usage.md#ace-task-create-title))
       - Ecosystem packages: link to sibling directories inline (e.g., [ace-overseer](../ace-overseer))
     Write 3-6 use cases. Each should show a real workflow, not just name a feature.

     Example:
       **Draft and structure work** - create a task, split it into subtasks, add new subtasks as work
       reveals scope. Use `/as-task-draft` to draft from an earlier captured [idea](../ace-idea) or
       short note, or [`ace-task create`](docs/usage.md#ace-task-create-title) from the CLI. -->

---

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
