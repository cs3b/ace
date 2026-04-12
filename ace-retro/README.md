<div align="center">
  <h1> ACE - Retro </h1>

  Lightweight retrospective management — create, tag, and archive retros from the command line.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-retro"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-retro.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-retro demo](docs/demo/ace-retro-getting-started.gif)

`ace-retro` helps teams capture learning while context is still fresh and maintain a searchable archive for follow-up improvements. Use [`ace-retro create`](docs/usage.md) to start a retro from the CLI (or `/as-retro-create` from an interactive agent session), use `/as-retro-analyze-worktree` to analyze completed assignments across one or many worktrees for scope drift, post-completion work, and `.ace-local` review/test telemetry, then `/as-retro-synthesize` to recursively distill multiple retros into a new synthesis retro with repo-validated rankings and unresolved improvement themes.

## How It Works

1. Create a retrospective from type-aware templates (standard, conversation-analysis, or self-review) with [`ace-retro create`](docs/usage.md).
2. Enrich metadata with tags and status updates.
3. Archive completed retros to preserve history while keeping the active workspace clean.

## Use Cases

**Capture retros quickly after delivery** - use `/as-retro-create` or [`ace-retro create`](docs/usage.md) to initialize a retro from templates while the work is still fresh.

**Analyze completed worktrees** - use `/as-retro-analyze-worktree` to surface initial scope vs final outcome drift, classify post-completion residual work, and include `.ace-local` review/test signals in high-value spec upgrades from real assignment outcomes.

**Synthesize patterns across retros** - use `/as-retro-synthesize` to merge retros or older synthesis retros into a new synthesis artifact, dedupe original source evidence, validate findings against the current repo, and surface only unresolved themes as action items.

**Review and maintain retro metadata** - list, show, and update retros with tags and status, then archive completed entries without losing searchability.

**Improve agent workflows over time** - use `/as-handbook-selfimprove` to feed retro insights back into handbook guidance for better future performance.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
