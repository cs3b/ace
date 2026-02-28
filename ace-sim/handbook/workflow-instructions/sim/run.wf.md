---
name: sim/run
description: Run ace-sim simulation with preset, source, and provider configuration
argument-hint: "[--preset NAME] [--source PATH] [--provider PROVIDER]"
allowed-tools: Read, Bash, TodoWrite
update:
  frequency: on-change
  last-updated: '2026-02-28'
---

# Simulation Run Workflow

## Goal

Run a simulation against a source document using a preset, then review the synthesis results (suggestions report and revised source).

## Arguments

- `--preset`: Preset name (optional). Available presets:
  - `validate-task` — steps: plan, work (synthesis: `wfi://task/review`)
  - `validate-idea` — steps: draft, plan, work (synthesis: `wfi://idea/review`)
- `--source`: Source markdown file path (required unless preset defines a default source)
- `--provider`: Provider:model override (repeatable). Examples: `google:flash-preview`, `google:pro-preview`
- `--synthesis-provider`: Provider:model for final synthesis. Example: `claude:haiku`
- `--dry-run`: Preview what would run without executing

## Instructions

### Step 1: Resolve Source

If the source is a task number or multiple files, use `ace-bundle` to merge into a single file:

```bash
# Single task
ace-bundle task:148 --output /tmp/sim-source.md

# Already a single file — use directly
# --source path/to/spec.md
```

If `--source` points to an existing file, use it directly.

### Step 2: Run Simulation

Execute `ace-sim run` with the resolved source and any overrides.

```bash
# With preset (defaults)
ace-sim run --preset validate-task --source path/to/source.md

# With provider override
ace-sim run --preset validate-task --source path/to/source.md --provider google:flash-preview

# With synthesis provider override
ace-sim run --preset validate-task --source path/to/source.md --synthesis-provider google:pro-preview

# Dry run — preview without executing
ace-sim run --preset validate-task --source path/to/source.md --dry-run
```

**Important for Claude Code**: Run with 10-minute timeout (600000ms) and wait for completion inline (not background). Simulations may take several minutes depending on step count and provider.

#### Execution Guard (Mandatory)

- Completion is defined by **process exit** (success or failure), not by partial output.
- Do **not** treat temporary silence/no new output as completion.
- Do **not** run any Step 3+ commands until Step 2 process exit is confirmed.
- If 10-minute timeout (600000ms) is reached, report timeout and last observed output, then stop dependent steps.

Wait for the simulation process to exit. Note the **Run Dir** path from the output.

### Step 3: Review Results

After successful completion, read the synthesis output files from the run directory:

```bash
# Read the suggestions report
Read: <run-dir>/final/suggestions.report.md

# Read the revised source document
Read: <run-dir>/final/source.revised.md
```

The run directory structure:
```
<run-dir>/
  chains/          # Individual chain execution outputs
  final/
    suggestions.report.md   # Synthesis report with findings
    source.revised.md       # Revised source incorporating suggestions
```

### Step 4: Present Summary

Summarize the simulation findings to the user:

1. **Run metadata** — preset, providers, step count, run directory
2. **Key findings** — top suggestions from the synthesis report
3. **Revised source highlights** — notable changes in the revised document
4. **Recommended actions** — what to do with the results (apply changes, re-run with different providers, etc.)

## Quick Reference

```bash
# List available presets
ace-sim run --help

# Validate a task spec
ace-sim run --preset validate-task --source path/to/task-spec.md

# Validate an idea
ace-sim run --preset validate-idea --source path/to/idea.md

# Override providers
ace-sim run --preset validate-task --source spec.md --provider google:flash-preview --provider google:pro-preview

# Dry run
ace-sim run --preset validate-task --source spec.md --dry-run
```

## Success Criteria

- [ ] Simulation completed without errors
- [ ] Synthesis report reviewed (`final/suggestions.report.md`)
- [ ] Revised source reviewed (`final/source.revised.md`)
- [ ] Key findings summarized to user
