---
doc-type: user
title: ace-search
purpose: Documentation for ace-search/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-search

Unified codebase search -- one command that auto-detects files or content.

![ace-search demo](docs/demo/ace-search-getting-started.gif)

## Why ace-search

Searching code should not require picking tools first. `ace-search` uses DWIM detection to choose file or content search automatically, defaults to project-root scope so results are consistent from any directory, and combines fast backends for both modes.

## Works With

- **[ace-git](../ace-git)** - staged/tracked/changed scope filters for Git-aware search
- **[ace-support-config](../ace-support-config)** - configuration cascade for user and project defaults
- **[ace-support-nav](../ace-support-nav)** - protocol-backed navigation used by search workflows

## Agent Skills

- **`as-search-run`** - single-shot search execution
- **`as-search-research`** - multi-search research workflow
- **`as-search-feature-research`** - feature-gap and implementation-pattern research

See [Handbook Reference](docs/handbook.md) for the complete catalog.

## Features

- **DWIM mode by default** - auto-detects file globs vs content patterns
- **Project-wide search** - resolves search root consistently across directories
- **Dual backend speed** - ripgrep for content, fd for files
- **Preset system** - reusable named search configurations
- **Git-aware filters** - restrict scope to staged, tracked, or changed files
- **Flexible output** - text, JSON, YAML, count, and files-with-matches modes

## Documentation

- [Getting Started](docs/getting-started.md) - tutorial workflow
- [Usage Guide](docs/usage.md) - full CLI reference
- [Handbook Reference](docs/handbook.md) - skills and workflows
- Runtime help: `ace-search --help`

## Part of ACE

`ace-search` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
