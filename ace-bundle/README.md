<div align="center">
  <h1> ACE - Bundle </h1>

  Assemble multiple sources into a single bundled file, with optional compression.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-bundle"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-bundle.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-bundle demo](docs/demo/ace-bundle-getting-started.gif)

`ace-bundle` assembles multiple sources — files, shell commands, and git diffs — into a single bundled file. Configure inputs through [presets](.ace-defaults/bundle/presets/project.md) or [frontmatter in any markdown file](../ace-task/handbook/workflow-instructions/task/finder.wf.md), with built-in support for protocol URLs (`wfi://`, `guide://`, `tmpl://`, `prompt://`, `task://`) resolved by [ace-support-nav](../ace-support-nav). Output goes to stdout or a cache file under `.ace-local/bundle/`, with optional compression through [ace-compressor](../ace-compressor).

## How It Works

1. Specify inputs as preset names (`project`, `code-review`), file paths, protocol URLs (`wfi://`, `guide://`, `task://`), or markdown files with [frontmatter configuration](.ace-defaults/bundle/presets/code-review.md).
2. ace-bundle resolves protocols via [ace-support-nav](../ace-support-nav), reads files, executes commands, generates diffs, and merges everything into structured section-based output.
3. Output is delivered to stdout or saved to `.ace-local/bundle/`, optionally compressed through [ace-compressor](../ace-compressor) for large payloads.

## Use Cases

**Load project context in one command** — run [`ace-bundle project`](docs/usage.md) to assemble architecture docs, repository state, and command output from a single [preset](.ace-defaults/bundle/presets/project.md) into a cached bundle.

**Pull workflow instructions by protocol URL** — run `ace-bundle wfi://task/finder` (or `guide://...`, `tmpl://...`, `prompt://...`) to resolve and load canonical handbook resources via [ace-support-nav](../ace-support-nav).

**Bundle task context for agent workflows** — run `ace-bundle task://t.0or --output cache` to assemble task-specific files, commands, and diffs into a single artifact for agent consumption.

**Compress large bundles for LLM workflows** — add `--compressor on` to reduce payload size through [ace-compressor](../ace-compressor), with `exact` and `agent` compression modes.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
