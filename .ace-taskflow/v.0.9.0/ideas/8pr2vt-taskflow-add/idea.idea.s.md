---
title: Add Multi-File Input Support to ace-sim via ace-bundle Integration
filename_suggestion: feat-sim-multi-input-bundle
enhanced_at: 2026-02-28 01:55:21
location: active
llm_model: pi:glm
---

# Add Multi-File Input Support to ace-sim via ace-bundle Integration

## What I Hope to Accomplish
Enable ace-sim to process multiple input files as a single simulation context, allowing users to run simulations against task hierarchies (parent + subtasks), entire directories, or glob patterns. This leverages ace-bundle's existing glob handling and context-packing capabilities to provide unified multi-file input support.

## What "Complete" Looks Like
- ace-sim CLI accepts multiple input paths: `ace-sim path/to/task.md path/to/subtasks/*.md`
- ace-sim supports glob patterns directly: `ace-sim .ace-taskflow/v.0.9.0/291/**`
- `--bundle` flag or similar option packs folder contents via ace-bundle before simulation
- Task hierarchies are processed with parent context inherited by subtasks
- Output clearly distinguishes results per input file or presents unified synthesis for batch mode
- ATOM architecture: new Organism orchestrates ace-bundle molecule calls + existing simulation pipeline

## Success Criteria
- `ace-sim .ace-taskflow/v.0.9.0/291/*.md` processes all matching task files
- `ace-sim --bundle .ace-taskflow/v.0.9.0/291/` packs folder via ace-bundle then simulates
- Subtask simulations have access to parent task context without manual specification
- Existing single-file simulation behavior unchanged (backward compatible)
- E2E test covers multi-file scenario with task + subtasks

---

## Original Idea

```
ace-sim should handle the multi file inputs (e.g.: tasks with subtasks, or even the whole folder, glob - use ace-bundle to pack whole folder) generally the ace-bundle handle globs)
```