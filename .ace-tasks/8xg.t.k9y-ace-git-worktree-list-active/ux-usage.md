# ace-git-worktree list activity views - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Daily driver - what happened recently?

**Goal**: Operator starts the day and wants to see only the worktrees where work happened in the last 18 hours, with enough context (task, age, last commit subject, uncommitted changes, PR state) to decide where to look first.

```
ace-git-worktree list
```

**Expected Output**

```
Active worktrees (last 18h) -- 4 of 88:
Task   Branch                       Age  Commit                    Changes  PR           Path
------------------------------------------------------------------------------------------------------------------------
ace    main                          3h  spec(8xf.t.ei9-wave-3):…        1  -            ~/Ps/ace
-      codex/ei9-ca…osition-join     8m  feat(ace-assign): compl…        -  -            …-campaign-composition-join/ace
xza.3  codex/ei9-ca…-composition    17h  docs(ei9): specify cano…       13  #142 merged  …ce-wt/ei9-campaign-composition
k9y+1  codex/r3-bou…-convergence     9d  feat(review): define bo…        2  #142 draft   …t/codex-r3-bounded-convergence

Inactive: 84  (use --full to list all)
Task-associated: 14    Usable: 71    Recent branches without worktrees: 1
```

Age and Changes are right-aligned; the `Commit` subject is right-truncated and `Branch`/`Path` preserve their distinguishing tails. `xza.3` and `k9y+1` were inferred from task files modified in those worktrees (`k9y+1` means one additional candidate task was also touched).

### Scenario 2: Custom activity window

**Goal**: After a weekend, the 18h default is too narrow; widen to 3 days.

```
ace-git-worktree list --active-within 3d
```

**Expected Output**

Same compact shape as Scenario 1, header reads `Active worktrees (last 3d) -- N of 88:` and the footer counts reflect the wider classification.

### Scenario 3: Exhaustive listing

**Goal**: Cleanup sweep - every worktree as a row with full enrichment columns and exact paths.

```
ace-git-worktree list --full
```

**Expected Output**

One enriched table row per worktree (active and inactive), followed by the two-line footer. `Path` shows the absolute path, untruncated; `--full` lines may be wider than the terminal. No plain legacy table exists.

### Scenario 4: Worktree with a useless name

**Goal**: A worktree created by another tool (`.../xza-direct-cli-contract/ace` on branch `codex/xza-direct-cli-contract`) has no task id in its path or branch. The operator still needs to know which task it belongs to and which PR it is.

**Expected Output**

The Task cell shows the task whose `.ace-tasks/` files were modified in that worktree (e.g. `xza.3`; `<id>+N` when several tasks were touched). The PR cell shows the PR matched by branch, else by HEAD commit, else by a unique task reference in the PR title/body. JSON makes the provenance explicit:

```
{
  "task_id": "xza.3",
  "task_id_source": "task_files",
  "task_ids": ["xza.3", "xz9"],
  "pr": { "number": 142, "state": "open", "draft": false, "matched_by": "head_sha" }
}
```

### Scenario 5: Machine consumption

**Goal**: A script needs per-worktree activity, dirty state, faithful PR data (including draft flag), and task-association provenance.

```
ace-git-worktree list --format json
```

**Expected Output**

JSON array; every selected worktree object includes `task_id`, `task_id_source` (`metadata|symlink|path|branch|task_files|null`), `task_ids`, `active_within_window`, `last_commit` (`sha`, `age_hours`, `committed_at`, `subject`), `uncommitted` (`staged`, `unstaged`, `untracked`, `total`), and `pr` (`number`, `state` in `open|merged|closed`, `draft` boolean, `matched_by` in `branch|head_sha|task_reference`). Sub-objects are `null` rather than omitted when absent.

### Scenario 6: Narrow terminal

**Goal**: Stay readable on an 80-column terminal.

```
COLUMNS=80 ace-git-worktree list
```

**Expected Output**

No line exceeds 80 columns: columns shrink in priority order (`Path`, then `Commit`, then `Branch`) down to their minimums; `Path` is dropped only when the minimums still overflow (e.g. `COLUMNS=60`). Column alignment holds; paths remain available via `--full`.

### Scenario 7: Slow or hung probe

**Goal**: One worktree's git probe hangs (large repo, network filesystem, broken worktree). The listing must not hang and must not lose the other rows.

**Expected Output**

Each worktree is probed in its own forked child; the hung probe is killed at the 5-second per-probe timeout, that row renders `?` in `Age`/`Commit`/`Changes`, all other rows render normally, output order stays `git worktree list` order, exit code is 0, and no orphan `git` processes remain.

### Scenario 8: Invalid duration / conflicting flags / removed flag

**Goal**: Understand failure behavior on bad input.

```
ace-git-worktree list --active-within abc
ace-git-worktree list --compact --full
ace-git-worktree list --show-tasks
```

**Expected Output**

Actionable one-line errors (`invalid duration 'abc'. Use forms like 30m, 18h, 2d, or bare hours.`; mutual-exclusion message; unknown-option message for the removed `--show-tasks`) with non-zero exit codes; no partial output.

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage` (target: `ace-git-worktree/docs/usage.md`).
- Help text (`--help`, list_command `show_help`) must document the new flags, column semantics, width behavior, task-association sources, and must no longer mention `--show-tasks`.
- `docs/usage.md` examples that currently use `--show-tasks` must be rewritten (the Task column is always present now).
- Task-association and PR-match provenance must be documented so agents can decide how much to trust an inferred task id or PR.
- The probe isolation behavior (fork per worktree, 16-child cap, 5s timeout, deterministic order) must be documented as observable behavior, not just an internal detail.

## Implementation Status (delivered)

All scenarios above are implemented and covered by `test/fast`:

- Scenario 1/2/3 (compact default, custom window, `--full`): `WorktreeListReport`
  + `WorktreeTableFormatter`/`WorktreeFooterFormatter` (width policy tested with
  pinned `COLUMNS`).
- Scenario 4 (useless names): `TaskAssociationResolver` (`task_files` precedence)
  and `PrStatusResolver` (`branch` -> `head_sha` -> `task_reference`).
- Scenario 5 (JSON): additive schema fields `task_id_source`, `task_ids`,
  `active_within_window`, `last_commit`, `uncommitted`, `pr` (state/draft/matched_by).
- Scenario 6 (narrow terminal): Path columns shrink then drop; `--full` exempt.
- Scenario 7 (slow probe): forked `WorktreeProbeRunner` with 16-child cap, 5s
  per-probe timeout, process-group kill, `?` rendering, deterministic order.
- Scenario 8 (bad input): one-line actionable errors with non-zero exit;
  `--show-tasks` is an unknown option.

`ace-git-worktree/docs/usage.md` is the authoritative usage reference.
