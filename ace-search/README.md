# ace-search

Unified codebase search -- one command that auto-detects files or content.

[Getting Started](docs/getting-started.md) | [CLI Usage Reference](docs/usage.md) | [Handbook Reference](docs/handbook.md)

![ace-search demo](docs/demo/ace-search-getting-started.gif)

`ace-search` gives developers and coding agents a single search entry point that chooses file or content mode automatically, keeps search scope predictable from any directory, and exposes fast output modes for workflow automation.

## Use Cases

**Find code patterns quickly without deciding tooling first** - run `ace-search "TODO"` or `ace-search "*.rb"` and let DWIM detection pick content vs file search.

**Constrain investigations to meaningful working sets** - combine `--staged`, `--tracked`, or `--changed` to inspect only Git-relevant files during reviews and refactors.

**Feed downstream tooling and automation** - use `--json`, `--yaml`, `--count`, or `--files-with-matches` for machine-readable pipelines and scripted checks.

**Standardize repeat searches across teams** - apply named presets with `--preset` for consistent daily scans and focused research queries.

## Works With

- **[ace-git](../ace-git)** for staged/tracked/changed scope filters in Git-aware search flows.
- **[ace-support-config](../ace-support-config)** for configuration cascade and user/project defaults.
- **[ace-support-nav](../ace-support-nav)** for protocol-backed navigation used by search workflows.

## Features

- DWIM mode by default for automatic file-vs-content detection.
- Project-wide search root resolution for consistent results from subdirectories.
- Dual backend execution using ripgrep for content and fd for files.
- Preset system for reusable named search configurations.
- Git-aware filters for staged, tracked, and changed file scopes.
- Flexible output modes: text, JSON, YAML, count, and files-with-matches.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Usage Reference](docs/usage.md)
- [Handbook Reference](docs/handbook.md)
- Command help: `ace-search --help`

## Agent Skills

Package-owned canonical skills:

- `as-search-run`
- `as-search-research`
- `as-search-feature-research`

## Part of ACE

`ace-search` is part of [ACE](../README.md) (Agentic Coding Environment).
