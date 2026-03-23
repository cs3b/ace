# ace-idea

<p align="center">
  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">
</p>

[![Gem Version](https://img.shields.io/gem/v/ace-idea.svg)](https://rubygems.org/gems/ace-idea)
[![Ruby](https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

> Capture ideas quickly, then shape and organize them for execution.

Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-idea demo](docs/demo/ace-idea-getting-started.gif)

Ideas appear mid-flow: copied from chat, typed in a terminal, or drafted with an LLM. `ace-idea` gives them a stable home in git with sortable IDs and lightweight status updates, so ideas stay actionable instead of scattered across notes and tabs.

## How It Works

1. Capture idea text into a structured markdown artifact with metadata from direct input, stdin, or clipboard.
2. Refine and organize entries through review-oriented workflows with tags, scoping, and bucket placement.
3. Promote ready ideas into execution tasks when they pass review.

## Use Cases

**Capture from anywhere** - create an idea from direct text input, stdin, or clipboard content with [`ace-idea create`](docs/usage.md). Add `--enhance` when a rough note needs LLM cleanup, or use `/as-idea-capture` for the full agent-driven workflow.

**Shape and review** - run `/as-idea-review` to turn raw notes into structured entries with clearer scope, tags, and next actions. Use `/as-idea-capture-features` for feature-oriented ideation sessions.

**Organize by intent** - move ideas through root `next` plus `_maybe`, `_anytime`, and `_archive` buckets to keep near-term ideas visible while preserving long-tail exploration.

**Track and maintain** - use [`ace-idea list`](docs/usage.md), `ace-idea show`, and `ace-idea status` for visibility, then run `ace-idea doctor` to detect and repair structure drift.

**Promote to execution** - once an idea is ready, hand it off to [ace-task](../ace-task) and continue with planning and implementation workflows.

## Documentation

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)
