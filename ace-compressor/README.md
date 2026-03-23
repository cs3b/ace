# ace-compressor

Compress Markdown and text inputs into `ContextPack/3` artifacts for efficient LLM context loading.

[CLI Usage Reference](docs/usage.md)

`ace-compressor` provides deterministic context compression for one or more sources, with exact extraction,
policy-driven compact output, and agent-assisted payload rewriting while preserving record structure.

## Use Cases

**Prepare large docs for agent workflows** - reduce source size while keeping provenance and section structure intact.

**Compare compression strategies on real files** - run benchmark mode across `exact`, `compact`, and `agent` to inspect
retention and size tradeoffs.

**Build repeatable context artifacts** - generate stable output paths and reuse cache-backed pack artifacts across runs.

## Works With

- **[ace-bundle](../ace-bundle)** for resolving preset and protocol-based input sources.
- **[ace-llm](../ace-llm)** for agent-mode payload rewriting through configured models.

## Features

- Exact mode for canonical semantic extraction into structured records.
- Compact mode with policy metadata for narrative-heavy content.
- Agent mode that rewrites payload text while keeping deterministic `ContextPack/3` structure.
- Multi-source support for files, directories, and mixed source inputs.
- Benchmark command for side-by-side mode comparison on live sources.
- Output controls for cache path, inline stdio content, or stats summaries.

## Quick Start

```bash
ace-compressor docs/vision.md --mode exact

ace-compressor docs/vision.md --mode compact --format stdio

ace-compressor docs/architecture.md --mode agent --verbose

ace-compressor benchmark docs/architecture.md --modes exact,compact,agent
```

## Documentation

- [CLI Usage Reference](docs/usage.md)
- Command help: `ace-compressor --help`

## Agent Skills

`ace-compressor` currently ships no package-owned canonical skills.

## Part of ACE

`ace-compressor` is part of [ACE](../README.md) (Agentic Coding Environment).
