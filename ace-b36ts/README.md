# ace-b36ts

Generate compact, sortable Base36 timestamp IDs for scripts, logs, and path-friendly artifacts.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-b36ts getting started](docs/demo/ace-b36ts-getting-started.gif)

`ace-b36ts` encodes UTC timestamps into short IDs that preserve chronological order in plain string sorting, and decodes them back when you need readable time output.

## Use Cases

**Create sortable IDs for automation output** - generate compact IDs for build artifacts, log entries, and task files without long timestamp strings.

**Map IDs to directory paths** - use split output (`--split`) to create hierarchical paths for storage and archival workflows.

**Round-trip between compact IDs and timestamps** - decode IDs during debugging, audits, and incident review flows.

## Works With

- **[ace-assign](../ace-assign)** for assignment/task workflows that benefit from compact sortable IDs.
- **[ace-task](../ace-task)** for task references and structured artifact naming.
- **Shell and CI pipelines** for deterministic, timestamp-derived IDs in scripts.
- **Ruby automation** through the `Ace::B36ts` API for encode/decode helpers.

## Features

- 6-character Base36 IDs by default (`2sec` format).
- Seven encode formats: `month`, `week`, `day`, `40min`, `2sec`, `50ms`, `ms`.
- Chronological sortability with plain string order.
- Configurable `year_zero` to control epoch baseline.
- Encode/decode commands plus split and JSON path output options.

## Quick Start


```bash
ace-b36ts encode now
ace-b36ts decode i50jj3
ace-b36ts config

```

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-b36ts --help`

## Agent Skills

- `as-b36ts`

## Part of ACE

`ace-b36ts` is part of [ACE](../README.md) (Agentic Coding Environment).
