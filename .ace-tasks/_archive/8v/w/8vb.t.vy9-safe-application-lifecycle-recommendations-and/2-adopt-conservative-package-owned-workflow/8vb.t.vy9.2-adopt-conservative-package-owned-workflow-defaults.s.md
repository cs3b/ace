---
id: 8vb.t.vy9.2
status: done
priority: high
created_at: "2026-08-12 21:18:20"
estimate: TBD
dependencies: [8vb.t.vy9.0]
tags: [defaults, worktree, task, review, handbook]
parent: 8vb.t.vy9
bundle:
  presets: [project]
  files: [ace-git-worktree/.ace-defaults/git/worktree.yml, ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb, ace-task/handbook/workflow-instructions/task/work.wf.md, ace-review/.ace-defaults/review/config.yml, ace-review/.ace-defaults/review/presets/code-valid.yml, ace-handbook/.ace-defaults/handbook/providers/agents.yml, ace-support-core/.ace-defaults/project-root/AGENTS.md, ace-support-core/.ace-defaults/project-root/docs/tools.md]
  commands: [ace-git-worktree config --show, ace-bundle wfi://task/work, ace-handbook status]
needs_review: false
---

# Adopt conservative package-owned workflow defaults

## Behavioral Specification

### User Experience

- **Input:** A new application installs ACE packages and uses their shipped defaults without copying large project overrides.
- **Process:** Worktree, task, review, handbook, and root-guidance owners provide conservative application behavior directly.
- **Output:** The project starts with checkout-only worktrees, one final completion owner, an executed neutral review gate, neutral skills, and compact canonical guidance.

### Expected Behavior

- `ace-git-worktree` keeps `.ace-wt` repository-local and resolves it from the common/primary checkout; automatic task status, metadata, commit, push, upstream, and PR mutations default to disabled.
- Atomic task implementation leaves the task `in-progress`; final delivery is the sole owner of `done` and archive.
- The default review gate selects one ready `role:review-default`, executes it, and fails if no report is produced.
- Neutral handbook sync projects only `.agents/skills/` by default and preserves project-owned canonical overrides.
- Generated `AGENTS.md` remains compact and points to canonical detailed guidance in `docs/tools.md`.

### Interface Contract

```bash
ace-git-worktree config --show
ace-git-worktree create --task <ref>
ace-review --pr <number> --auto-execute
ace-handbook sync
```

Error Handling:

- Linked-worktree invocation that cannot resolve the primary/common root fails before creating a nested `.ace-wt`.
- Review preparation without an executed report fails the gate.
- Customized guidance or skills are reported as owned overrides and are never overwritten implicitly.

Edge Cases:

- Projects may explicitly re-enable worktree lifecycle mutations, subject to the separate #314 safety contract.
- Explicit harness-native projections remain supported but are never produced by neutral sync.
- The application defaults do not add bootstrap behavior owned by #313.

## Success Criteria

- Fresh application defaults create only a branch/worktree checkout and perform no task/main-checkout or remote mutation.
- Relative worktree roots resolve identically from primary and linked worktrees.
- Implementation cannot mark a task done before final delivery.
- A neutral executed review produces a report or blocks completion.
- Neutral sync and generated guidance remain compact, canonical, and non-destructive to project-owned content.

## Validation Questions

- None open. Explicit opt-ins remain allowed; defaults are conservative.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** A fresh application is safe without copied workflow/config overlays
- **Advisory size:** Large
- **Context dependencies:** Worktree/task/review defaults, handbook provider projection, generated root guidance

## Verification Plan

### Unit/Component Validation

- Assert default values, common-root resolution, completion ownership, review execution, projection selection, and guidance markers.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Bootstrap a plain application fixture and verify checkout-only creation, executed review, neutral sync, and single task completion owner.

### Failure/Invalid Path Validation

- Common-root ambiguity, missing review reports, and customized guidance all fail or report safely without mutation.

### Verification Commands

- `ace-test ace-git-worktree all`
- `ace-test ace-task all`
- `ace-test ace-review all`
- `ace-test ace-handbook all`

## Objective

Move application safety into the packages that own each default so users do not need project-local workflow forks to become safe.

## Scope of Work

- Checkout-only worktree defaults and common-root placement
- Single task-completion ownership
- Provider-neutral executed review
- Neutral skill projection and compact guidance

## Deliverables

### Behavioral Specifications

- Package default contracts and explicit override boundaries

### Validation Artifacts

- Fresh-application and linked-worktree fixtures

## Out of Scope

- Hardening explicitly enabled bookkeeping commits (#314)
- Worktree bootstrap commands or readiness (#313)
- Assignment outcome preset composition (`8vb.t.vy9.3`)

## References

- https://github.com/cs3b/ace/issues/311
- Parent `8vb.t.vy9`
- Dependency `8vb.t.vy9.0`
- `../ux-usage.md`
