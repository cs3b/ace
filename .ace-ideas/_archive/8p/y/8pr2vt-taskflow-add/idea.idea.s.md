---
title: Add Multi-File Input Support to ace-sim via ace-bundle Integration
filename_suggestion: feat-sim-multi-input-bundle
enhanced_at: 2026-02-28 01:55:21.000000000 +00:00
location: active
llm_model: pi:glm
simulation_verdict: READY_TO_DRAFT
status: done
completed_at: 2026-02-28 14:36:09.000000000 +00:00
id: 8pr2vt
tags: []
created_at: '2026-02-28 01:55:20'
---

# Add Multi-File Input Support to ace-sim via ace-bundle Integration

## What I Hope to Accomplish
Enable `ace-sim` to accept multiple files or glob patterns via the existing `--source` flag. When multiple files are detected, `ace-bundle` is invoked to merge them into a single `input.bundle.md` — the rest of the simulation pipeline runs unchanged. No new flags or variadic args: just extend `--source` to handle commas and globs.

## What "Complete" Looks Like

```bash
# Single file (unchanged)
ace-sim run --preset validate-task --source path/to/task.md

# Comma-separated files
ace-sim run --preset validate-task --source "path/to/parent.md,path/to/subtask.md"

# Glob pattern
ace-sim run --preset validate-task --source "tasks/291/**/*.md"
```

When `--source` resolves to more than one file, `ace-bundle` is called to merge them into `input.bundle.md`. That bundle file becomes the single input to the simulation chain — identical to the single-file path from that point on.

## Technical Decisions & Constraints
- **No new CLI flags**: `--source` is the only entry point; it accepts a single path, comma-separated paths, or a glob string.
- **Always bundle via ace-bundle**: Every `--source` value — single file, comma list, or glob — is passed to `ace-bundle` to produce `<run-dir>/input.bundle.md`. No special-casing for single files.
- **ace-bundle handles relative paths**: Paths are passed as-is (relative to project root); ace-bundle resolves them correctly.
- **`input.bundle.md` is the step-1 contract**: The simulation runtime always reads `input.bundle.md` as its first-step input — uniform regardless of how many source files were given.
- **Fail-fast**: If a glob matches zero files or any listed file is missing, ace-bundle will error; halt before the LLM is called.

## Success Criteria
- [ ] `--source "tasks/291/**/*.md"` bundles all matching files into `input.bundle.md` and runs as one simulation.
- [ ] `--source "parent.md,subtask.md"` bundles both files into `input.bundle.md` and runs as one simulation.
- [ ] `--source single.md` also goes through ace-bundle — `input.bundle.md` is always the step-1 input.
- [ ] Empty glob or missing file exits with non-zero status and clear error before LLM call.
- [ ] Frontmatter is stripped by ace-bundle; simulation chain receives clean markdown.

---

## Original Idea

```
ace-sim should handle the multi file inputs (e.g.: tasks with subtasks, or even the whole folder, glob - use ace-bundle to pack whole folder) generally the ace-bundle handle globs)
```