<div align="center">
  <h1> ACE - Compressor </h1>

  Compress Markdown and text into ContextPack/3 artifacts for efficient LLM context loading.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.S.png" alt="ACE Logo" width="480">

  <a href="https://rubygems.org/gems/ace-compressor"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-compressor.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.
[Usage Guide](docs/usage.md)
`ace-compressor` provides deterministic context compression for one or more sources, with exact extraction, policy-driven compact output, and agent-assisted payload rewriting while preserving record structure. It integrates with [ace-bundle](../ace-bundle) for input resolution and [ace-llm](../ace-llm) for agent-mode rewriting.

## How It Works

1. Feed one or more Markdown or text sources into a compression mode (`exact`, `compact`, or `agent`).
2. The compressor extracts structured records, applies mode-specific reduction policies, and produces a stable `ContextPack/3` artifact.
3. Output goes to a cache-backed path for reuse or inline to stdio, with optional stats summaries and benchmark comparisons.

## Use Cases

**Prepare large docs for agent workflows** - run [`ace-compressor docs/vision.md --mode exact`](docs/usage.md) to reduce source size while keeping provenance and section structure intact for [ace-bundle](../ace-bundle) payloads.

**Compare compression strategies on real files** - run benchmark mode across `exact`, `compact`, and `agent` to inspect retention and size tradeoffs before committing to a compression approach.

**Build repeatable context artifacts** - generate stable output paths and reuse cache-backed pack artifacts across runs in CI pipelines and multi-agent loops.

**Rewrite payloads with LLM assistance** - use agent mode with [ace-llm](../ace-llm) to rewrite payload text while keeping the deterministic `ContextPack/3` structure, producing more concise context for downstream consumers.

## Documentation

[Usage Guide](docs/usage.md)

---

Part of [ACE](../README.md) (Agentic Coding Environment)

