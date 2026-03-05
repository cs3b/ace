---
name: demo/record
allowed-tools: Bash, Read
description: Record terminal demos from VHS tapes or inline commands, optionally attach to PRs
argument-hint: "<tape|name> [--pr <number>] [-- commands...]"
doc-type: workflow
purpose: demo recording workflow instruction
update:
  frequency: on-change
  last-updated: '2026-03-05'
---

# Record Demo Workflow

## Purpose

Record terminal demos using `ace-demo record`. Supports two modes: tape-based recording from existing `.tape` files, and inline recording from ad-hoc commands. Optionally uploads and attaches the result to a GitHub PR.

## Context

**Two recording modes:**
- **Tape mode**: Records from an existing tape file (created with `ace-demo create` or manually)
- **Inline mode**: Generates a temporary tape from commands passed after `--`

**Output** goes to `.ace-local/demo/` (tape mode) or `.ace-local/demo/<session-id>/` (inline mode).

**PR attachment** uploads the recording to a `demo-assets` GitHub release and posts a comment with the embedded demo.

## Variables

- `$ARGUMENTS`: Tape reference or demo name, optional PR number, optional inline commands

## Instructions

### Record from Existing Tape

1. **Find available tapes**:

   ```bash
   ace-demo list
   ```

2. **Preview** (dry-run skips recording):

   ```bash
   ace-demo record <tape-name> --dry-run
   ```

3. **Record**:

   ```bash
   ace-demo record <tape-name>
   ```

4. **Record with custom format or output**:

   ```bash
   ace-demo record <tape-name> --format mp4 --output path/to/output.mp4
   ```

### Record Inline (Ad-Hoc Commands)

1. **Preview** generated tape content:

   ```bash
   ace-demo record my-demo --dry-run -- "git status" "ace-test atoms"
   ```

2. **Record**:

   ```bash
   ace-demo record my-demo -- "git status" "ace-test atoms"
   ```

   Inline options adjust display: `--width 1200 --height 600 --font-size 14 --timeout 3s`

### Attach to PR

Add `--pr <number>` to any record command to upload and post a comment:

```bash
ace-demo record <tape-name> --pr 235
ace-demo record my-demo --pr 235 -- "cmd1" "cmd2"
```

Preview attachment without recording or posting:

```bash
ace-demo record <tape-name> --pr 235 --dry-run
```

### Environment Variable Passing

Tapes using `$VAR` placeholders expand from the calling shell:

```bash
TEST_PATH=ace-bundle ace-demo record test
```

## Options Reference

| Option | Description |
|--------|-------------|
| `--output/-o <path>` | Custom output file path |
| `--format/-f <fmt>` | Output format: gif, mp4, webm (default: gif) |
| `--pr <number>` | Attach recording to this PR |
| `--dry-run/-n` | Preview without recording or posting |
| `--timeout/-t <dur>` | Wait time after each command — inline mode (default: 2s) |
| `--desc/-D <text>` | Description metadata — inline mode |
| `--tags/-T <tags>` | Comma-separated tags — inline mode |
| `--width <px>` | Terminal width — inline mode (default: 960) |
| `--height <px>` | Terminal height — inline mode (default: 480) |
| `--font-size <n>` | Font size — inline mode (default: 16) |

## Success Criteria

- Recording file produced in `.ace-local/demo/`
- If `--pr` used: demo uploaded to `demo-assets` release and comment posted on PR
- If `--dry-run`: preview printed, no side effects
