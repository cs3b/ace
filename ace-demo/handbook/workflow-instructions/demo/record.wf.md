---
doc-type: workflow
title: Record Demo Workflow
purpose: demo recording workflow instruction
ace-docs:
  last-updated: 2026-03-08
  last-checked: 2026-03-21
---

# Record Demo Workflow

## Purpose

Record terminal demos using `ace-demo record`. Supports two modes: tape-based recording from existing `.tape` files, and inline recording from ad-hoc commands. Optionally postprocesses playback speed and attaches the result to a GitHub PR.

## Context

**Two recording modes:**
- **Tape mode**: Records from an existing tape file (created with `ace-demo create` or manually)
- **Inline mode**: Generates a temporary tape from commands passed after `--`

**Output** goes to `.ace-local/demo/` (tape mode) or `.ace-local/demo/<session-id>/` (inline mode).

**PR attachment** uploads the recording to a `demo-assets` GitHub release and posts a comment with the embedded demo.

## Variables

- `$ARGUMENTS`: Tape reference or demo name, optional PR number, optional inline commands

## Instructions

### Validate the Recording Contract First

Before choosing tape mode vs inline mode, lock these points:

- **What is the user-visible behavior?**
- **What screen or tmux client must the reviewer be looking at to see it?**
- **What setup can happen off-camera so the recording starts at the meaningful baseline?**

If the feature is about visible tmux behavior such as opening a pane, switching windows, or showing a running fork in the current session:

- record the tmux client view that will actually show that transition
- do not treat a shell transcript as sufficient proof
- start from the operator's normal work window unless the feature is specifically about attach/reattach behavior
- prefer showing the transition directly over showing commands that reconstruct the state later

### Record from Existing Tape

The tape argument accepts a **preset name** (from `ace-demo list`) or a **direct file path** to a `.tape` or `.tape.yml` file.

For demos that serve as durable evidence, prefer a committed `.tape.yml` so the generated `.cast` can be verified again with `ace-demo verify`.

1. **Find available tapes**:

   ```bash
   ace-demo list
   ```

2. **Preview** (dry-run skips recording):

   ```bash
   ace-demo record <tape-name> --dry-run
   ```

3. **Record by preset name or file path**:

   ```bash
   # By preset name
   ace-demo record <tape-name>

   # By direct file path (YAML tape)
   ace-demo record path/to/tape.tape.yml
   ```

4. **Record with custom format or output**:

   ```bash
   ace-demo record <tape-name> --format mp4 --output path/to/output.mp4
   ace-demo record path/to/tape.tape.yml --output path/to/output.gif
   ```

5. **Preflight the camera contract for state-transition demos**:

   Ask these questions before recording:

   - Does the first part of the recording show the baseline state the reviewer needs?
   - Will the trigger action happen on camera?
   - Will the visible system reaction happen on camera?
   - If the feature is tmux-related, will the recording clearly show the tmux window/pane/session change rather than only a later shell prompt?

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

### Postprocess Playback Speed

Generate both original and retimed outputs:

```bash
ace-demo record hello --playback-speed 4x
```

Postprocess existing files directly:

```bash
ace-demo retime .ace-local/demo/hello.gif --playback-speed 8x
```

Config default (auto postprocess on `record`):

```yaml
record:
  postprocess:
    playback_speed: 4x
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
| `--playback-speed <speed>` | Postprocess speed: `1x`, `2x`, `4x`, `8x` |

## Verification and Recovery

For YAML/asciinema demos, recording is not complete when the GIF exists. The cast must pass semantic verification.

Use tape `verify:` rules to express:
- required exported variables (`require_vars`)
- forbidden output/error signatures (`forbid_output`)
- final-state assertions (`assert_commands`)

After recording:

1. If verification passes, continue normally.
2. If verification fails with `scenario_defect`:
   - inspect the generated report in `.ace-local/demo/`
   - run `ace-demo verify <cast> --tape <tape>` again if needed
   - fix the tape instructions, viewpoint, or setup contract
   - retry recording once
3. If verification fails with `product_bug`:
   - stop
   - keep the generated report in `.ace-local/demo/`
   - run the cast-analysis workflow and treat it as a real code/runtime bug
4. Never upload or comment on a PR when verification is not a true pass.
5. For any non-pass result, branch through `wfi://demo/analyze-cast` before re-recording.

### Additional Validation for UX / Tmux Demos

Even when the recorder succeeds technically, reject the demo and re-record if any of these are true:

- the recording starts after the important state change already happened
- the recording shows only setup and end state, not the visible transition
- a tmux/window/pane feature is represented only by status files or textual explanation
- the viewer cannot identify the operator window, trigger action, and resulting fork/window/pane state from the recording alone

## Success Criteria

- Recording file produced in `.ace-local/demo/` (plus optional retimed artifact)
- YAML/asciinema recordings pass semantic verification
- If `--pr` used: demo uploaded to `demo-assets` release and comment posted on PR only after verification passes
- If verification fails: error report written to `.ace-local/demo/`
- If `--dry-run`: preview printed, no side effects
- For UI/state-transition demos, the recording visibly shows `before -> trigger -> visible effect -> after` from the correct viewer perspective
