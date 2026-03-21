---
doc-type: reference
title: ace-demo Usage Guide
purpose: CLI usage guide for ace-demo — VHS-based terminal demo recording and PR attachment.
ace-docs:
  last-updated: 2026-03-08
  last-checked: 2026-03-21
---

# ace-demo Usage Guide

## Document Type: How-To Guide + Reference

## Overview

`ace-demo` records terminal command demos using VHS tape scripts and optionally attaches the resulting GIF to GitHub pull requests. It enables developers and AI agents to provide visual proof of feature functionality directly in PRs.

**Key Features:**
- Run VHS `.tape` scripts to produce deterministic GIF/MP4/WebM recordings
- Post-process existing recordings into faster playback variants with `retime`
- Resolve tape files via config cascade (built-in presets, user, project, direct path)
- Upload recordings to GitHub release assets for stable URLs
- Post PR comments with inline embedded demo GIFs
- Discover and inspect available tape presets with `list` / `show`
- Create new tape files from shell commands with `create`

**Prerequisite:** [VHS](https://github.com/charmbracelet/vhs) must be installed for recording. `gh` CLI must be authenticated for PR attachment.

---

## Quick Start (5 minutes)

```bash
# Record the built-in hello preset
ace-demo record hello
# Output: Recorded: .ace-local/demo/hello.gif

# List available tape presets
ace-demo list
# Output:
#   Available demo tapes:
#   hello     Built-in echo demo  (built-in)
#   ace-test  Run ace-test demo   (built-in)

# Record and attach to a PR in one step
ace-demo record ace-test --pr 42
# Output:
#   Recorded: .ace-local/demo/ace-test.gif
#   Uploaded: ace-test.gif -> https://github.com/.../releases/assets/...
#   Posted demo comment to PR #42
```

---

## Common Scenarios

### Scenario 1: Record a demo from a preset tape

**Goal**: Record the built-in `hello` tape to a GIF.

```bash
ace-demo record hello
```

**Expected output:**
```
Recorded: .ace-local/demo/hello.gif
```

### Scenario 2: Record a custom tape file

**Goal**: Use your own `.tape` file.

```bash
ace-demo record ./my-feature.tape
```

**Expected output:**
```
Recorded: .ace-local/demo/my-feature.gif
```

### Scenario 3: Record with a specific format and output path

**Goal**: Produce an MP4 at a custom location.

```bash
ace-demo record hello --format mp4 --output /tmp/hello-demo.mp4
```

**Expected output:**
```
Recorded: /tmp/hello-demo.mp4
```

### Scenario 4: Attach an existing GIF to a PR

**Goal**: Upload a pre-recorded GIF and post it as a PR comment.

```bash
ace-demo attach .ace-local/demo/hello.gif --pr 99
```

**Expected output:**
```
Uploaded: hello.gif -> https://github.com/.../releases/assets/12345
Posted demo comment to PR #99
```

### Scenario 5: Record + attach in one step

**Goal**: Record a demo and immediately post it to a PR.

```bash
ace-demo record ace-test --pr 123
```

**Expected output:**
```
Recorded: .ace-local/demo/ace-test.gif
Uploaded: ace-test.gif -> https://github.com/.../releases/assets/12346
Posted demo comment to PR #123
```

### Scenario 6: Preview without posting (dry run)

**Goal**: See what would be uploaded without actually posting.

```bash
ace-demo attach .ace-local/demo/hello.gif --pr 99 --dry-run
```

**Expected output:**
```
[dry-run] Would upload: hello.gif
[dry-run] Would post comment to PR #99:
![hello demo](...) ...
```

### Scenario 7: Create a tape from shell commands

**Goal**: Generate a `.tape` file from a list of commands.

```bash
ace-demo create my-demo -- "git status" "make deploy"
```

**Expected output:**
```
Created: .ace/demo/tapes/my-demo.tape
```

### Scenario 8: Create a tape with metadata

**Goal**: Add description and tags to a generated tape.

```bash
ace-demo create my-demo --desc "Deploy flow" --tags ci -- "git status" "make deploy"
```

### Scenario 9: Preview a tape without writing

**Goal**: See what would be generated without creating a file.

```bash
ace-demo create my-demo --dry-run -- "echo hello"
```

### Scenario 10: Create a tape from stdin

**Goal**: Pipe commands from a file or other command.

```bash
echo "git status" | ace-demo create stdin-demo
cat commands.txt | ace-demo create from-file
```

### Scenario 11: Discover and inspect tapes

**Goal**: Find available presets and see tape contents before recording.

```bash
# List all tapes
ace-demo list

# Inspect a specific tape
ace-demo show hello
```

**Expected output (show):**
```
Tape: hello
Source: .ace/demo/tapes/hello.tape
Description: Built-in echo demo

--- Contents ---
Output .ace-local/demo/hello.gif
...
```

### Scenario 12: Record inline (without a pre-written tape)

**Goal**: Generate a tape on-the-fly from shell commands, then record it immediately.

```bash
ace-demo record my-demo -- "git status" "make deploy"
```

**Expected output:**
```
Recorded: .ace-local/demo/i50jj3/my-demo.gif
Tape: .ace-local/demo/i50jj3/my-demo.tape
```

### Scenario 13: Preview inline tape without recording (dry-run)

**Goal**: See what tape would be generated without executing VHS.

```bash
ace-demo record my-demo --dry-run -- "echo hello"
```

**Expected output:** tape content printed to stdout, no VHS execution.

### Scenario 14: Pass parameters to a tape via environment variables

**Goal**: Record a tape that uses `$VAR` placeholders, supplying values at runtime.

```bash
TEST_PATH=ace-bundle ace-demo record test
```

Environment variables are inherited by the VHS process and its shell session, so `$TEST_PATH` in a `Type` directive expands when the command runs inside the recording:

```
# .ace/demo/tapes/test.tape
Type "ace-test $TEST_PATH"
```

This is the only parameter mechanism — VHS has no native argument system. Any env var set in the calling shell is available inside the tape.

---

## Command Reference

### `ace-demo record <tape>`

Record a terminal demo from a VHS tape file.

**Syntax:**
```bash
ace-demo record <tape> [--output <path>] [--format gif|mp4|webm] [--pr <number>] [--dry-run]
ace-demo record <name> -- <command>... [inline options]
echo "<command>" | ace-demo record <name> [inline options]
```

**Parameters:**
- `<tape>`: Tape preset name (e.g. `hello`) or direct file path (e.g. `./my.tape`)
- `<name>` (inline mode): Base name for generated tape and recording; sanitized to a filesystem-safe slug; output goes to `.ace-local/demo/<b36ts>/<name>.gif`

**Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--output` | `-o` | Output file path | `.ace-local/demo/<name>.<format>` |
| `--format` | `-f` | Output format: `gif`, `mp4`, `webm` | `gif` |
| `--pr` | | PR number to attach recording to | (none) |
| `--dry-run` | `-n` | Preview without recording or posting | `false` |
| `--timeout` | `-t` | Wait time after each command (inline mode) | `2s` |
| `--desc` | `-D` | Description metadata (inline mode) | (none) |
| `--tags` | `-T` | Comma-separated tags (inline mode) | (none) |
| `--width` | | Terminal width in pixels (inline mode) | `960` |
| `--height` | | Terminal height in pixels (inline mode) | `480` |
| `--font-size` | | Font size (inline mode) | `16` |
| `--playback-speed` | | Postprocess speed: `1x`, `2x`, `4x`, `8x` | (none) |

**Examples:**
```bash
ace-demo record hello                                       # → .ace-local/demo/hello.gif
ace-demo record hello --format mp4                          # → .ace-local/demo/hello.mp4
ace-demo record hello --output /tmp/demo.gif                # → /tmp/demo.gif
ace-demo record hello --playback-speed 4x                   # + hello-4x.gif
ace-demo record ace-test --pr 123                           # record + attach to PR
ace-demo record ace-test --pr 123 --dry-run                 # preview only
ace-demo record my-demo -- "git status" "make deploy"       # inline → session dir
ace-demo record my-demo --dry-run -- "echo hello"           # preview tape content
echo "echo hello" | ace-demo record my-demo                 # stdin
TEST_PATH=ace-bundle ace-demo record test                   # pass env var to tape
ace-demo retime .ace-local/demo/hello.gif --playback-speed 8x
```

**Environment variables:** all env vars in the calling shell are inherited by VHS and its shell session. Use `$VAR` in `Type` directives within `.tape` files to reference them.

**Inline mode output:**
```
Recorded: .ace-local/demo/<session-id>/<name>.gif
Tape: .ace-local/demo/<session-id>/<name>.tape
```

When playback postprocess is active (via `--playback-speed` or config), `record` keeps the original output and generates an additional `-<speed>` variant (for example `hello-4x.gif`). If `--pr` is used, the retimed file is attached.

**Exit codes:**
- `0`: Recording (and attachment) succeeded
- `1`: VHS not found, tape not found, VHS execution error, or PR/upload error

---

### `ace-demo attach <file>`

Attach an existing demo recording to a GitHub PR.

**Syntax:**
```bash
ace-demo attach <file> --pr <number> [--dry-run]
```

**Parameters:**
- `<file>`: Path to the recording file (GIF, MP4, or WebM)

**Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--pr` | | PR number (required) | — |
| `--dry-run` | `-n` | Preview comment without posting | `false` |

**Examples:**
```bash
ace-demo attach .ace-local/demo/hello.gif --pr 45
ace-demo attach /tmp/feature-demo.gif --pr 45 --dry-run
```

---

### `ace-demo list`

List all discoverable demo tapes (built-in, user, and project).

**Syntax:**
```bash
ace-demo list
```

**Expected output:**
```
Available demo tapes:
  hello     Built-in echo demo   (.ace/demo/tapes/)
  ace-test  Run ace-test demo    (.ace/demo/tapes/)
```

---

### `ace-demo show <tape>`

Display metadata and full contents of a tape file.

**Syntax:**
```bash
ace-demo show <tape>
```

**Parameters:**
- `<tape>`: Tape preset name or direct `.tape` file path

**Expected output:**
```
Tape: hello
Source: .ace/demo/tapes/hello.tape
Description: Built-in echo demo
Tags: example, getting-started

--- Contents ---
Output .ace-local/demo/hello.gif
...
```

---

### `ace-demo create <name>`

Create a new demo tape from shell commands.

**Syntax:**
```bash
ace-demo create <name> [options] -- <command>...
ace-demo create <name> [options] < commands.txt
```

**Parameters:**
- `<name>`: Tape name (used as filename, saved to `.ace/demo/tapes/<name>.tape`)

**Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--desc` | `-D` | Description metadata | (none) |
| `--tags` | `-T` | Comma-separated tags | (none) |
| `--width` | | Terminal width in pixels | `960` |
| `--height` | | Terminal height in pixels | `480` |
| `--font-size` | | Font size | `16` |
| `--timeout` | `-t` | Wait time after each command | `2s` |
| `--format` | `-f` | Output format: `gif`, `mp4`, `webm` | `gif` |
| `--force` | | Overwrite existing tape | `false` |
| `--dry-run` | `-n` | Preview without writing | `false` |

**Examples:**
```bash
ace-demo create my-demo -- "git status" "make deploy"
ace-demo create my-demo --desc "Deploy flow" --tags ci -- "git status"
ace-demo create my-demo --dry-run -- "echo hello"
echo "git status" | ace-demo create stdin-demo
```

**Exit codes:**
- `0`: Tape created (or dry-run preview shown)
- `1`: No commands provided, or tape already exists

---

### `ace-demo retime <file>`

Create a faster playback variant from an existing recording file.

**Syntax:**
```bash
ace-demo retime <file> --playback-speed <1x|2x|4x|8x> [--output <path>] [--dry-run]
```

**Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--playback-speed` | | Target speed: `1x`, `2x`, `4x`, `8x` | — |
| `--output` | `-o` | Output file path | `<input>-<speed>.<ext>` |
| `--dry-run` | `-n` | Preview without writing | `false` |

**Examples:**
```bash
ace-demo retime .ace-local/demo/hello.gif --playback-speed 4x
ace-demo retime /tmp/demo.mp4 --playback-speed 8x --output /tmp/demo-fast.mp4
```

---

## Configuration

### Tape Discovery Cascade

Tapes are resolved in this order (first match wins):

1. Direct file path (e.g. `./custom.tape`)
2. `.ace/demo/tapes/` — project-specific overrides (committed)
3. `~/.ace/demo/tapes/` — user-wide presets
4. `.ace-defaults/demo/tapes/` — built-in gem tapes

### Built-in Tapes

| Name | Description |
|------|-------------|
| `hello` | Minimal echo demo |
| `ace-test` | Demonstrates `ace-test` run |

### Adding Project Tapes

Place `.tape` files in `.ace/demo/tapes/` with optional metadata comments:

```
# Description: Demo of my-feature command
# Tags: feature, v2

Output .ace-local/demo/my-feature.gif
Set FontSize 14

Type "my-command --help"
Enter
Sleep 2s
```

### Output Directory

Recordings default to `.ace-local/demo/`. The directory is created automatically if missing.

### Record Postprocess Defaults

Configure automatic retime after `record` in `.ace/demo/config.yml`:

```yaml
record:
  postprocess:
    playback_speed: 4x
```

CLI `--playback-speed` overrides this value for a single command.

---

## Troubleshooting

### Problem: VHS not found

**Symptom:**
```
Error: VHS not found. Install: https://github.com/charmbracelet/vhs
```

**Solution:** Install VHS following the [official instructions](https://github.com/charmbracelet/vhs).

---

### Problem: Tape not found

**Symptom:**
```
Error: Tape not found: nonexistent
Searched: .ace-defaults/demo/tapes/, ~/.ace/demo/tapes/, .ace/demo/tapes/
```

**Solution:** Run `ace-demo list` to see available preset names, or pass a direct `.tape` file path.

---

### Problem: gh CLI not authenticated

**Symptom:**
```
Error: gh CLI authentication failed. Run: gh auth login
```

**Solution:**
```bash
gh auth login
```

---

### Problem: PR does not exist

**Symptom:**
```
Error: PR #999 not found in this repository.
```

**Solution:** Verify the PR number with `gh pr list`.

---

### Problem: GIF too large for GitHub comment

**Symptom:** Comment renders broken or upload is rejected.

**Solution:** Use `--format webm` for smaller file sizes:
```bash
ace-demo record hello --format webm --pr 123
```

---

## Best Practices

1. **Use presets over ad-hoc paths**: Put reusable tapes in `.ace/demo/tapes/` so the team can run them by name.
2. **Record GIFs for screenshots**: GIFs embed directly in PR comments — prefer over MP4 for visibility.
3. **Dry-run before posting**: Use `--dry-run` to preview the comment before it appears in the PR.
4. **Keep tapes short**: Aim for <30s recordings. Longer tapes produce large files and slow CI.
5. **Add metadata comments**: Use `# Description:` and `# Tags:` in tape files for `ace-demo list` discoverability.