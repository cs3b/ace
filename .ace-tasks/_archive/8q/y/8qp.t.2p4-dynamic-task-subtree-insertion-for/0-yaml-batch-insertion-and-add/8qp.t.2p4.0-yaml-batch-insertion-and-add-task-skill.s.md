---
id: 8qp.t.2p4.0
status: done
priority: medium
created_at: "2026-03-27 10:43:47"
estimate: medium
dependencies: []
tags: [ace-assign, cli, skill]
parent: 8qp.t.2p4
bundle:
  presets: [project]
  files: [ace-assign/lib/ace/assign/cli/commands/add.rb, ace-assign/lib/ace/assign/organisms/assignment_executor.rb]
  commands: []
---

# YAML Batch Insertion and Add-Task Skill

## Objective

Enable `ace-assign add --from <file>` for batch step insertion from YAML, plus an `as-assign-add-task` agent skill for adding task subtrees to running assignments.

## Status: DONE

Delivered in ace-assign v0.38.0-v0.38.3 (PR #268).

### What Was Delivered

- `ace-assign add --from <file>` — batch inserts steps from a YAML file with `steps:` array
- `add_batch()` method on `AssignmentExecutor` with sequential insertion, metadata passthrough, `sub_steps` expansion
- CLI validation: `--from` and `name` mutual exclusivity, missing file/empty steps errors
- `added_by: "batch_from:<filename>"` audit metadata on all batch-inserted steps
- `as-assign-add-task` canonical skill + `wfi://assign/add-task` workflow
- Provider skill projections for Claude, Codex, Gemini, OpenCode, Pi
- 207 new test lines (add_command_test.rb + assignment_executor_test.rb)
- Docs updated: usage, getting-started, handbook

### Verification

- 488 tests, 1547 assertions, 0 failures (ace-assign)
- 7482 tests passed monorepo-wide
