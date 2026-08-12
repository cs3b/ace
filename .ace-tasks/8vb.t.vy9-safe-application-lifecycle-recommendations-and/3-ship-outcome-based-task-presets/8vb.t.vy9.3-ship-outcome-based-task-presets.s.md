---
id: 8vb.t.vy9.3
status: draft
priority: high
created_at: "2026-08-12 21:18:23"
estimate: TBD
dependencies: [8vb.t.vy9.2]
tags: [assign, task-work, presets, delivery]
parent: 8vb.t.vy9
bundle:
  presets: [project]
  files: [ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/.ace-defaults/assign/catalog/steps/work-on-task.step.yml, ace-assign/handbook/workflow-instructions/assign/drive.wf.md, ace-assign/lib/ace/assign/molecules/preset_inferrer.rb, ace-task/handbook/skills/as-task-work/SKILL.md, ace-task/handbook/workflow-instructions/task/work.wf.md, ace-assign/.ace-defaults/assign/catalog/steps/mark-task-done.step.yml, CHANGELOG.md]
  commands: [ace-bundle wfi://task/work, ace-bundle wfi://assign/create, ace-bundle wfi://assign/drive, ace-assign status]
---

# Ship outcome-based task presets

## Behavioral Specification

### User Experience

- **Input:** A user invokes public `as-task-work` with one task and optionally selects a terminal-outcome preset.
- **Process:** The skill explicitly creates and drives the matching assignment, while an internal implementation step performs only atomic implementation.
- **Output:** The task reaches exactly the requested merge-approval, guarded auto-merge, in-place commit, or ACE-development outcome.

### Expected Behavior

- Bare `as-task-work` selects `work-on-task` even when the runtime ignores `assign:` metadata.
- `work-on-task` uses one task-owned worktree from a fixed base; implements, acceptance-verifies, updates conditional docs and the one leading root `CHANGELOG.md` `Unreleased` section, scope-audits, commits/pushes/creates a draft PR, executes review and feedback, reverifies, rebases while preserving concurrent changelog entries, marks done during final delivery, updates the PR, obtains exact-head gates, then stops for merge approval with branch/worktree intact.
- `work-on-task-auto-merge` uses identical gates and treats preset selection as advance authorization only for a safe guarded merge.
- `work-on-task-in-place` creates one reviewed, verified, scoped commit in the explicitly authorized current checkout and creates no worktree, PR, rebase, or merge.
- `work-on-task-ace-development` owns the existing batch/fork/release/demo/retro pipeline.
- Internal `as-task-implement` / `implement-task` never marks done, commits, pushes, creates PRs, rebases, merges, versions, publishes, or deploys.

### Interface Contract

```text
/as-task-work <task-ref>
/as-task-work <task-ref> --preset work-on-task-auto-merge
/as-task-work <task-ref> --preset work-on-task-in-place
/as-task-work <task-ref> --preset work-on-task-ace-development
```

Error Handling:

- Draft or invalid task references are handled before assignment execution according to task lifecycle policy.
- Turn/terminal loss, completed child subtrees, or newly exposed parent work cannot produce a false completion response.
- Missing current-checkout authorization blocks `work-on-task-in-place`.

Edge Cases:

- Metadata-aware and metadata-blind runtimes route through the same public outcome contract.
- Assignment continuation discovers state from the owning worktree rather than assuming root-local `.ace-local/assign`.
- Application task presets update root `Unreleased` but do not version, publish, or deploy.

## Success Criteria

- All four preset names resolve to their documented outcomes.
- Bare public task work creates and drives `work-on-task` in both metadata-aware and metadata-blind runtimes.
- Atomic implementation has none of the prohibited delivery side effects.
- Worktree-aware continuation resumes pending parent work after turn or terminal loss.
- Root `Unreleased` remains singular and preserves both current-base and task entries through rebase.
- Each preset stops at its exact terminal state with no leaked behavior from another preset.

## Validation Questions

- None open. The four preset names and public/internal ownership boundary are fixed by issue #311.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** One public task-work invocation reaches a named, predictable terminal outcome
- **Advisory size:** Large
- **Context dependencies:** Conservative defaults, assignment presets/catalog, public/internal skills, drive continuation, task lifecycle

## Verification Plan

### Unit/Component Validation

- Verify preset inference, public routing, internal-step capability limits, worktree-state discovery, and changelog preservation rules.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise metadata-aware/blind routing, all four terminal states, turn-loss continuation, and concurrent `Unreleased` rebase behavior.

### Failure/Invalid Path Validation

- Missing authorization, stale assignment state, and newly exposed parent work block false completion; no application preset versions or publishes.

### Verification Commands

- `ace-test ace-assign all`
- `ace-test ace-task all`
- `ace-test-suite --target fast`

## Objective

Replace the overloaded task-work path with explicit public delivery outcomes and a narrowly bounded internal implementation capability.

## Scope of Work

- Public `as-task-work` routing and assignment drive
- Four terminal-outcome presets
- Internal `as-task-implement` / `implement-task`
- Worktree-aware continuation and root changelog preservation

## Deliverables

### Behavioral Specifications

- Preset terminal states and ownership boundaries

### Validation Artifacts

- Cross-runtime routing, continuation, outcome, and changelog scenarios

## Out of Scope

- Exact-head receipt and merge-digest details (`8vb.t.vy9.4`)
- Worktree cleanup, bootstrap, or explicitly enabled bookkeeping safety

## References

- https://github.com/cs3b/ace/issues/311#issuecomment-5272561943
- Parent `8vb.t.vy9`
- Dependency `8vb.t.vy9.2`
- `../ux-usage.md`
