---
id: 8xg.t.k9y
status: pending
priority: medium
needs_review: false
created_at: "2026-10-17 13:31:03"
estimate: TBD
dependencies: []
tags: [git-worktree, cli-ux]
bundle:
  presets: ["project"]
  files:
    - ace-git-worktree/lib/ace/git/worktree/commands/list_command.rb
    - ace-git-worktree/lib/ace/git/worktree/cli/commands/list.rb
    - ace-git-worktree/lib/ace/git/worktree/organisms/worktree_manager.rb
    - ace-git-worktree/lib/ace/git/worktree/molecules/worktree_lister.rb
    - ace-git-worktree/lib/ace/git/worktree/models/worktree_info.rb
    - ace-git-worktree/lib/ace/git/worktree/molecules/cleanup_reporter.rb
    - ace-git-worktree/lib/ace/git/worktree/molecules/current_task_linker.rb
    - ace-git-worktree/lib/ace/git/worktree/molecules/worktree_creator.rb
    - ace-git-worktree/lib/ace/git/worktree/models/worktree_metadata.rb
    - ace-git-worktree/.ace-defaults/git/worktree.yml
    - ace-git-worktree/test/fast/commands/list_command_test.rb
    - ace-git-worktree/test/fast/molecules/worktree_lister_test.rb
    - ace-git-worktree/test/fast/models/worktree_info_test.rb
    - ace-git-worktree/test/fast/molecules/current_task_linker_test.rb
    - ace-git-worktree/test/e2e/TS-WORKTREE-001-basic-lifecycle/scenario.yml
    - ace-git-worktree/test/e2e/TS-WORKTREE-001-basic-lifecycle/TC-002-list-and-create.verify.md
    - ace-git-worktree/test/e2e/TS-WORKTREE-001-basic-lifecycle/TC-003-switch-and-formats.verify.md
    - ace-git/lib/ace/git/organisms/repo_status_loader.rb
    - ace-git/lib/ace/git/providers/base.rb
    - ace-git/lib/ace/git/providers/evidence.rb
    - ace-overseer/lib/ace/overseer/organisms/status_collector.rb
    - .ace-tasks/8xa.t.ega-deliver-gad2-closure-records-via/8xa.t.ega-deliver-gad2-closure-records-via-reviewed-pr.s.md
    - ace-git-worktree/docs/usage.md
    - .ace-tasks/8xg.t.k9y-ace-git-worktree-list-active/ux-usage.md
  commands:
    - ace-git-worktree list
    - ace-git-worktree list --format json
    - ace-git-worktree list --help
---

# ace-git-worktree list: active worktree table with compact default

## Behavioral Specification

### User Experience

- **Input**: `ace-git-worktree list` with optional detail flags (`--compact` / `--full`), an activity window (`--active-within DURATION`, default `18h`), the existing filters (`--task-associated`, `--usable`, `--search`) and `--format=table|json|simple`. The redundant `--show-tasks` flag is removed.
- **Process**: The command reads the worktree list once, then scans every worktree concurrently in its own forked child process (HEAD commit metadata, uncommitted changes, `_current` symlink, `.ace-tasks/` diffs), reconciles each worktree to a task id even when its path/branch name is useless, resolves PR state with one bounded forge query, and splits worktrees into "active within window" and "inactive".
- **Output**: By default a compact view: one enriched row per active worktree, then a two-line count footer (inactive worktrees are a number, not rows). `--full` renders every worktree in the same columns with the absolute path. JSON output carries full detail for every selected worktree.

### Expected Behavior

1. **Default (compact)**: running `ace-git-worktree list` prints:
    - A header line naming the window and active/total counts: `Active worktrees (last 18h) -- 3 of 88:`
    - One table row per **active** worktree with columns `Task`, `Branch`, `Age`, `Commit`, `Changes`, `PR`, `Path` (see Interface Contract for widths and semantics).
    - A blank line, then a two-line footer: `Inactive: 85  (use --full to list all)` followed by `Task-associated: 14    Usable: 71    Recent branches without worktrees: 4`.
    - The legacy branch-name enumeration (`Branches: a, b, c, ...`) is gone; the old undifferentiated plain table is not kept as a separate mode (ADR-024). `--format json` remains the machine surface.
