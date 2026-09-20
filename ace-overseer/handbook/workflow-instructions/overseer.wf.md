---
name: overseer-workflow
description: Orchestrate task worktrees with ace-overseer (work-on, status, prune) under binding prune-safety and status-truth executed-check contracts
allowed-tools: Bash, Read
doc-type: workflow
title: Overseer Workflow
purpose: Binding process contract for the overseer lifecycle (work-on, status, prune) with executed-check contracts for prune safety and status truth.
ace-docs:
  last-updated: '2026-09-20'
  last-checked: '2026-09-20'
---

# Overseer Workflow

## Goal

Orchestrate task worktrees with `ace-overseer` (work-on, status, prune) as the
binding process contract. Two executed-check contracts in this workflow are
non-negotiable: **prune safety** and **status truth**. They exist because a
described or remembered check is how worktrees and commits get silently
destroyed and stale blockers masquerade as state. Every step below is executed,
never assumed.

## Instructions

Run the loaded workflow as the source of truth and execute it end-to-end
instead of only summarizing it.

### 1) Work-on: start focused task work

Provision a worktree, open a tmux window, and prepare the assignment:

```bash
ace-overseer work-on --task <task-ref>
```

- Repeatable/comma-separated refs fan out into the same batch: `ace-overseer work-on --task 230 --task 231,232`
- Optional preset: `ace-overseer work-on --task <task-ref> --preset <preset-name>`
- After launch, switch to the tmux window and run `/ace-assign-drive`.
- Lab runtime variant (reserved agent + Herdr workspace): `ace-overseer work-on --runtime lab --work <work-id> --agent <agent-id>` -- `--task`/`--preset` are not supported with the Lab runtime.

Never improvise worktree provisioning by hand when `work-on` exists; ad-hoc
worktrees bypass the assignment lifecycle that `status` and `prune` rely on.

### 2) Status: inspect active worktrees

```bash
ace-overseer status                     # table dashboard
ace-overseer status --format json       # machine-readable snapshot
```

Lab runtime: `ace-overseer status --runtime lab [--project <project>]` (no
`--watch`; continuous status lives in each project Herdr session).

#### Status truth (non-negotiable executed check)

Recorded blockers are **claims, not state**. During any status review:

1. For each pending owner-blocked task, look for an executable non-secret
   check that can confirm or refute the blocker, and run it when one exists.
2. Close or correct stale tasks **in the same change** -- do not accept a
   recorded blocker as state and do not defer the correction to a later pass.
3. Report what you executed (command + observed output) as the evidence for
   each kept or closed blocker. A described or remembered check is never
   sufficient.

### 3) Prune: remove finished worktrees safely

Always preview before destructive cleanup:

```bash
ace-overseer prune --dry-run
```

Then apply only when confirmed:

```bash
ace-overseer prune --yes
```

- Targeted: `ace-overseer prune <task-ref|folder>...` or `ace-overseer prune --assignment <assignment-id>`
- Lab runtime: `ace-overseer prune <work-id>... --runtime lab --dry-run`, rerun with `--yes` to delegate each destruction to Lab.

#### Prune safety (non-negotiable executed check)

Prune/removal of a worktree or branch happens **only after an executed
preservation proof** for every commit that would be removed:

1. Prove the work is already merged into its base:

   ```bash
   git merge-base --is-ancestor <work-head> <base>
   ```

   Exit code 0 proves every commit on the work branch is contained in the base.

2. If the work was migrated elsewhere (squash-merge, cherry-pick, hand-off),
   prove the copy exists with a subject-level search in the successor
   repository:

   ```bash
   git -C <successor-repo> log --all --grep "<subject>"
   ```

   The search must return the commit(s) carrying the work. No output means no
   proof.

3. A described or remembered proof is never sufficient -- run the command and
   observe the result in this session.

4. Any commit without a proven copy **blocks the prune** for that worktree.
   Report the blocked candidate (ref, head SHA, missing proof) to the operator;
   never silently drop it and never force past a failed proof.

## Non-Negotiable Contracts Summary

| Contract     | Claim                             | Executed proof                                                                                                                                                            |
|--------------|-----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Prune safety | "The work is preserved"           | `git merge-base --is-ancestor <work-head> <base>` (rc=0), or `git -C <successor-repo> log --all --grep "<subject>"` returning the migrated commit                          |
| Status truth | "The task is blocked on the owner" | An executable non-secret check run in this session; stale tasks closed/corrected in the same change                                                                       |

## Success Criteria

- Work starts only through `ace-overseer work-on` (or the Lab-runtime equivalent), never through ad-hoc manual worktree provisioning.
- Every status review re-verified pending owner-blocked tasks with an executed check and corrected stale state in the same change.
- Every pruned worktree/branch had an executed preservation proof; candidates without proof were reported as blocked, not removed.
