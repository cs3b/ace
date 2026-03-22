---
doc-type: user
title: ace-b36ts
purpose: Landing documentation for ace-b36ts
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-b36ts

**Compact, sortable Base36 timestamp IDs**

![Demo](docs/demo/ace-b36ts-getting-started.gif)

## Why

Convert timestamps into short IDs you can use for IDs, filenames, and logs. A 6-character value keeps data compact while preserving chronological order in normal string sorting.

## Works With

- Ruby scripts and task automation
- CLI and shell-based workflows
- CI and release pipelines
- Agent and bot integrations

## Agent Skills

- `as-b36ts` (`wfi://b36ts`)

## Features

- **6-character Base36 IDs** as a compact default format
- **7 format options** from 2-char monthly to 8-char millisecond precision
- **Chronologically sortable** IDs (`string` order equals time order)
- Default 108-year coverage with configurable `year_zero`
- Built-in `encode` and `decode` operations
- Split output support for hierarchical paths

## Quick Start

```bash
mise exec -- ace-b36ts encode now          # generate an ID
mise exec -- ace-b36ts decode <id>         # decode back to timestamp
mise exec -- ace-b36ts config              # show resolved configuration
```

## Documentation

- [Getting Started](docs/getting-started.md)
- [Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)

---

Part of ACE (Agentic Coding Environment)
