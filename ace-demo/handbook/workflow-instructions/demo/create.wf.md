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

1. **Define the demo contract before scripting anything**:

   Capture these decisions in notes or the task/PR before you create a tape:

   - **Viewpoint**: what exact terminal or tmux client is being recorded
   - **Starting state**: what must already be visible on screen before the trigger action
   - **Trigger action**: the concrete command or interaction that causes the behavior
   - **Visible reaction**: the system state change that must be seen in the recording
   - **End state**: what the reviewer should understand after the recording finishes

   For demos about tmux, panes, windows, or session routing, the contract must explicitly say which tmux client view is being recorded. A shell transcript alone is not sufficient if the feature is about visible tmux behavior.

2. **Keep setup off-camera unless setup is the feature**:

   Pre-stage long or distracting setup before recording whenever possible:

   - create fixtures, assignments, and helper scripts before the recording starts
   - start from the state the viewer must recognize
   - only leave setup on camera when the setup step itself is what the demo is proving

   For tmux fork/window demos, prefer starting in the operator's normal work window and let the recording capture the visible transition into the fork window. Do not begin already attached to the fork window unless the feature is specifically about that attach flow.

   If the demo is intended to be durable evidence for docs, review, or PR proof, prefer a committed `.tape.yml` / asciinema flow over ad-hoc inline/VHS capture so the resulting `.cast` can be re-verified later.

3. **Preview the tape** before writing:

   ```bash
   ace-demo create <name> --dry-run -- "cmd1" "cmd2"
   ```

   This prints the generated tape content without writing any file.

4. **Create the tape**:

   ```bash
   ace-demo create <name> -- "cmd1" "cmd2"
   ```

   Add metadata for discoverability:
   ```bash
   ace-demo create <name> --desc "What this demo shows" --tags "feature,setup" -- "cmd1" "cmd2"
   ```

5. **Update an existing tape** (overwrite):

   ```bash
   ace-demo create <name> --force -- "cmd1" "cmd2"
   ```

6. **Verify** the created tape:

   ```bash
   ace-demo show <name>
   ```

   This displays metadata and full tape contents.

7. **List all available tapes** to confirm visibility:

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
- The tape starts from the intended viewer-recognizable state instead of rebuilding irrelevant setup on camera
- For state-transition demos, the tape visibly shows `before -> trigger -> visible effect -> after`
