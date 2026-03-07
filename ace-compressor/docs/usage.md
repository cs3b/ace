---
doc-type: how-to-guide
purpose: Usage guide for ace-compressor CLI tool — exact-mode context compression to ContextPack/2.
update:
  update_frequency: on-change
  last-updated: '2026-03-07'
---

# ace-compressor Usage Guide

## Document Type: How-To Guide + Reference

## Overview

`ace-compressor` compresses Markdown and text files into a compact `ContextPack/2` format — a
minimal, machine-readable representation that preserves document structure, headings, facts, tables,
and rule modalities while reducing exact-mode wire overhead.

**Key Features:**

- **Exact mode**: Lossless structural extraction — every heading, paragraph, table, and rule block
  is preserved as a typed record.
- **Multi-source**: Accepts one or more files and/or directories in a single run.
- **Provenance**: A compact source table maps source IDs to file paths once per pack.
- **Fidelity markers**: Images emit `U|...`; fenced code blocks emit `B|...` rather than failing
  silently.

## Quick Start

```bash
# Compress a single Markdown file
ace-compressor docs/vision.md --mode exact

# Expected output:
/absolute/path/to/.ace-local/compressor/exact/docs/vision.<hash>.exact.pack
```

**Success criteria:** The command writes a pack file and prints its path by default.

## Command Interface

### Basic Usage

```bash
# Single file
ace-compressor <file> --mode exact

# Multiple files
ace-compressor file1.md file2.md --mode exact

# Directory (recursively finds .md and .txt files)
ace-compressor docs/ --mode exact

# Mixed sources
ace-compressor README.md docs/ --mode exact

# Verbose (shows skipped files in directory traversal)
ace-compressor docs/ --mode exact --verbose
```

### Command Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--mode` | | Compression mode (`exact`) | `exact` |
| `--output` | `-o` | Save output to file or directory path | canonical cache path |
| `--format` | `-f` | Console output format: `path`, `stdio`, `stats` | `path` |
| `--verbose` | `-v` | Show skipped files during directory traversal | `false` |
| `--quiet` | `-q` | Suppress non-essential output | `false` |
| `--debug` | `-d` | Show debug output | `false` |
| `--help` | `-h` | Show help | |

## Output Contract

`ace-compressor` separates saved output from console output:

- `--output` controls where the pack file is saved
- `--format` controls what is printed to stdout

### `--output`

- Omitted: writes to canonical cache under `.ace-local/compressor/exact/`
- File path: writes exactly that file
- Directory path: if the path exists as a directory or ends with `/`, derives a hashed filename inside it

The canonical cache is still used for freshness checks even when `--output` points somewhere else.

### `--format`

- `path` (default): print the saved pack path
- `stdio`: print the full `ContextPack/2` content
- `stats`: print a short human-readable summary showing cache status, output location, and original vs packed totals

Example stats output:

```text
Cache:    hit
Output:   /abs/path/to/file.pack
Sources:  1 file
Mode:     exact
Original: 3,663 B, 101 lines
Packed:   3,691 B, 37 lines
Change:   +0.8% bytes, -63.4% lines
```

## Output Format: ContextPack/2

Every run emits a stream of pipe-delimited records:

| Record Type | Example | Meaning |
|-------------|---------|---------|
| `H|` | `H\|ContextPack/2\|exact` | Header — one per run |
| `S|` | `S\|1\|docs/vision.md` | Source table entry |
| `M|` | `M\|1\|2\|Overview` | Section heading |
| `F|` | `F\|1\|A preserved paragraph fact.` | Fact / paragraph |
| `T|` | `T\|1\|\| Name \| Value \| \|\|ROW\|\| ...` | Table rows (preserved verbatim) |
| `U|` | `U\|1\|image-only\|![Chart](chart.png)` | Unresolved image reference |
| `B|` | `B\|1\|fenced-code\|fenced code payload...` | Fenced code fallback |

The format is intentionally compact:

- source paths appear once in the `S|` table, not on every record
- section IDs are implicit from record order rather than serialized on each fact
- record fields use fixed positions instead of repeated `key=value` labels

## Common Scenarios

### Scenario 1: Compress a single document

