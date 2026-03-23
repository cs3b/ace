---
doc-type: user
title: ace-docs Usage Guide
purpose: CLI reference for ace-docs commands and options
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-docs Usage Guide

Reference for current `ace-docs` commands, arguments, options, and common examples.

## Commands

- `status`
- `discover`
- `analyze`
- `analyze-consistency`
- `update`
- `validate`

## status

Show status of managed documents.

```bash
ace-docs status [OPTIONS]
```

Options:

- `--type VALUE`
- `--needs-update`
- `--freshness VALUE` (`current`, `stale`, `outdated`)
- `--package PKG[,PKG2]`
- `--glob GLOB[,GLOB2]`

Examples:

```bash
ace-docs status
ace-docs status --needs-update
ace-docs status --type guide
ace-docs status --freshness stale
ace-docs status --package ace-docs
ace-docs status --glob 'ace-docs/docs/**/*.md'
```

## discover

List managed documents.

```bash
ace-docs discover [OPTIONS]
```

Options:

- `--package PKG[,PKG2]`
- `--glob GLOB[,GLOB2]`

Examples:

```bash
ace-docs discover
ace-docs discover --package ace-docs
ace-docs discover --glob 'ace-docs/**/*.md'
```

## analyze

Analyze changes for a single document with LLM support.

```bash
ace-docs analyze FILE [OPTIONS]
```

Arguments:

- `FILE` (required)

Options:

- `--since VALUE`
- `--exclude-renames`
- `--exclude-moves`

Examples:

```bash
ace-docs analyze README.md
ace-docs analyze docs/architecture.md --since '2026-03-01'
ace-docs analyze docs/usage.md --exclude-renames --exclude-moves
```

## analyze-consistency

Analyze consistency across multiple documents.

```bash
ace-docs analyze-consistency [PATTERN] [OPTIONS]
```

Arguments:

- `PATTERN` (optional file or directory pattern)

Options:

- `--terminology`
- `--duplicates`
- `--versions`
- `--all`
- `--threshold VALUE`
- `--output VALUE` (`markdown`, `json`, `text`)
- `--save`
- `--model VALUE`
- `--timeout VALUE`
- `--strict`
- `--package PKG[,PKG2]`
- `--glob GLOB[,GLOB2]`

Examples:

```bash
ace-docs analyze-consistency
ace-docs analyze-consistency docs/
ace-docs analyze-consistency --terminology
ace-docs analyze-consistency --duplicates --threshold 80
ace-docs analyze-consistency --package ace-docs
```

## update

Update frontmatter fields for one file or a preset scope.

```bash
ace-docs update [FILE] [OPTIONS]
```

Arguments:

- `FILE` (optional when `--preset` is used)

Options:

- `--set key=value` (repeatable)
- `--preset VALUE`
- `--package PKG[,PKG2]`
- `--glob GLOB[,GLOB2]`

Examples:

```bash
ace-docs update README.md --set last-updated=today
ace-docs update docs/guide.md --set status=complete --set last-reviewed=2026-03-22
ace-docs update --preset handbook --set last-checked=today
ace-docs update --glob 'ace-docs/docs/**/*.md' --set last-updated=today
```

## validate

Validate documentation structure and content rules.

```bash
ace-docs validate [PATTERN] [OPTIONS]
```

Arguments:

- `PATTERN` (optional)

Options:

- `--syntax`
- `--semantic`
- `--all`
- `--package PKG[,PKG2]`
- `--glob GLOB[,GLOB2]`

Examples:

```bash
ace-docs validate
ace-docs validate README.md
ace-docs validate --syntax
ace-docs validate --semantic
ace-docs validate --package ace-docs
```

## Exit Codes

- `status`, `discover`, `analyze`, `update`: `0` success, `1` error
- `analyze-consistency`: `0` success, `1` issues found with `--strict`, `2` error
- `validate`: `0` pass, `1` validation failure, `2` error

## Frontmatter-Free Files

Files matching the `frontmatter_free` config patterns (default: `README.md`, `*/README.md`) are managed without YAML frontmatter. `ace-docs` currently infers metadata only for README basenames, so status/discover management for frontmatter-free files is README-focused.

- `status` and `discover` include them with metadata inferred from file path, content, and git history.
- `update` skips frontmatter writes and prints a skip message instead of inserting YAML.
- `validate` (via ace-lint) exempts them from missing-frontmatter errors.

Override the default README patterns in `.ace/docs/config.yml`:

```yaml
frontmatter_free:
  - "README.md"
  - "*/README.md"
```

## Notes

- `analyze` requires a `FILE` argument.
- For large repos, use `--package` and `--glob` to limit analysis scope.
