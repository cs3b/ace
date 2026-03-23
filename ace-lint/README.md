<h1 align="center">ace-lint</h1>

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-lint"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-lint.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

  Ruby-native linting for markdown, YAML, and Ruby with no Node.js or Python runtime required.
</p>

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)
> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

![ace-lint demo](docs/demo/ace-lint-getting-started.gif)

`ace-lint` gives developers and coding agents a single Ruby-first lint command that validates docs and code, applies safe auto-fixes, and keeps behavior predictable through config cascade defaults. It covers markdown, YAML, Ruby, and frontmatter without requiring Node.js or Python tooling.

## How It Works

1. Run lint checks across markdown, YAML, Ruby, and frontmatter validators in one pass.
2. Apply safe auto-fixes with `--fix` for markdown and Ruby style issues.
3. Report results with colorized pass/fail output, using configuration cascade from CLI flags through project and user defaults.

## Use Cases

**Validate markdown, YAML, and Ruby in one pass** - run [`ace-lint`](docs/usage.md) for doc and code lint checks without mixing Node/Python tooling into Ruby projects. Use `/as-lint-run` for the full agent-driven lint workflow.

**Apply low-risk formatting fixes before review** - use `--fix` to automatically clean markdown and Ruby style issues prior to manual review. Run `/as-lint-fix-issue-from` to fix specific issues identified in lint reports.

**Standardize lint behavior across teams and repos** - rely on user/project/default cascade settings from [ace-support-config](../ace-support-config) for consistent validator sets and output modes.

**Process and act on lint reports** - use `/as-lint-process-report` to analyze lint output and coordinate fixes, pairing with [ace-docs](../ace-docs) for documentation maintenance workflows that complement lint validation.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
