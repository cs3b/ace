---
doc-type: reference
title: ace-sim Usage Reference
purpose: Complete CLI reference for simulation runs and command behavior
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-sim Usage Reference

`ace-sim` runs provider simulations through configurable steps and presets.

## Command Overview

- `ace-sim` — entrypoint
- `ace-sim run` — run a simulation preset with one or more source files
- `ace-sim --help` — print command list and examples

## `ace-sim --help`

Shows command examples and the `run` subcommand.

## `ace-sim run`

### Syntax

```bash
ace-sim run [OPTIONS]
```

### Purpose

Execute a preset-driven simulation with source files, provider list, and optional final synthesis.

### Options

| Option | Type | Default / Source | Description |
|---|---|---|---|
| `--preset` | string | config `sim.default_preset` or `validate-idea` | Preset name from `.ace/sim/presets/*.yml|yaml` |
| `--source` | array | preset `source` | One or more source files (repeatable, supports globs) |
| `--steps` | string | preset steps | Comma-separated step names (override preset step list) |
| `--provider` | array | preset providers | Provider:model values (`--provider` may repeat) |
| `--repeat` | integer | sim default repeat (or `1`) | Run each provider this many times |
| `--synthesis-workflow` | string | preset / config | Workflow/file ref for final synthesis |
| `--synthesis-provider` | string | preset / config provider | Provider for final suggestions generation |
| `--dry-run` | flag | preset / false | Prepare and preview without mutating providers |
| `--writeback` | flag | preset / false | Write final revised source back to source when set |
| `--quiet`, `-q` | flag | false | Suppress non-essential status output |
| `--verbose`, `-v` | flag | false | Print extended diagnostics |
| `--help`, `-h` | flag | false | Show command help |

## Preset configuration model

- Presets are resolved by name.
- Preset loading precedence for files is:
  - gem defaults (`.ace-defaults/sim/presets`)
  - user presets (`~/.ace/sim/presets`)
  - project presets (`.ace/sim/presets`)

- File extensions: `.yml` and `.yaml`.

If a preset is missing but known, fallback behavior is an empty preset with default steps and the system-level defaults for provider/repeat behavior.

## Step config resolution

Each requested step is resolved in this order:

1. `.ace/sim/steps/<step>.md`
2. `~/.ace/sim/steps/<step>.md`
3. `.ace-defaults/sim/steps/<step>.md`

Run fails with `Missing step config` if a required step file is not found.

## Synthesis and precedence

- If `--synthesis-provider` is passed, that provider is used for final synthesis.
- If not passed, synthesis defaults use: preset `synthesis_provider`, then global config `sim.synthesis_provider`.
- `--synthesis-provider` requires `--synthesis-workflow` to be set.
- `--dry-run` is a non-mutating preview and cannot be combined with `--writeback`.

## Artifacts

Run output lives under `.ace-local/sim/simulations/<run-id>/`.

Run root:

- `session.yml` — simulation session metadata
- `synthesis.yml` — final synthesis status and summaries
- `input.md` — bundled source content used for provider execution
- `input.bundle.md` — source bundle manifest generated before execution

Per chain (`<provider>-<iteration>`):

- `NN-step/input.md` — effective input for that step
- `NN-step/user.bundle.md` — step bundle for LLM prompt
- `NN-step/user.prompt.md` — resolved prompt file
- `NN-step/output.md` — provider output for that step

Final directory:

- `final/input.md` — combined chain outputs
- `final/user.bundle.md` — final synthesis bundle
- `final/user.prompt.md` — final synthesis prompt
- `final/output.sequence.md` — raw LLM output sequence
- `final/suggestions.report.md` — parsed suggestions block
- `final/source.original.md` — original source snapshot
- `final/source.revised.md` — revised source output (if synthesis enabled)

## Behavior notes

- Steps run sequentially within each chain — each step's output becomes the next step's input, so later steps build on earlier reasoning.
- `draft`, `plan`, `work` are common defaults; custom step order is supported via `--steps`.
- After all chains complete, the synthesis stage gathers feedback from every stage to propose improvements and produce a revised source artifact.
- Synthesis is optional; enable via preset or explicit `--synthesis-workflow`.
- `--dry-run` does not perform provider calls.

## Troubleshooting

- `Unknown preset`:
  - verify preset exists under one of `.ace-defaults/sim/presets`, `~/.ace/sim/presets`, or `.ace/sim/presets`
- `Missing step config`:
  - verify step bundles exist in step search path above
- `--source is required`:
  - provide source files directly or via preset defaults
- `synthesis_provider requires synthesis_workflow`:
  - include both flags together when overriding synthesis provider
