---
id: 8xh.t.z14
status: in-progress
priority: medium
created_at: "2026-10-18 23:21:15"
estimate: TBD
dependencies: []
tags: []
bundle:
  presets: [project]
  files: [ace-herdr/docs/usage.md, ace-lab/docs/usage.md]
  commands: []
worktree:
  branch: z14-fold-l7-statuses-refinements-into-main
  path: .ace-wt/ace-t.z14
  created_at: "2026-10-19 00:21:39"
  updated_at: "2026-10-19 00:21:39"
  target_branch: main
---

# Fold l7-statuses refinements into main

## Objective

PR #382 (`l7-statuses`) delivered task 8xg.t.sbz.6.0, but PR #383 merged a
parallel implementation of the same L7.1 status feature first, leaving #382
conflicting and redundant. The #382 branch nevertheless carries reviewed,
unique behavioral improvements that users on main do not have today. This task
extracts exactly those unique behaviors onto a fresh branch off main, delivers
them through a new PR, and closes #382 with an explanatory comment.

## Behavioral specification

### User experience

- Input: a developer runs `ace-herdr status` / `ace-lab status` on main.
- Process: the commands use the refined configuration cascade and state
  classification salvaged from `l7-statuses`.
- Output: correct tri-state classification (including the config cascade
  precedence fix from `4745fdf90`), `--workspace` scoping on
  `ace-herdr status`, and JSON output for the composed tree.

### Expected behavior

- `ace-lab status` classifies the lab configuration tri-state with the
  corrected config cascade precedence (local overrides correctly win over
  defaults; previously misclassified states are fixed).
- Missing canonical state locations are classified as missing, not conflated
  with other states.
- `ace-herdr status` supports `--workspace <id>` to scope the rendered tree
  to one workspace, and `--format json` emits the composed tree as JSON.
- A live-but-empty layout remains a valid state; an unreachable runtime is
  reported as an error, never as an empty layout.

### Interface contract

```bash
ace-herdr status                      # readable tree, all workspaces
ace-herdr status --workspace w1       # one workspace only
ace-herdr status --format json        # composed tree as JSON
ace-lab status                        # config tri-state + state locations
```

Error handling:
- Unreachable herdr runtime → error exit, never an empty layout.
- Unknown workspace id → concrete error naming the workspace.

Edge cases:
- Live but empty workspace/tab set renders as a valid empty tree.
- Custom lab config cascade (non-default `hitl`/lab config locations) is
  classified through the corrected precedence.

### Success criteria

- The unique behavioral deltas of `l7-statuses` (config cascade precedence
  fix, `--workspace` scoping, JSON tree, missing-state classification) exist
  on main after the new PR merges, with regression tests.
- No duplication with the #383 implementation: obsolete/conflicting variants
  are replaced, not layered (pre-1.0, ADR-024).
- Version/CHANGELOG entries are appended on top of the already-released
  herdr 0.7.0 / lab 0.11.0 (no double-bump, no duplicated entries).
- PR #382 is closed with a comment explaining the supersession and pointing
  to #383 and the new PR.
- `bin/ace-test ace-herdr all`, `bin/ace-test ace-lab all`, and
  `bin/ace-test-suite` pass.

### Validation questions

(None — user approved the extraction plan directly.)

## Vertical slice decomposition (task/subtask model)

- Slice type: standalone task.
- Slice outcome: main gains the unique reviewed refinements; PR #382 closed
  with explanation.
- Advisory size: medium (cross-package but well-understood diff).

## Verification plan

### Unit/component validation

- Config cascade precedence: local config overrides defaults — expected
  classification respects precedence.
- Missing-state classification: absent canonical locations → "missing".

### Integration/e2e validation

- `ace-herdr status --workspace` scopes the tree; JSON output round-trips.

### Failure/invalid path validation

- Unreachable runtime → error, not empty layout.
- Unknown `--workspace` id → concrete error.

### Verification commands

- `bin/ace-test ace-herdr all` → 0 failures
- `bin/ace-test ace-lab all` → 0 failures
- `bin/ace-test-suite` → 0 failed

## Scope of work

- Extract unique deltas from `origin/l7-statuses` vs main into a new branch
  on a separate worktree.
- Append CHANGELOG/version bumps as needed without duplicating #383 entries.
- New PR, independent review, merge.
- Close PR #382 with explanatory comment referencing #383 and the new PR.

## Out of scope

- Re-merging PR #382 itself.
- Any new status features beyond what `l7-statuses` already contains.
- CI hardening.

## References

- Superseded PR: https://github.com/cs3b/ace/pull/382
- Merged wave containing the baseline implementation: PR #383
- Source branch: `origin/l7-statuses` (last commit `c9bddfdc3`)
