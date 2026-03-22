---
doc-type: reference
title: ace-b36ts Usage Guide
purpose: CLI reference for ace-b36ts
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-b36ts Usage Guide

## Command Overview

- `ace-b36ts encode [timestamp]` — encode timestamp to compact ID
- `ace-b36ts decode <compact_id>` — decode to timestamp
- `ace-b36ts config` — print resolved configuration
- `ace-b36ts version` — print installed gem version
- `ace-b36ts help` — show command help
- `ace-b36ts --help` / `ace-b36ts -h` — show full help and examples

## `ace-b36ts encode`

```bash
mise exec -- ace-b36ts encode [timestamp]
```

- `timestamp` is optional. Use `now` or omit for the current UTC time.

Options:

- `--format <month|week|day|40min|2sec|50ms|ms>`
  - alias: `-f`
- `--count <N>`: generate `N` sequential IDs
  - alias: `-n`
- `--split <levels>`: split into hierarchical levels e.g., `month,week,day`
- `--path-only`: output only split path
- `--json`: output split output as JSON
- `--year-zero <year>`: set base year for encoding
  - alias: `-y`
- `--quiet`: suppress config summary output
  - alias: `-q`
- `--verbose`: show verbose output
  - alias: `-v`
- `--debug`: show debug traces on failures
  - alias: `-d`

Examples:

```bash
mise exec -- ace-b36ts encode now
mise exec -- ace-b36ts encode now --format day
mise exec -- ace-b36ts encode "2025-01-06 12:30:00" --format ms
mise exec -- ace-b36ts encode now --split month,week,day
mise exec -- ace-b36ts encode now --split month,day --path-only
mise exec -- ace-b36ts encode now --split month,day --json
mise exec -- ace-b36ts encode now --count 3 --format ms
```

## `ace-b36ts decode`

```bash
mise exec -- ace-b36ts decode <compact_id>
```

- `compact_id` is required.

Options:

- `--year-zero <year>`: set base year for decoding
  - alias: `-y`
- `--format <readable|iso|timestamp>`: output formatting mode
  - alias: `-f`
- `--split`: force hierarchical split decode path
- `--quiet`: suppress config summary output
  - alias: `-q`
- `--verbose`: show verbose output
  - alias: `-v`
- `--debug`: show debug traces on failures
  - alias: `-d`

Examples:

```bash
mise exec -- ace-b36ts decode i50jj3
mise exec -- ace-b36ts decode i50jj3 --format iso
mise exec -- ace-b36ts decode i50jj3 --format timestamp
mise exec -- ace-b36ts decode i5/1/5/j/j3
mise exec -- ace-b36ts decode i515jj3 --split
```

## `ace-b36ts config`

```bash
mise exec -- ace-b36ts config
mise exec -- ace-b36ts config --verbose
```

### Options

- `--verbose`: show config source order and derived metadata
  - alias: `-v`

## Global Options

Use full help output for the latest full flag list:

```bash
mise exec -- ace-b36ts --help
```