2. **Activity definition**: a worktree is *active within the window* when **either**:
    - the last commit reachable from its checked-out HEAD has a committer date inside the window, **or**
    - its working tree currently has uncommitted changes (staged, unstaged, or untracked files).
3. **Task association is name-independent**: the task id is resolved from the best available signal, in this order:
    1. **Recorded metadata**: the task frontmatter `worktree.path` or `worktree.branch` in the current project's `.ace-tasks/` tree matches this worktree's path or branch (`task_id_source: metadata`).
    2. **Current-task symlink**: the `_current` symlink at the worktree root resolves to a directory under `.ace-tasks/` (`task_id_source: symlink`).
    3. **Validated name extraction**: the existing path/branch task-ID extraction, accepted only when the extracted id resolves to an existing task in `.ace-tasks/` (current or archived tree); when the project has no `.ace-tasks/` tree the extraction is accepted as today (`task_id_source: path` or `branch`).
    4. **Task-file diffs** (the name-independent fallback): task files modified **in this worktree** identify the task (`task_id_source: task_files`). Sources, in order: uncommitted changes under `.ace-tasks/`, then files changed by the worktree's commits relative to the merge-base with the primary worktree's checked-out branch (when no merge-base exists, the HEAD commit's changed files). Candidate ids come from each changed task spec's frontmatter `id` (short form), and from the enclosing task directory for changed non-spec files.
    5. Otherwise unresolved: the Task cell renders `-`.
    When step 4 yields multiple tasks, the task with the most changed `.ace-tasks/` files wins (ties broken by lexicographically smallest id); the Task cell renders `<id>+N` where `N` is the number of additional candidate tasks, and JSON exposes all candidates. The `.ace-tasks/` task index is built once per run, not per worktree.
4. **Custom window**: `--active-within` accepts `Nm`, `Nh`, `Nd` durations and bare integers (interpreted as hours). The default is `18h`. Invalid, empty, zero, or negative values produce an actionable error and a non-zero exit. No upper bound is enforced (`--active-within 999d` is accepted).
5. **Full mode**: `--full` lists every worktree in the same table with the absolute `Path` (no `~` shortening, no left-elision; a `--full` line may be wider than the terminal width). `--compact` and `--full` are mutually exclusive flags; compact is the default when neither is given.
6. **PR status**: each worktree row resolves the PR whose head is the worktree's branch through the existing forge provider machinery (the same recent-PR source `ace-git status` uses), using **one bounded provider query per run**, never one network query per worktree. Resolution order:
    1. **Branch match** (`matched_by: branch`): a recent PR whose `head_ref` equals the worktree branch; open PRs preferred over merged/closed.
    2. **Head commit match** (`matched_by: head_sha`): after branch match fails (detached HEAD, renamed branch), a recent PR whose `head_sha` equals the worktree HEAD commit.
    3. **Task reference match** (`matched_by: task_reference`): after both fail, if a task id was resolved, exactly one recent PR whose title or body contains that task id as a bounded token (`8xg.t.k9y` or `k9y`); if zero or more than one match, no PR.
    Rendering: `#142` for an open non-draft PR, `#142 draft`, `#142 merged`, `#142 closed`; `-` when no PR exists, no forge is configured, lookup fails, or the PR falls outside the bounded query window. PR resolution never fails the command and never blocks output indefinitely.
7. **Filters compose**: `--task-associated`, `--usable`, and `--search` filter the worktree set *before* the active/inactive split. `--task-associated` means "task id was resolved by any of the Expected Behavior 3 sources", so inferred tasks are included. The header counts and the `Inactive` / `Task-associated` / `Usable` footer values reflect the filtered set (and total is that filtered total). The `Recent branches without worktrees` count is branch-based and is **not** affected by worktree filters.
8. **Empty states are explicit**: zero active worktrees prints `No active worktrees in the last 18h.` (window echoed), the header count `0 of N`, and the footer counts; zero worktrees at all keeps today's `No worktrees found.` with no table and no footer; exit code stays 0 in both cases.
9. **JSON stays complete**: `--format json` returns every *selected* (post-filter) worktree with the enrichment fields regardless of detail flags, as a top-level array. Detail flags do not alter JSON.
10. **Operating modes**: `--quiet` suppresses the footer counts but keeps the active table (JSON unaffected). `--verbose` and `--debug` keep their current meaning. `--format simple` is unchanged (one `branch at path` line per worktree, no activity markers).
11. **`--show-tasks` removed**: the flag is deleted from the CLI, help text, and usage docs (ADR-024, no compatibility layer). Passing it now fails as an unknown option with a non-zero exit.
12. **Isolated concurrent probing**: each worktree is scanned in its own forked child process:
    - Children run read-only git/FS inspection for exactly one worktree and report a serialized result to the parent; they never write repo state, shared files, or the terminal.
    - At most 16 child processes are alive at once; the parent reaps every child before rendering.
    - Each child has a hard per-probe timeout of 5 seconds; on timeout the parent kills the child and its process group, so no orphan `git` processes remain, and that worktree renders `?` enrichment while the command still exits 0.
    - Output order is always `git worktree list` order, never child completion order; children report raw signals (timestamps, counts), and the parent computes ages from one clock snapshot, so repeated runs on an unchanged repo produce identical output.
    - If `fork` is unavailable (non-POSIX), probes run sequentially with the same timeouts and the same output contract.
    - The parent builds the `.ace-tasks/` task index once and performs the single bounded PR query once; neither is repeated per child.

### Interface Contract

```bash
# CLI interface
ace-git-worktree list [--compact | --full] [--active-within DURATION]
                      [--format table|json|simple]
                      [--task-associated | --no-task-associated]
                      [--usable | --no-usable] [--search PATTERN]
                      [-q | -v | -d]

# Default compact output (shape; COLUMNS=120, dynamic Task width shrinks Path to 31)
Active worktrees (last 18h) -- 4 of 88:
Task   Branch                       Age  Commit                    Changes  PR           Path
------------------------------------------------------------------------------------------------------------------------
ace    main                          3h  spec(8xf.t.ei9-wave-3):…        1  -            ~/Ps/ace
-      codex/ei9-ca…osition-join     8m  feat(ace-assign): compl…        -  -            …-campaign-composition-join/ace
xza.3  codex/ei9-ca…-composition    17h  docs(ei9): specify cano…       13  #142 merged  …ce-wt/ei9-campaign-composition
k9y+1  codex/r3-bou…-convergence     9d  feat(review): define bo…        2  #142 draft   …t/codex-r3-bounded-convergence

Inactive: 84  (use --full to list all)
Task-associated: 14    Usable: 71    Recent branches without worktrees: 1

# JSON per-worktree additions (schema fragment; existing keys unchanged)
{
  "path": "...", "branch": "...",
  "task_id": "k9y",                    // resolved short id, or null
  "task_id_source": "task_files",      // metadata|symlink|path|branch|task_files, or null
  "task_ids": ["k9y", "xza"],          // all candidates when resolved; [] when unresolved
  "active_within_window": true,                              // bool, window from --active-within
  "last_commit": { "sha": "abc1234", "age_hours": 2.1,
                   "committed_at": "2026-10-17T11:20:00Z",
                   "subject": "fix guard" },                 // null when no commits
  "uncommitted": { "staged": 2, "unstaged": 4, "untracked": 1,
                   "total": 7 },                              // null when clean
  "pr": { "number": 142, "state": "open", "draft": false,
          "matched_by": "branch" }                            // null when none/unknown;
}                                                             // matched_by: branch|head_sha|task_reference
```

**Column semantics**

- `Task`: resolved short task id (Expected Behavior 3); `<id>+N` when the task-file fallback found `N` additional candidate tasks; `-` when unresolved.
- `Branch`: checked-out branch name, middle-elided (prefix and suffix kept) when truncated; `detached` for detached HEAD.
- `Age`: relative age of the last commit with a single compact unit, right-aligned: `8m`, `3h`, `9d`, `3w`, `2mo`, `1y`; `never` when the branch has no commits; future timestamps render `0m`. No `ago` suffix (the header carries the meaning).
- `Commit`: last commit subject, right-truncated with a trailing `…`; empty cell when the branch has no commits.
- `Changes`: total uncommitted file count (staged + unstaged + untracked), right-aligned; `-` when the working tree is clean.
- `PR`: `#N` for an open non-draft PR; `#N draft` / `#N merged` / `#N closed` for other states; `-` otherwise (see Expected Behavior 6).
- `Path`: compact mode shortens the `$HOME` prefix to `~` and left-elides (leading `…`) so the distinguishing tail survives; `--full` prints the absolute path untruncated.

**Task association resolution notes**

- The `.ace-tasks/` task index maps short id, full id, task directory, and recorded `worktree` metadata. It is built once per run from task spec frontmatter and used for validation, metadata matching, symlink resolution, and changed-file mapping.
- A task id inferred from task-file diffs is trusted only when the change belongs to a task directory that exists in the index (or, for deleted tasks, matches the leading task-id pattern of the removed path).
- Repos without a `.ace-tasks/` tree fall back to name extraction only (today's behavior); no inference error is reported.

**Probe isolation and concurrency**

- Per-worktree probe = fork a child, run the read-only inspection there, return one serialized result over a pipe, then reap. The parent owns all resolution and rendering.
- Live children are capped at 16; results are stored by `git worktree list` index, so completion order never affects output.
- Per-probe timeout is 5 seconds (implementation constant, not a config key). A timeout or non-zero child exit renders `?` for that worktree's `Age` / `Commit` / `Changes` and leaves the other rows untouched.
- Children must not `Dir.chdir` the parent or mutate shared state; git inspection uses explicit `-C <path>` execution context (ADR-031).
- Forking is a POSIX mechanism; the sequential fallback exists only so the command still works where `fork` is unavailable.

**Width and truncation rules**

- Detected width = `Integer(COLUMNS)` when set and >= 40; otherwise `IO.console&.winsize&.last` when stdout is a TTY; otherwise `120`.
- Compact table layout targets, joined by two-space gutters: `Task` = max(task column contents, 4), `Branch` = 25 (min 12), `Age` = 5, `Commit` = 24 (min 10), `Changes` = 7, `PR` = 11, `Path` = 32 (min 10).
- If the target total exceeds the detected width, shrink in this priority order: `Path`, then `Commit`, then `Branch`, each down to its minimum.
- If the table still exceeds the detected width after every column is at its minimum (minimum totals: 71 columns before the dynamic `Task` width), drop the `Path` column first, then the `Commit` column. Compact output never exceeds the detected width.
- Truncation uses the single-character ellipsis `…` and counts as one column. `Branch` is middle-elided, `Commit` right-truncated, `Path` left-elided. All output lines are right-trimmed (no trailing spaces). The separator line is `-` repeated to the computed table width.
- `--full` is exempt: absolute paths print untruncated even when lines exceed the detected width.

**Consumers**: only the help text, `ace-git-worktree/docs/usage.md`, and the e2e scenario assertions consume this output; no other gem or script parses the table format (verified by search across `ace-*/lib` and `ace-*/handbook`). Existing JSON consumers see additive fields only.

**Error Handling**

- Invalid `--active-within` value (e.g. `--active-within abc`, empty, `0`, `-3h`) -> `Error: invalid duration 'abc'. Use forms like 30m, 18h, 2d, or bare hours.` plus non-zero exit.
- `--compact --full` together -> actionable error stating they are mutually exclusive plus non-zero exit.
- Removed `--show-tasks` -> unknown-option error with a non-zero exit (existing CLI unknown-option behavior).
- Git failure while probing one worktree -> that worktree renders `?` in `Age` / `Commit` / `Changes`, the command still exits 0 when the worktree list itself was readable, and the row still participates in the active/inactive split as inactive unless a signal says otherwise.
- Probe timeout -> child and its process group are killed, row renders `?`, command exits 0.
- Forge offline/timeout -> `PR` shows `-` for all rows; exit 0; no stack traces.

**Edge Cases**

- Detached-HEAD worktrees: activity from the HEAD commit date; `Branch` shows `detached`; PR resolved by head-commit match; `PR` shows `-` when no match.
- Bare worktrees: never active; counted in the `Inactive` footer and in the `Usable` count.
- Prunable/unreadable worktree paths (directory missing or `git status` fails): rendered with `?` enrichment columns, still counted.
- Worktrees whose checked-out branch was force-pushed/rebased: activity uses the current HEAD committer date only.
- Branches with fresh commits but no worktree: never rows; appear only in the `Recent branches without worktrees` count (branch committer date inside the window, excluding branches checked out in any worktree and the primary worktree's main branch).
- Clock skew/future timestamps: treated as active with `Age` `0m`.
- `Changes` renders the exact file count with no abbreviation; a 4+ digit count counts against the width budget and may force other columns to shrink.
- JSON with no commits / clean tree / no PR emits `null` for the matching sub-object rather than omitting keys.
- Task ambiguity: multiple inferred tasks render `<dominant>+N` and JSON lists every candidate; the same worktree always resolves identically on repeat runs.
- A worktree with no resolvable task and no PR still renders (Task `-`, PR `-`) and counts as non-task-associated.

### Success Criteria

1. On a fixture repository with roughly 90 worktrees where exactly 3 have commits or dirty state newer than 18h, the default command prints exactly those 3 enriched rows plus the header and two-line footer, in at most 30 lines of output.
2. `--active-within 2d` reclassifies worktrees whose last activity is between 18h and 48h old as active (window honored, default is 18h); `--active-within 90m` narrows accordingly.
3. `--full` lists every worktree as an enriched row with absolute paths; no legacy plain-table mode remains reachable.
4. `--format json` validates against the documented schema for every selected worktree, including `active_within_window`, `last_commit` (with `sha`, `age_hours`, `committed_at`, `subject`), `uncommitted`, `pr` with `state` in `open|merged|closed` plus `draft` and `matched_by`, and `task_id` / `task_id_source` / `task_ids`.
5. Compact run on a repository with roughly 90 worktrees completes within 10 seconds wall-clock using forked, bounded-concurrency probing (at most 16 live children; per-probe 5s timeout enforced).
6. Zero-active state prints `No active worktrees in the last 18h.` (echoing the configured window) plus the footer, and exits 0.
7. With no forge configured, every `PR` cell reads `-` and the exit code stays 0.
8. Width honored: with `COLUMNS=80` and `COLUMNS=120`, no compact output line exceeds the configured width (columns shrink to their minimums at 80); with `COLUMNS=60`, `Path` is dropped after all columns reach their minimums and the remaining columns stay aligned.
9. `ace-test ace-git-worktree` passes, including new coverage: duration parsing, activity classification, age formatting, column truncation/width policy (with pinned `COLUMNS`), footer counts, PR cell mapping (open/draft/merged/closed/none/outside-window/failure), empty states, mutual-exclusion and invalid-duration errors, `--show-tasks` rejection, the JSON schema, task-association precedence, ambiguity suffix, and forked-probe isolation.
10. Existing e2e scenario `TS-WORKTREE-001` (`TC-002` list evidence, `TC-003` output formats) still passes against the new default output.
11. Name-independent task resolution: a worktree whose path and branch do not resolve to a task (e.g. a Codex-created worktree at `.../xza-direct-cli-contract/ace` on branch `codex/xza-direct-cli-contract`) but whose branch modified `.ace-tasks/<task>/...` rows with that task id and `task_id_source: task_files`.
12. Association precedence: a task worktree whose directory was renamed still resolves from `worktree.branch` metadata (`task_id_source: metadata`); a worktree carrying a resolvable `_current` symlink resolves from it (`task_id_source: symlink`); an extracted 3-character basename that matches no task (e.g. `ace`) is rejected instead of polluting the Task column and counts.
13. Ambiguous task-file inference: when two task directories were modified, the dominant id renders with `+1`, `task_ids` lists both, and repeat runs resolve identically.
14. PR fallbacks: a detached worktree checked out at a recent PR's head shows that PR with `matched_by: head_sha`; a branchless worktree with exactly one recent PR referencing the resolved task id shows it with `matched_by: task_reference`; more than one candidate reference yields `-`.
15. Fork isolation and determinism: a probe that hangs is killed at the 5-second per-probe timeout, that row renders `?`, all other rows render, exit code is 0, no orphan `git` processes remain, and three consecutive runs on the unchanged fixture produce identical row ordering while never exceeding 16 live probe children.

### Vertical Slice Decomposition (task/subtask model)

- **Slice type**: standalone task (single capability slice: one command's output behavior).
- **Slice outcome**: `ace-git-worktree list` delivers the compact active table + footer, `--full`, `--active-within`, name-independent task/PR inference, forked concurrent probing, enriched JSON, and defined width behavior, observable end-to-end from the terminal.
- **Advisory size**: medium (touches list command + lister molecule + manager result + task-association resolver + formatter/width logic + forked probe orchestration + PR provider integration + help/docs + existing fast tests and e2e expectations).
- **Context dependencies**: bundle files listed in frontmatter; `ace-git-worktree list` command; `.ace-tasks/` task tree of the current project; forge provider config inherited from ace-git.

### Verification Plan

**Unit/component validation**

- Duration parser: `30m` -> 0.5h, `18h` -> 18h, `2d` -> 48h, `5` -> 5h, `abc` / `-3h` / `` / `0` -> error.
- Activity classifier (fixture-driven): fresh commit + clean tree -> active; stale commit + dirty tree -> active; stale + clean -> inactive; future-dated commit -> active.
- Age formatter: minutes, hours, days, weeks, months, years, `never`, future -> `0m`.
- Task association precedence: metadata path match, metadata branch match, `_current` symlink, validated path/branch extraction, task-file diff (uncommitted), task-file diff (committed vs merge-base), unresolved -> `-`; unvalidated 3-character name (`ace`) rejected; no-`.ace-tasks` repo keeps today's extraction.
- Ambiguity: dominant task by changed-file count, lexicographic tie-break, `+N` suffix, `task_ids` array contents.
- PR resolution: branch match, head-sha match, unique task-reference match, ambiguous task reference -> `-`, precedence between the three, outside bounded window -> `-`.
- Table formatter: active-only rows, middle/right/left truncation determinism, two-space gutters, right-trimmed lines, separator width, column shrinking priority (Path then Commit then Branch), Path drop under narrow widths (pinned `COLUMNS`).
- Footer formatter: counts with filters applied; inferred tasks counted as task-associated; recent-branches count independent of worktree filters; `--quiet` suppression.
- Probe orchestration: bounded concurrency (<= 16), order preservation independent of child completion order, timeout kill includes process group, sequential fallback path.

**Integration/e2e validation**

- Temp multi-worktree repo (create via `ace-git-worktree create` or plain git): one fresh-commit worktree, one dirty worktree, one stale worktree -> default shows 2 rows + `Inactive: 1`; `--full` shows 3 rows; `--format json` includes all fields; a branch with a new commit but no worktree bumps `Recent branches without worktrees`.
- Name-independent inference: a worktree created with a non-task directory name whose branch modifies `.ace-tasks/<task>/...` resolves that task; a renamed task worktree resolves from metadata; a worktree with a valid `_current` symlink resolves from the symlink.
- Fork isolation: a worktree whose `git` probe hangs (PATH shim) renders `?` after the 5s timeout with exit 0 and no orphan processes; other rows unperturbed; three runs produce identical output ordering.
- Flag contract: `--compact --full` -> error; `--active-within abc` -> error with guidance; `--show-tasks` -> unknown-option error; all non-zero exit.
- Width: run the fixture with `COLUMNS=80` and `COLUMNS=120`, assert every line fits and the table stays aligned; with `COLUMNS=60`, assert the `Path` column is dropped and alignment holds.
- Existing e2e scenario: `bin/ace-test-e2e ace-git-worktree TS-WORKTREE-001`; confirm `TC-002` list evidence and `TC-003` output-format assertions still hold.

**Failure/invalid path validation**

- Forge unreachable (fixture) -> `PR` cells `-`, exit 0.
- One worktree path unreadable -> `?` enrichment, exit 0, remaining rows intact.
- Probe timeout -> `?` enrichment, child reaped, exit 0.
- Missing `.ace-tasks/` tree -> name extraction only, no inference error.

**Verification commands**

- `bin/ace-test ace-git-worktree` -> all green, including new cases.
- `COLUMNS=80 bin/ace-git-worktree list` and `COLUMNS=120 bin/ace-git-worktree list` -> no line exceeds the width; footer counts correct.
- `COLUMNS=60 bin/ace-git-worktree list` -> `Path` column dropped, remaining columns aligned.
- `time bin/ace-git-worktree list` on a ~90-worktree repository -> <= 10s, forked probes, deterministic order.
- `time bin/ace-git-worktree list --full` -> row count equals total worktree count, absolute paths shown.
- `bin/ace-git-worktree list --format json` -> parseable array, schema-complete (task association + PR match sources).
- `bin/ace-git-worktree list --show-tasks` -> non-zero unknown-option error.
- `bin/ace-test-e2e ace-git-worktree TS-WORKTREE-001` -> existing list/output-format goals still pass.

## Objective

Make `ace-git-worktree list` answer the operator's real first question -- "where is work happening right now?" -- by promoting recently-active worktrees into an information-dense, width-safe table (task, age, commit subject, uncommitted changes, PR status) while collapsing everything else into counts. The table must stay useful when worktree names are meaningless: task id and PR are inferred from recorded metadata, the `_current` symlink, and task files modified in the worktree. Probing runs in isolated forked children so the single-threaded 88-row dump becomes a fast, deterministic, bounded-concurrency command with `--full` for exhaustive listings.

## Scope of Work

- **User experience scope**: compact-by-default listing, `--compact` / `--full` detail flags, `--active-within` window parameter, aligned enriched columns, compact two-line count footer, explicit empty states, `--show-tasks` removal.
- **System behavior scope**: activity classification (commit recency + uncommitted state), name-independent task association (metadata, symlink, validated name, `.ace-tasks/` diffs) with ambiguity handling, three-tier PR resolution, filter composition before the active/inactive split, terminal-width detection and column shrinking, JSON schema enrichment, forked bounded-concurrency probing with per-probe timeouts.
- **Interface scope**: `ace-git-worktree list` CLI only (lib/cli command surface, JSON output schema, help text, `docs/usage.md`). No other subcommands change.

## Deliverables

### Behavioral Specifications

- Compact-by-default listing UX with activity-window table, aligned columns, and count footer
- `--compact` / `--full` and `--active-within` flag contract with error behaviors, plus `--show-tasks` removal
- Name-independent task association contract (precedence, ambiguity `+N`, JSON sources) and three-tier PR resolution contract
- Forked probe isolation contract (one child per worktree, <= 16 live, 5s timeout, deterministic order, process-group kill)
- Width/truncation policy and JSON output schema including enrichment fields (`state`, `draft`, `matched_by`, task sources)

### Validation Artifacts

- Success criteria checks executable via the Verification Plan commands
- Unit + integration scenarios listed above mapped to `ace-test ace-git-worktree`, including fork-isolation and name-inference fixtures
- Updated UX usage scenarios in `ux-usage.md` (this directory)

## Out of Scope

- Implementation details (which git porcelain calls, task-index cache layout, IPC encoding, formatter internals)
- Rewriting the existing path/branch task-ID extractor itself: validation and fallbacks are in scope; the extractor's output stays one of the resolution signals
- Changes to other `ace-git-worktree` subcommands (`create`, `remove`, `prune`, `cleanup`, `switch`)
- `ace-overseer status` or `ace-git status` behavior changes (alignment welcome but not required)
- Config cascade keys for the default window, width, probe concurrency, or per-probe timeout (constants/env-only for now; follow-up task)
- Watch/auto-refresh modes, color/theming, alternate sort orders, grouping
- Native Windows process isolation: POSIX `fork` is the supported concurrency mechanism, with a documented sequential fallback

## References

- `ux-usage.md` in this task directory (draft usage scenarios)
- `ace-git-worktree/docs/usage.md` (current documented behavior; update during work-on-task via `wfi://docs/update-usage`)
- `ace-git-worktree/lib/ace/git/worktree/molecules/current_task_linker.rb` (`_current` symlink source)
- `ace-git-worktree/lib/ace/git/worktree/models/worktree_metadata.rb` and `.ace-tasks/8xa.t.ega-.../*.s.md` (task frontmatter `worktree.path` / `worktree.branch` source)
- `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_creator.rb` (where metadata and the symlink are written on create)
- `ace-overseer/lib/ace/overseer/organisms/status_collector.rb` (existing fork-per-worktree collection precedent)
- `ace-git/lib/ace/git/providers/evidence.rb` (`ProviderPullRequest`: `state` is `:open|:merged|:closed`, `draft` is a separate boolean, `head_sha` enables the commit fallback)
- `ace-git/lib/ace/git/providers/base.rb` (`recent_pull_requests(limit:)` is the bounded per-run PR source)
- `ace-git/lib/ace/git/organisms/repo_status_loader.rb` (PR enrichment pattern)
- `ace-git-worktree/lib/ace/git/worktree/molecules/cleanup_reporter.rb` (`dirty_state` porcelain precedent)
- `ace-git-worktree/test/e2e/TS-WORKTREE-001-basic-lifecycle/` (list/output-format e2e expectations)
- ADR-023 (CLI conventions), ADR-024 (no backward compatibility; legacy table and `--show-tasks` removed), ADR-030 (B36 compact IDs), ADR-031 (subprocess argv / execution-context contract)
