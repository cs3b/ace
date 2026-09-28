---
name: overseer-workflow
description: Orchestrate task worktrees with ace-overseer (work-on, status, prune) under binding prune-safety and status-truth executed-check contracts
allowed-tools: Bash, Read
doc-type: workflow
title: Overseer Workflow
purpose: Binding process contract for the overseer lifecycle (work-on, status, prune) with executed-check contracts for prune safety and status truth.
ace-docs:
  last-updated: '2026-09-28'
  last-checked: '2026-09-28'
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
preservation proof plus an executed no-active-writer check** for every
candidate:

1. Prove the work is already merged into its base:

   ```bash
   git merge-base --is-ancestor <work-head> <base>
   ```

   Exit code 0 proves every commit on the work branch is contained in the
   base.

2. If the work was migrated elsewhere (squash-merge, cherry-pick,
   hand-off), preservation requires a **declared, verified destination**
   plus content equivalence. A matching commit subject is never sufficient
   proof:

   1. Declare the destination concretely: successor repository plus
      branch/PR/commit that received the work.
   2. Verify the destination actually accepted the work, executed in this
      session:

      ```bash
      git -C <successor-repo> merge-base --is-ancestor <dest-ref> <dest-branch>
      ```

      rc=0 proves the destination landed on the declared branch (or read
      the merged/accepted state from the forge hosting the PR).

   3. Prove the destination carries the same work by content, not by
      name. Pass with exactly one of:

      - Tree/artifact equivalence -- the squashed result is the same
        content:

          ```bash
          test "$(git -C <successor-repo> rev-parse '<dest-ref>^{tree}')" \
            = "$(git rev-parse '<work-head>^{tree}')"
          ```

      - Patch equivalence -- the same changes, compared inside the
        successor repository. Fetch the source proof refs first and
        range-diff with separate source and destination bases:

          ```bash
          git -C <successor-repo> fetch <source-repo> <source-base> <work-head>
          git -C <successor-repo> range-diff \
            <source-base>...<work-head> <dest-base>...<dest-ref>
          ```

          with no substantive differences; or diff the normalized patches
          (`git show --format=` output of each side) and require an empty
          diff.

   4. Ambiguity preserves: conflicting hashes, an unverifiable destination,
      or a failed equivalence check means no proof -- block the prune per
      step 5.

3. Prove no active writer before destruction, executed in this session
   against the authoritative lifecycle state:

   ```bash
   ace-overseer status --format json
   ```

   For assignment-backed candidates also check `ace-assign status`; for Lab
   runtime candidates check `ace-overseer status --runtime lab`. A running
   assignment, an in-flight Lab work, or any unaccounted writer blocks the
   prune. Missing or unreadable lifecycle state counts as an active writer
   -- preserve.

4. A described or remembered proof is never sufficient -- run the commands
   and observe the results in this session.

5. Any commit without a proven copy, any failed or ambiguous equivalence,
   or any active-writer evidence **blocks the prune** for that worktree.
   Report the blocked candidate (ref, head SHA, missing proof) to the
   operator; never silently drop it and never force past a failed proof.
   Preserve on ambiguity.

## Non-Negotiable Contracts Summary

| Contract     | Claim | Executed proof |
|--------------|-------|----------------|
| Prune safety | "The work is preserved and nothing is actively writing" | `git merge-base --is-ancestor <work-head> <base>` (rc=0), or verified destination + tree/artifact or patch equivalence; plus `ace-overseer status --format json` (assignment/Lab status where applicable) showing no active writer |
| Status truth | "The task is blocked on the owner" | An executable non-secret check run in this session; stale tasks closed/corrected in the same change |

## Success Criteria

- Work starts only through `ace-overseer work-on` (or the Lab-runtime equivalent), never through ad-hoc manual worktree provisioning.
- Every status review re-verified pending owner-blocked tasks with an executed check and corrected stale state in the same change.
- Every pruned worktree/branch had an executed preservation proof (ancestor containment, or a verified destination with tree/artifact or patch equivalence) and an executed no-active-writer check; candidates without complete proof were reported as blocked, not removed.
