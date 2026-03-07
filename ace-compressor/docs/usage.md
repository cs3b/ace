---
doc-type: how-to-guide
purpose: Usage guide for ace-compressor CLI tool — exact and compact context compression to ContextPack/3.
update:
  update_frequency: on-change
  last-updated: '2026-03-07'
---

# ace-compressor Usage Guide

## Document Type: How-To Guide + Reference

## Overview

`ace-compressor` compresses Markdown and text files into a compact `ContextPack/3` format — a
minimal, semantic representation that preserves document structure and meaning while reducing wire overhead.

**Key Features:**

- **Exact mode**: Canonical semantic extraction — headings, prose, lists, and code structures are
  converted into compact typed records.
- **Compact mode**: Policy-driven narrative compaction with runtime metadata:
  `POLICY|class=<...>|action=<...>`.
- **Multi-source**: Accepts one or more files and/or directories in a single run.
- **Provenance**: `FILE|` and `SEC|` records establish scope inline; no separate source table is emitted.
- **Fidelity markers**: Images emit `U|...`; compact reductions emit explicit `TABLE|...|strategy=...`,
  `LOSS|...`, and `EXAMPLE_REF|...` records.

## Quick Start

```bash
# Compress a single Markdown file
ace-compressor docs/vision.md --mode exact

# Compact narrative docs with runtime policy metadata
ace-compressor docs/vision.md --mode compact --format stdio

# Expected output:
/absolute/path/to/.ace-local/compressor/exact/docs/vision.<hash>.exact.pack
```

**Success criteria:** The command writes a pack file and prints its path by default.

## Command Interface

### Basic Usage

```bash
# Single file
ace-compressor <file> --mode exact

# Single file (compact mode)
ace-compressor <file> --mode compact

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
| `--mode` | | Compression mode (`exact`, `compact`) | `exact` |
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
- `stdio`: print the full `ContextPack/3` content
- `stats`: print a short human-readable summary showing cache status, output location, and original vs packed totals

Example stats output:

```text
Cache:    hit
Output:   /abs/path/to/file.pack
Sources:  1 file
Mode:     exact
Original: 3,663 B, 101 lines
Packed:   3,691 B, 37 lines
Change:   -6.2% bytes, -63.4% lines
```

## Output Format: ContextPack/3

Every run emits a stream of pipe-delimited records:

| Record Type | Example | Meaning |
|-------------|---------|---------|
| `H|` | `H\|ContextPack/3\|exact` | Header — one per run |
| `FILE|` | `FILE\|docs/vision.md` | Source scope marker |
| `POLICY|` | `POLICY\|class=narrative-heavy\|action=aggressive_compact` | Compact-mode runtime policy decision |
| `SEC|` | `SEC\|vision` | Section heading |
| `SUMMARY|` | `SUMMARY\|A high-level statement` | Overview prose |
| `FACT|` | `FACT\|A preserved factual statement` | Statement with operational content |
| `RULE|` | `RULE\|Tooling must avoid side effects` | Policy-style statement |
| `CONSTRAINT|` | `CONSTRAINT\|No more than 2 retries` | Hard constraints |
| `PROBLEMS|` | `PROBLEMS\|[context_bloat,isolation_boundary]` | Typed array |
| `LIST|` | `LIST\|core_principles\|[cli_first,transparent_inspectable]` | Generic typed array scoped to a section |
| `EXAMPLE|` | `EXAMPLE\|tool=ace-git-commit` | Example context marker |
| `EXAMPLE_REF|` | `EXAMPLE_REF\|tool=ace-git-commit\|source=docs/b.md\|original_source=docs/a.md\|reason=duplicate_example` | Ref to previously emitted example |
| `CMD|` | `CMD\|ace-git-commit -i "fix"` | Shell command block |
| `FILES|` | `FILES\|ace-git-commit\|[.ace-defaults/git/commit.yml,handbook/prompts/git-commit.system.md,exe/ace-git-commit]` | File listing |
| `TREE|` | `TREE\|docs\|src/...` | Tree-shaped block |
| `CODE|` | `CODE\|ruby\|puts 1` | Generic code block |
| `TABLE|` | `TABLE\|id=vision_t1\|strategy=schema_plus_key_rows\|rows=\| Tier \| QPS \| ...` | Compact table with explicit strategy |
| `LOSS|` | `LOSS\|kind=table\|target=vision_t1\|strategy=schema_plus_key_rows\|original_rows=7\|retained_rows=2\|dropped_rows=5` | Explicitly reports what was removed |
| `U|` | `U\|image-only\|![Chart](chart.png)` | Unresolved image reference |

The format is intentionally compact:

- file scope is established by the current `FILE|` record, not repeated on every line
- section scope is implicit from the preceding `SEC|` record
- record fields use fixed positions, no per-record `src=` fields

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
H|ContextPack/3|exact
FILE|docs/architecture.md
SEC|ace_system_architecture
...
FILE|docs/vision.md
SEC|ace_vision
```

Files are sorted alphabetically; provenance comes from the `FILE|` order and line sequence.

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
| `Input file is empty. Exact mode requires content: <path>` | Source has zero bytes or no post-frontmatter content | 1 |
| `Binary input is not supported in exact mode: <path>` | File contains null bytes | 1 |
| `Directory has no supported markdown/text sources: <path>` | Directory has no supported `.md`/`.txt` files | 1 |
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

**Symptom**: `Binary input is not supported in exact mode: image.png`

**Solution**: Only pass Markdown (`.md`) or text (`.txt`) files. Binary files are never accepted
even when buried in a directory — the tool skips them automatically during traversal but rejects
them when passed explicitly.

### Problem: Empty directory fails

**Symptom**: `Directory has no supported markdown/text sources: ./tmp`

**Solution**: Ensure the directory contains at least one `.md` or `.txt` file.

### Problem: Duplicate paths processed once

**Behaviour**: `ace-compressor file.md file.md` processes `file.md` once and emits one `FILE|` source
entry. Deduplication is automatic.

### Problem: Fish shell rejects `{hash}` style output paths

**Symptom**: `fish: Unexpected end of string, incomplete parameter expansion`

**Solution**: Do not use brace-style placeholder templates in `--output`. Pass a normal file path,
or pass a directory path and let `ace-compressor` derive the hashed filename for you.

## Best Practices

1. **Use default cache output for repeat work**: repeated runs on unchanged sources reuse the same canonical pack artifact.
2. **Use `--format stdio` only when a consumer truly needs inline content**: the default `path` output is cheaper and easier to chain.
3. **Use `--output` for explicit exports**: keep cache as the freshness source, and export copies only when needed.
4. **Use provenance**: use `FILE|` records to trace grouped facts back to source documents.
5. **Read stats as a comparison**: the compact exact format should show byte and line reductions for
   normal long-form documentation.
6. **Check unresolved markers**: Image-heavy docs emit `U|...` records —
   review these if visual content is critical.
7. **Rely on deterministic ordering**: Multiple files are always sorted alphabetically, making
   output stable across re-runs.