**Goal**: Convert a Markdown doc for LLM consumption with minimal token footprint.

```bash
ace-compressor docs/architecture.md --mode exact
```

**Expected Output**:
```
/absolute/path/to/.ace-local/compressor/exact/docs/architecture.<hash>.exact.pack
```

### Scenario 2: Compress multiple files into a merged pack

**Goal**: Combine several reference docs into a single structured pack.

```bash
ace-compressor docs/vision.md docs/architecture.md --mode exact --format stdio
```

**Expected Output** (excerpt):
```
H|ContextPack/2|exact
S|1|docs/architecture.md
S|2|docs/vision.md
M|1|1|ACE - System Architecture
...
M|2|1|ACE Vision
```

Files are sorted alphabetically; provenance comes from the `S|` source table plus the source ID in
each record.

### Scenario 3: Compress an entire directory

**Goal**: Build a pack from all Markdown/text files under `docs/`.

```bash
ace-compressor docs/ --mode exact --format stats
```

**Expected Output** (excerpt):
```
Cache:    miss
Output:   /.../.ace-local/compressor/exact/multi.<hash>.exact.pack
Sources:  41 files
Mode:     exact
Original: ...
Packed:   ...
Change:   ...
```

Use `--verbose` to see which files were skipped (non-Markdown/text files).

### Scenario 4: Capture output to a file

```bash
ace-compressor docs/ --mode exact --output context.pack
```

### Scenario 5: Save into a directory with a derived hashed filename

```bash
ace-compressor docs/vision.md --mode exact --output .ace-local/export/
```

### Scenario 6: Print content while still writing the pack file

```bash
ace-compressor docs/vision.md --mode exact --format stdio
```

## Error Conditions

| Error | Cause | Exit Code |
|-------|-------|-----------|
| `Input source not found: <path>` | File or directory does not exist | 1 |
| `Input file is empty: <path>` | File has zero bytes | 1 |
| `Binary file not supported: <path>` | File contains null bytes | 1 |
| `No supported source files found in directory: <path>` | Directory has no `.md`/`.txt` files | 1 |
| No paths provided | Missing `[SOURCES]` argument | 1 |

## Configuration

No project-level configuration is required for basic usage. Defaults are in
`.ace-defaults/compressor/config.yml`.

To override defaults project-wide, create `.ace/compressor/config.yml`:

```yaml
compressor:
  default_mode: exact
  default_format: path
  cache_dir: .ace-local/compressor
```

## Troubleshooting

### Problem: Binary file rejected

**Symptom**: `Binary file not supported: image.png`

**Solution**: Only pass Markdown (`.md`) or text (`.txt`) files. Binary files are never accepted
even when buried in a directory — the tool skips them automatically during traversal but rejects
them when passed explicitly.

### Problem: Empty directory fails

**Symptom**: `No supported source files found in directory: ./tmp`

**Solution**: Ensure the directory contains at least one `.md` or `.txt` file.

### Problem: Duplicate paths processed once

**Behaviour**: `ace-compressor file.md file.md` processes `file.md` once and emits one `S|` source
entry. Deduplication is automatic.

### Problem: Fish shell rejects `{hash}` style output paths

**Symptom**: `fish: Unexpected end of string, incomplete parameter expansion`

**Solution**: Do not use brace-style placeholder templates in `--output`. Pass a normal file path,
or pass a directory path and let `ace-compressor` derive the hashed filename for you.

## Best Practices

1. **Use default cache output for repeat work**: repeated runs on unchanged sources reuse the same canonical pack artifact.
2. **Use `--format stdio` only when a consumer truly needs inline content**: the default `path` output is cheaper and easier to chain.
3. **Use `--output` for explicit exports**: keep cache as the freshness source, and export copies only when needed.
4. **Use provenance**: Resolve source IDs through the `S|` table to trace facts back to source documents.
5. **Read stats as a comparison**: the compact exact format removes most structural overhead, but exact mode can still be slightly larger than the raw source while collapsing line count substantially.
6. **Check unresolved markers**: Image-heavy docs emit `U|...` records —
   review these if visual content is critical.
7. **Rely on deterministic ordering**: Multiple files are always sorted alphabetically, making
   output stable across re-runs.
