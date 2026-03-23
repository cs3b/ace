---
doc-type: user
title: ace-compressor Getting Started
tags:
  - ace-compressor
  - getting-started
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# Getting Started with `ace-compressor`

## Prerequisites

- Ruby 3.2+
- `ace-compressor` installed and on `PATH` through the repo bundle

## Install

- From RubyGems:

```bash
gem install ace-compressor
```

- From this repo (development environment):

```bash
bundle install
```

## First Compression

Compress a single Markdown file using exact mode (the default):

```bash
ace-compressor docs/architecture.md
```

Expect output like:

```text
/absolute/path/to/.ace-local/compressor/exact/docs/architecture.a1b2c3d4e5f6.exact.pack
```

The printed path is the cached pack file. Subsequent runs on the same unchanged source reuse this artifact.

## Viewing the Output

Use `--format stdio` to print the ContextPack/3 content directly:

```bash
ace-compressor docs/architecture.md --format stdio
```

Expect pipe-delimited records like:

```text
H|ContextPack/3|exact
FILE|docs/architecture.md
SEC|overview
SUMMARY|ACE is a mono-repo of Ruby gems...
FACT|All gems follow the ATOM architecture pattern.
LIST|scope|[atom_pattern,config_cascade,key_ads]
```

## Checking Compression Stats

Use `--format stats` to see a summary of what happened:

```bash
ace-compressor docs/architecture.md --format stats
```

```text
Cache:    hit
Output:   /.../.ace-local/compressor/exact/docs/architecture.a1b2c3d4e5f6.exact.pack
Sources:  1 file
Mode:     exact
Original: 8,412 B, 201 lines
Packed:   7,580 B, 95 lines
Change:   -9.9% bytes, -52.7% lines
```

## Trying Different Modes

### Exact Mode (default)

Deterministic semantic extraction — no LLM involved:

```bash
ace-compressor docs/vision.md --mode exact --format stats
```

### Agent Mode

Runs exact extraction first, then uses an LLM (via [ace-llm](../ace-llm)) to rewrite selected payloads for tighter compression:

```bash
ace-compressor docs/vision.md --mode agent --format stats
```

### Compact Mode

Policy-driven narrative compaction with explicit loss markers:

```bash
ace-compressor docs/vision.md --mode compact --format stats
```

## Compressing Multiple Sources

Pass multiple files or directories in one run:

```bash
ace-compressor docs/vision.md docs/architecture.md --mode exact --format stats
```

Compress all Markdown files in a directory:

```bash
ace-compressor docs/ --mode exact --format stats
```

## Comparing Modes with Benchmark

Run all modes side-by-side on the same source:

```bash
ace-compressor benchmark docs/architecture.md --modes exact,compact,agent
```

## Common Commands

| Command | What it does |
| --- | --- |
| `ace-compressor file.md` | Compress a file using exact mode |
| `ace-compressor file.md --format stats` | Show compression statistics |
| `ace-compressor file.md --format stdio` | Print ContextPack/3 content to stdout |
| `ace-compressor file.md --mode agent` | Compress with LLM-assisted rewriting |
| `ace-compressor docs/ --mode exact` | Compress all Markdown files in a directory |
| `ace-compressor benchmark file.md` | Compare modes on the same source |

## What to try next

- Use `ace-compressor project` to compress the [ace-bundle](../ace-bundle) project context preset
- Add `.ace/compressor/config.yml` for project-level configuration overrides
- Explore `--source-scope per-source` for independent per-file output
- See the full [Usage Guide](usage.md) for cache configuration, error conditions, and best practices
