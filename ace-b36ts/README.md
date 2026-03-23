<div align="center">
  <h1> ACE - B36TS </h1>

  Compact, sortable Base36 timestamp IDs for scripts, logs, and path-friendly artifacts.

  <img src="https://raw.githubusercontent.com/cs3b/ace/main/docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-b36ts"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-b36ts.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

![ace-b36ts demo](docs/demo/ace-b36ts-getting-started.gif)

`ace-b36ts` encodes UTC timestamps into short Base36 IDs that preserve chronological order in plain string sorting, and decodes them back when you need readable time output. Seven encode formats range from `month` granularity down to `ms`, with a configurable `year_zero` epoch baseline.

## How It Works

1. Encode a timestamp (or `now`) into a compact Base36 ID -- from 2 characters at month granularity up to 8 at millisecond precision.
2. Use the ID directly in file names, directory paths (with `--split`), log entries, or automation artifacts.
3. Decode the ID back into a human-readable UTC timestamp for debugging, audits, or incident review.

All examples below encode **2026-03-23 12:00:00 UTC**:

| Format | Chars | Precision | Example |
|--------|-------|-----------|---------|
| `month` | 2 | month | `8q` |
| `week` | 3 | ISO week | `8qy` |
| `day` | 3 | day | `8qm` |
| `40min` | 4 | 40 min | `8qmi` |
| `2sec` | 6 | ~1.85 s | `8qmi00` |
| `50ms` | 7 | ~50 ms | `8qmi000` |
| `ms` | 8 | ~1.4 ms | `8qmi0000` |

> `day` and `week` both produce 3-character IDs. The 3rd character distinguishes them: values 0--30 in base36 encode days 1--31, while values 31--35 encode ISO weeks (Thursday determines which week a date belongs to).

## Use Cases

**Create sortable IDs for automation output** - generate compact IDs for build artifacts, log entries, and task files without long timestamp strings. Use [`ace-b36ts encode now`](docs/usage.md) for quick generation or `/as-b36ts` in agent workflows.

**Map IDs to directory paths** - use split output (`--split`) to create hierarchical paths for storage and archival workflows across [ace-assign](../ace-assign) and [ace-task](../ace-task) pipelines.

**Round-trip between compact IDs and timestamps** - decode IDs during debugging, audits, and incident review flows with [`ace-b36ts decode`](docs/usage.md).

**Embed in shell and CI pipelines** - use deterministic, timestamp-derived IDs in scripts and Ruby automation through the `Ace::B36ts` API for encode/decode helpers.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
