---
doc-type: workflow
title: Create Demo Tape Workflow
purpose: tape creation workflow instruction
ace-docs:
  last-updated: 2026-03-05
  last-checked: 2026-03-21
---

# Create Demo Tape Workflow

## Purpose

Create or update VHS demo tapes using `ace-demo create`. Tapes are stored in `.ace/demo/tapes/` and define terminal recordings as reproducible scripts.

## Context

Tapes are VHS script files that define terminal sessions: commands to type, timing, and display settings. Once created, tapes can be recorded with `ace-demo record`.

**Tape discovery cascade** (highest to lowest priority):
1. Direct file path
2. `.ace/demo/tapes/` — project-specific (committed)
3. `~/.ace/demo/tapes/` — user-wide
4. `.ace-defaults/demo/tapes/` — built-in

## Variables

- `$ARGUMENTS`: Tape name, options, and commands (everything after `--`)

## Instructions

1. **Preview the tape** before writing:

   ```bash
   ace-demo create <name> --dry-run -- "cmd1" "cmd2"
   ```

   This prints the generated tape content without writing any file.

2. **Create the tape**:

   ```bash
   ace-demo create <name> -- "cmd1" "cmd2"
   ```

   Add metadata for discoverability:
   ```bash
   ace-demo create <name> --desc "What this demo shows" --tags "feature,setup" -- "cmd1" "cmd2"
   ```

3. **Update an existing tape** (overwrite):

   ```bash
   ace-demo create <name> --force -- "cmd1" "cmd2"
   ```

4. **Verify** the created tape:

   ```bash
   ace-demo show <name>
   ```

   This displays metadata and full tape contents.

5. **List all available tapes** to confirm visibility:

   ```bash
   ace-demo list
   ```

## Options Reference

| Option | Description |
|--------|-------------|
| `--desc/-D <text>` | Description metadata |
| `--tags/-T <tags>` | Comma-separated tags |
| `--format/-f <fmt>` | Output format: gif, mp4, webm (default: gif) |
| `--timeout/-t <dur>` | Wait time after each command (default: 2s) |
| `--width <px>` | Terminal width in pixels (default: 960) |
| `--height <px>` | Terminal height in pixels (default: 480) |
| `--font-size <n>` | Font size (default: 16) |
| `--force` | Overwrite existing tape |
| `--dry-run/-n` | Preview content without writing |

## Success Criteria

- Tape file created at `.ace/demo/tapes/<name>.tape`
- `ace-demo show <name>` displays correct metadata and commands
- `ace-demo list` shows the new tape