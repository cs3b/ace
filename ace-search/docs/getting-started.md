---
doc-type: user
title: Getting Started with ace-search
purpose: Documentation for ace-search/docs/getting-started.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-search

Use `ace-search` when you need one command for both code-content search and file discovery.

## Prerequisites

- Ruby installed
- `ripgrep` available as `rg`
- `fd` available as `fd`

Install gem:

```bash
gem install ace-search
```

## Installation

If developing in this monorepo, install dependencies at repo root:

```bash
bundle install
```

## Your first search

Content search (auto-detected):

```bash
ace-search "TODO"
```

File search via DWIM (glob auto-detected):

```bash
ace-search "**/*search*.rb"
```

## Using presets

Run a named preset (ace-search ships a `code` preset in `.ace-defaults/search/presets/code.yml`; add your own under `.ace/search/presets/<name>.yml`):

```bash
ace-search "class" --preset code
```

## Configuring defaults

Create `.ace/search/config.yml` in your project and set defaults you use often (for example case-insensitive mode, excludes, max results).

## Git-aware search

Search only staged files:

```bash
ace-search "TODO" --staged
```

Search only tracked files:

```bash
ace-search "TODO" --tracked
```

Search only changed files:

```bash
ace-search "TODO" --changed
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-search "TODO"` | Content search (DWIM auto mode) |
| `ace-search "*.rb"` | File search (DWIM glob detection) |
| `ace-search "pattern" --content` | Force content mode |
| `ace-search "pattern" --files` | Force file mode |
| `ace-search "pattern" --preset NAME` | Run with a preset |
| `ace-search "pattern" --staged` | Search staged files only |
| `ace-search "pattern" --json` | JSON output |

## Next steps

- [Usage Guide](usage.md) - full option and flag reference
- [Handbook Reference](handbook.md) - search skills and workflows
- Try `--fzf` for interactive result selection
- For agent integrations, use the package skills listed in `docs/handbook.md`
