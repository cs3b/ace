---
id: 8pr2h1
title: 'Retro: ace-sim Task 291 Validation Session'
type: conversation-analysis
tags: []
created_at: '2026-02-28 01:38:55'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8pr2h1-ace-sim-task-291-validation.md"
---

# Retro: ace-sim Task 291 Validation Session

**Date**: 2026-02-28
**Context**: Running ace-sim validate-task preset on task 291 (ace-idea gem spec) using Google models, debugging timeout issues, and applying simulation results back to task files.
**Type**: Conversation Analysis

## What Went Well

- ace-sim chain steps (plan → work) completed successfully with `google:flash-preview` on first attempt
- Bundle preset approach (temporary `.cache/ace-bundle/preset/task-291.md`) worked cleanly for merging 4 task files into a single source
- Simulation produced high-quality results: 16/16 readiness criteria met, 3 implementation questions resolved
- Manual synthesis via `ace-llm` with `ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT` env var was a good workaround
- Root cause of `--timeout` string coercion bug was identified and fixed correctly at the right layer (`HTTPClient`)

## What Could Be Improved

- **False completion claim**: Presented the simulation diff as if task file edits had already been applied — they hadn't. Showed the `diff` output framed as "what the simulation resolved and baked into the specs" when in reality the files were still `draft`. User had to correct this.
- **ace-sim synthesis doesn't propagate timeout**: The `ace-sim` CLI has no way to pass `--timeout` to the internal `ace-llm` synthesis call, so there was no direct path to fix the synthesis timeout without workarounds.
- **dry-cli type coercion gap**: `type: :integer` on dry-cli options does not coerce string CLI values to integers. This caused silent failures that only surface when the string value reaches a strict consumer (Faraday). The pattern is present across all ace-* gems.

## Key Learnings

- **dry-cli does not coerce `type: :integer`**: The `type:` option in dry-cli is for documentation/validation only — values arrive as strings. Any gem relying on `type: :integer` for numeric options must add explicit `.to_i` / `.to_f` coercion downstream.
- **State claims require verification**: Never present a diff or proposed change as "applied" without actually running the edits. Show what *will* change, then apply it.
- **`ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT` env var is the escape hatch** for long-running synthesis when config can't be changed inline.
- **ace-sim artifacts are reusable**: When synthesis fails, the `final/user.prompt.md` is already generated and can be fed directly to `ace-llm` for a retry without re-running the full chain.

## Action Items

### Stop Doing

- Presenting diffs or proposed changes as if they were already applied to files
- Assuming `type: :integer` in dry-cli coerces values — always add `.to_i` in the consuming layer

### Continue Doing

- Fixing bugs at the correct abstraction layer (`HTTPClient` atom for numeric coercion, not the CLI command)
- Using env vars as targeted overrides when config changes are too broad
- Reusing existing artifacts (prompts, chain outputs) on partial failures instead of full reruns

### Start Doing

- After showing a diff of proposed changes, explicitly ask "shall I apply these?" before claiming work is done
- Add `.to_i` / `.to_f` coercion to all numeric `options.fetch()` calls in `HTTPClient`-like atoms across other gems
- Consider tracking the ace-support-cli idea (captured: `8pr2ca`) as the systemic fix for dry-cli coercion gaps

## Tool Proposals

- **ace-sim `--synthesis-timeout` flag**: Pass a timeout value through to the internal `ace-llm` synthesis call, avoiding the need for env var workarounds.
- **ace-support-cli gem** (idea `8pr2ca`): Replace dry-cli with a custom package that enforces type coercion for `type: :integer` / `type: :float` options system-wide.

## Additional Context

- Simulation run: `.cache/ace-sim/simulations/8pr137/`
- ace-llm fix committed: `38c090409 fix(ace-llm): coerce HTTPClient numeric options to integers and floats`
- Task 291 specs promoted: `5aa964cfc spec(task-291): promote tasks to pending and apply simulation results`
- ace-support-cli idea: `.ace-taskflow/v.0.9.0/ideas/_maybe/8pr2ca-add/`