---
doc-type: reference
title: ace-demo Usage Guide
purpose: Complete CLI reference for recording demos and attaching them to PRs
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-demo Usage Guide

`ace-demo` turns terminal sessions into reviewable recordings and can post them to GitHub PRs.

## Command Overview

- `ace-demo list` — list available demo tapes
- `ace-demo show` — inspect tape metadata and contents
- `ace-demo record` — record a tape or inline command session
- `ace-demo retime` — generate faster playback variants
- `ace-demo attach` — upload an existing recording and comment on a PR
- `ace-demo create` — build a tape from commands
- `ace-demo version` — print installed gem version

## Global options

- `--help`, `-h` — show help
- `--version` — print version

## `ace-demo list`

### Syntax

```bash
ace-demo list
```

No arguments.

### Output

- `No demo tapes found.` when no tapes exist.
- `Available demo tapes:` with columns: name, description, source.

## `ace-demo show <tape>`

### Syntax

```bash
ace-demo show hello
ace-demo show ./path/to/demo.tape
```

### Arguments

- `<tape>` — tape name or `.tape` file path

### Behavior

Prints tape name, source, description/metadata, and full tape content.

## `ace-demo create <name> -- <commands...>`

### Syntax

```bash
ace-demo create <name> [options] -- <command>...
echo "git status" | ace-demo create <name> [options]
```

### Arguments

- `<name>` — tape name (saved as `.ace/demo/tapes/<name>.tape`)

### Options

| Option | Alias | Default | Purpose |
|--------|-------|---------|---------|
| `--desc` | `-D` | — | Set tape `Description` metadata |
| `--tags` | `-T` | — | Set comma-separated `Tags` metadata |
| `--width` | — | `960` | VHS terminal width |
| `--height` | — | `480` | VHS terminal height |
| `--font-size` | — | `16` | VHS font size |
| `--timeout` | `-t` | `2s` | Delay after each command |
| `--format` | `-f` | `gif` | Output format hint for generated metadata |
| `--force` | — | `false` | Overwrite existing tape |
| `--dry-run` | `-n` | `false` | Print generated `.tape` content only |

### Examples

```bash
ace-demo create my-demo -- "git status" "make deploy"
ace-demo create my-demo --desc "Release smoke" --tags smoke,release -- "npm test"
echo "git status" | ace-demo create my-demo
ace-demo create my-demo --dry-run -- "echo hello"
```

### Output

- `Created: .ace/demo/tapes/my-demo.tape`
- with `--dry-run`: prints tape content and exits

## `ace-demo record <tape|name>`

### Syntax

```bash
ace-demo record hello
ace-demo record ./local.tape --format mp4 --output /tmp/demo.mp4
ace-demo record ace-task/docs/demo/ace-task-getting-started.tape.yml
ace-demo record my-demo -- "git status" "make deploy"
ace-demo record my-demo --timeout 3s --width 1100 -- "git status"
echo "git status" | ace-demo record my-demo
ace-demo record hello --pr 42 --dry-run
```

### Arguments

- `<tape|name>`:
  - preset name (`hello`)
  - direct `.tape` path (`./local.tape`)
  - direct `.tape.yml` path (`ace-task/docs/demo/ace-task-getting-started.tape.yml`)
  - inline session name when commands are passed after `--`

### Options

| Option | Alias | Default | Purpose |
|--------|-------|---------|---------|
| `--output` | `-o` | `.ace-local/demo/<name>.<format>` | Output file path |
| `--format` | `-f` | `gif` | `gif`, `mp4`, `webm` |
| `--pr` | — | — | Attach to PR |
| `--dry-run` | `-n` | `false` | Preview output without running VHS |
| `--timeout` | `-t` | `2s` | Delay between inline commands |
| `--desc` | `-D` | — | Inline tape description metadata |
| `--tags` | `-T` | — | Inline tape tags |
| `--width` | — | `960` | Inline terminal width |
| `--height` | — | `480` | Inline terminal height |
| `--font-size` | — | `16` | Inline font size |
| `--playback-speed` | — | configured/default | Postprocess speed `1x|2x|4x|8x` |

### Behavior

- If commands are provided after `--`, `record` runs inline mode.
- In normal mode, `record` uses tape resolution rules (see below).
- `.tape.yml` paths run in sandbox mode: setup directives execute, scenes compile to VHS, and teardown cleanup runs.
- With `--dry-run`, output shows planned recording and attachment actions only.
- `--playback-speed` creates a `-<speed>` file and, when `--pr` is set, attaches that variant.

### Examples

```text
Recorded: .ace-local/demo/hello.gif
Tape: .ace-local/demo/i50jj3/my-demo.tape
Retimed: .ace-local/demo/hello-4x.gif (4x)
Uploaded: hello-1700000000.gif -> https://github.com/OWNER/REPO/releases/download/demo-assets/hello-1700000000.gif
Posted demo comment to PR #42
```

## `ace-demo retime <file>`

### Syntax

```bash
ace-demo retime .ace-local/demo/hello.gif --playback-speed 4x
ace-demo retime /tmp/demo.mp4 --playback-speed 2x --output /tmp/demo-2x.mp4
ace-demo retime .ace-local/demo/hello.gif --playback-speed 4x --dry-run
```

### Arguments

- `<file>` — input media file (`gif`, `mp4`, `webm`)

### Options

| Option | Alias | Required | Purpose |
|--------|-------|----------|---------|
| `--playback-speed` | — | Yes | Required speed (`1x|2x|4x|8x`) |
| `--output` | `-o` | No | Auto `-<speed>` suffix |
| `--dry-run` | `-n` | No | Show planned output without writing |

## `ace-demo attach <file> --pr <number>`

### Syntax

```bash
ace-demo attach .ace-local/demo/hello.gif --pr 42
ace-demo attach /tmp/hello.webm --pr 42 --dry-run
```

### Arguments

- `<file>` — recording file path |
- `--pr` — required PR number |

### Options

| Option | Alias | Required | Purpose |
|--------|-------|----------|---------|
| `--pr` | — | Yes | PR number |
| `--dry-run` | `-n` | No | Preview upload/comment only |

### Behavior

- Without `--pr`, command raises `PR number is required. Use --pr <number>.`
- `--dry-run` prints the would-be upload and comment body.

## Tape Discovery Order

When a tape name is used (not a direct path), `ace-demo` resolves in this order:

1. `./.ace/demo/tapes`
2. `~/.ace/demo/tapes`
3. `<gem_root>/.ace-defaults/demo/tapes`

## Commands to Run Without Full Reference

- `ace-demo --help`
- `ace-demo list`
- `ace-demo version`

## Troubleshooting

- **VHS not found**: install VHS (`https://github.com/charmbracelet/vhs`) and keep `chromium`/`ttyd` available for rendering.
- **gh not authenticated**: run `gh auth login` before `--pr` attachments.
- **Tape not found**: inspect search paths with `ace-demo list` and use a direct `.tape` path as a fallback.
