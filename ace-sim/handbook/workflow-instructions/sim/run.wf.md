---
doc-type: workflow
title: Simulation Run Workflow
purpose: Run ace-sim simulation with preset, source, and provider configuration
ace-docs:
  last-updated: 2026-02-28
  last-checked: 2026-03-21
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

# Task spec with usage context (recommended for validate-task)
ace-sim run --preset validate-task --source "path/to/task.s.md,path/to/ux/usage.md"

# Already a single file — use directly
# --source path/to/spec.md
```

If `--source` points to an existing file, use it directly.

If the source is a task with usage documentation (`ux/usage.md`), include both spec and usage files to give the simulation behavioral acceptance context.

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

### Step 4: Apply Validated Changes

After reviewing `source.revised.md`, apply the validated refinements back to the
original source files. The simulation output is only useful if it feeds back into
the actual specs.

**When the source was a single file** — apply diffs directly using the Edit tool,
comparing `source.revised.md` against the original.

**When the source was bundled from multiple files** (e.g. merged task specs):
- Compare `source.revised.md` section by section against each original file
- Apply each relevant change to its correct source file using the Edit tool
- Common changes to propagate: status promotions, spec refinements, new error
  messages, updated success criteria, clarified edge cases

**Skip or flag for human decision:**
- Changes marked `[PENDING DECISION]` in the revised source
- Structural additions that don't have a clear home in the originals
- Questions from the suggestions report — surface these to the user instead

Do not commit yet — let the commit workflow handle that after review.

### Step 5: Present Summary

Summarize the simulation findings to the user:

1. **Run metadata** — preset, providers, step count, run directory
2. **Key findings** — top suggestions from the suggestions report
3. **Changes applied** — which original files were updated and what changed
4. **Pending decisions** — any `[PENDING DECISION]` items needing human input
5. **Recommended actions** — next steps (commit, re-run with different providers, etc.)

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
- [ ] Validated changes applied back to original source files
- [ ] Pending decisions surfaced to user
- [ ] Key findings summarized to user