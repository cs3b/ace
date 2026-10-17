# Implementation Plan — 8xg.t.k9y `ace-git-worktree list` active worktree table

JIT plan produced because `ace-task plan 8xg.t.k9y` stalled (>5 min, no output) —
the planner dispatch hang is an environment issue, not a spec issue. This plan is
the implementation checklist for the work-on-task execution.

## Task Summary

Replace the legacy plain `list` table (Task/Branch/Path/Status + "Summary:" block)
with a compact, width-aware active-worktree table and count footer. Activity is
"committed or dirty inside `--active-within` (default 18h)". Task ids and PRs are
resolved name-independently (recorded metadata -> `_current` symlink -> validated
name -> task-file diffs; PR by branch -> head sha -> unique task reference).
Per-worktree probing runs in forked children (<=16 live, 5s per-probe timeout,
deterministic order). `--full` lists everything, JSON is enriched, `--show-tasks`
is removed (ADR-024).

## Exec Context

- Repo: ACE monorepo; packages are Ruby gems under `ace-*/`; ATOM layers
  (`atoms/`, `molecules/`, `organisms/`, `models/`), flat tests under `test/fast/{atoms,molecules,organisms,models,commands}`.
- Gem: `ace-git-worktree` (Ruby >= 3.2, dry-cli via `ace-support-cli`; depends on
  `ace-git ~> 0.29` for repo/forge provider machinery and `ace-task`).
- Commands: run `bin/ace-test ace-git-worktree` (never rake/bundle exec ruby),
  `bin/ace-lint <paths>`, `bin/ace-git-commit <paths>`.
- Config cascade ADR-022; no backward compatibility before 1.0 (ADR-024);
  compact Base36 ids (ADR-030); subprocess contract is explicit argv (ADR-031).
- Task spec: `.ace-tasks/8xg.t.k9y-ace-git-worktree-list-active/8xg.t.k9y-…-worktree-table.s.md`;
  draft usage: same folder `ux-usage.md`.

## Technical Approach

- **Renderer pipeline**: one organism `Organisms::WorktreeListReport` owns ordering:
  worktree inventory -> task index (once) -> fork-probe all (once) -> task
  association -> PR resolution (one provider query) -> filters -> active/inactive
  split -> render. The list command only parses/validates args and prints.
- **Probing**: fork one child per worktree; child runs read-only git/FS inspection
  for exactly one worktree and writes one JSON payload to a pipe; parent owns
  task association, age math (single clock snapshot), PR, filters, rendering.
  Parent pool keeps <=16 children alive, kills a timed-out child's process group
  (`setpgid` in child, `Process.kill(-pid)`), reaps everything before rendering,
  stores results by `git worktree list` index. Sequential fallback when
  `fork` is unavailable (same contract; `Timeout` around the inline probe).
- **Task index**: built once from the current project's `.ace-tasks/**.s.md`
  frontmatter (`id`, `status`, `worktree.path`, `worktree.branch`); maps full id,
  short id (suffix + subtask, e.g. `k9y`, `qk0.3`), task directory, and recorded
  worktree metadata. Repos without `.ace-tasks/` keep today's name extraction.
- **Task association precedence** (first hit wins, recorded as `task_id_source`):
  `metadata` (index path/branch match) -> `symlink` (`_current` resolves under
  `.ace-tasks/`) -> `path`/`branch` (name extraction validated against index) ->
  `task_files` (uncommitted `.ace-tasks/` diffs, then committed diffs vs merge-base
  with the primary worktree's branch). Ambiguity: dominant changed-file count,
  lexicographic tie-break, `<id>+N`, full candidate list in JSON.
- **PR resolution**: one `provider.recent_pull_requests(limit: 50)` per run.
  Order: `branch` (head_ref == branch, open preferred) -> `head_sha`
  (head_sha == worktree HEAD) -> `task_reference` (exactly one PR whose title/body
  contains the task id as a bounded token). Any provider failure => `-`, exit 0.
- **Widths**: detected width = `COLUMNS` (>=40) else `IO.console.winsize.last` on
  TTY else 120. Targets Task=max(contents,4), Branch 25/12, Age 5, Commit 24/10,
  Changes 7, PR 11, Path 32/10; two-space gutters; shrink Path, Commit, Branch to
  minima; then drop Path, then Commit. `…` truncation: branch middle, commit right,
  path left; right-trim lines; separator = `-` * table width. `--full` exempt.
- **No new config keys** (constants only, per spec Out of Scope); no new gem
  dependencies (stdlib `json`, `time`, `io/console` only).

## File Modifications

### Create

- `ace-git-worktree/lib/ace/git/worktree/atoms/duration_parser.rb` — parse
  `Nm|Nh|Nd|<int hours>` to hours + canonical label; actionable `ArgumentError`.
- `ace-git-worktree/lib/ace/git/worktree/atoms/text_truncator.rb` — single-column
  `…` middle/right/left truncation helpers.
- `ace-git-worktree/lib/ace/git/worktree/atoms/relative_age_formatter.rb` —
  seconds -> `8m|3h|9d|3w|2mo|1y|never`, future -> `0m`.
- `ace-git-worktree/lib/ace/git/worktree/models/task_index.rb` — immutable task
  index + query API (metadata match, dir match, validation, candidate ranking).
- `ace-git-worktree/lib/ace/git/worktree/molecules/task_index_builder.rb` — scans
  `.ace-tasks/` (current + `_archive`/`_maybe` sub-trees) once per run.
- `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_probe.rb` — single
  worktree read-only probe payload (HEAD sha/epoch/subject, staged/unstaged/
  untracked counts, `_current` target, changed `.ace-tasks/` paths).
- `ace-git-worktree/lib/ace/git/worktree/organisms/worktree_probe_runner.rb` —
  fork pool: <=16 live children, 5s per-probe timeout, process-group kill,
  deterministic order, sequential fallback.
- `ace-git-worktree/lib/ace/git/worktree/molecules/task_association_resolver.rb` —
  precedence + ambiguity handling; mutates WorktreeInfo enrichment.
- `ace-git-worktree/lib/ace/git/worktree/molecules/pr_status_resolver.rb` — single
  bounded provider query + branch/head_sha/task_reference matching + rendering hash.
- `ace-git-worktree/lib/ace/git/worktree/molecules/recent_branch_counter.rb` —
  branch-based "recent branches without worktrees" count.
- `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_table_formatter.rb` —
  width detection, column shrink/drop policy, truncation, header/rows.
- `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_footer_formatter.rb` —
  header line + two-line footer + empty-state lines.
- `ace-git-worktree/lib/ace/git/worktree/organisms/worktree_list_report.rb` —
  pipeline + JSON/table/simple selection + statistics.
- Tests: `test/fast/atoms/{duration_parser,text_truncator,relative_age_formatter}_test.rb`,
  `test/fast/models/task_index_test.rb`,
  `test/fast/molecules/{task_index_builder,worktree_probe,task_association_resolver,pr_status_resolver,recent_branch_counter,worktree_table_formatter,worktree_footer_formatter}_test.rb`,
  `test/fast/organisms/{worktree_probe_runner,worktree_list_report}_test.rb`.

### Modify

- `ace-git-worktree/lib/ace/git/worktree/models/worktree_info.rb` — additive
  enrichment attributes (`task_id_source`, `task_ids`, `active_within_window`,
  `last_commit`, `uncommitted`, `pr`, internal `probe_error`), JSON additions,
  no change to existing keys/consumers.
- `ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb` — add
  `short_id(full_id)` and accept numeric subtasks (`qk0.3`) in `normalize`.
- `ace-git-worktree/lib/ace/git/worktree/molecules/worktree_lister.rb` — remove
  legacy table formatter; keep `:simple`/`:json`; `list_with_tasks` removed.
- `ace-git-worktree/lib/ace/git/worktree/organisms/worktree_manager.rb` — delegate
  `list_all` to `WorktreeListReport`; drop `show_tasks` option and legacy
  summary; `format: :simple` stays for switch/remove fallbacks.
- `ace-git-worktree/lib/ace/git/worktree/commands/list_command.rb` — new flag
  parsing/validation (`--compact`, `--full`, `--active-within`), remove
  `--show-tasks`, print renderer output, one-line errors, new help text.
- `ace-git-worktree/lib/ace/git/worktree/cli/commands/list.rb` — new dry-cli
  options (`compact`, `full`, `active_within`), remove `show_tasks` passthrough.
- `ace-git-worktree/lib/ace/git/worktree/cli.rb` — help example using `list`.
- `ace-git-worktree/lib/ace/git/worktree.rb` — require new components.
- `ace-git-worktree/docs/usage.md` — rewrite list section (flags, columns,
  task/PR provenance, width behavior, probe isolation, no `--show-tasks`).
- `ace-git-worktree/CHANGELOG.md` + `version.rb` — feature entry, minor bump.
- `ace-overseer/lib/ace/overseer/organisms/{status_collector,prune_orchestrator}.rb`
  — drop removed `show_tasks:` argument from `list_all` calls.
- `ace-git-worktree/test/fast/{commands/list_command_test.rb,models/worktree_info_test.rb,atoms/task_id_extractor_test.rb}`
  — update expectations.
- `ace-git-worktree/test/e2e/TS-WORKTREE-002-task-aware/TC-003-list-and-filter.runner.md`
  — remove removed `--show-tasks` invocation.
- `.ace-tasks/8xg.t.k9y-…/ux-usage.md` — mark implementation notes satisfied where behavior lands.

### Delete

- Legacy plain-table rendering (`WorktreeLister#format_as_table`), the `Summary:`
  block (`ListCommand#display_summary`), `--show-tasks`, and
  `WorktreeLister#list_with_tasks` / `#resolve_task_associations` no-op. No
  compatibility layer (ADR-024).

## Plan Checklist

- **step_01** (depends: none) — `TaskIDExtractor.short_id` + numeric subtask
  normalize; `DurationParser`; `RelativeAgeFormatter`; `TextTruncator`.
  Anchor: `ace-git-worktree/lib/ace/git/worktree/atoms/task_id_extractor.rb:60`.
  Verification: `bin/ace-test ace-git-worktree test/fast/atoms/duration_parser_test.rb`,
  `…/text_truncator_test.rb`, `…/relative_age_formatter_test.rb`, `…/task_id_extractor_test.rb`.
- **step_02** (depends: step_01) — `Models::TaskIndex` +
  `Molecules::TaskIndexBuilder`. Anchor: task spec Expected Behavior 3 /
  "Task association resolution notes". Verification: `bin/ace-test ace-git-worktree test/fast/models/task_index_test.rb`,
  `…/molecules/task_index_builder_test.rb`.
- **step_03** (depends: step_02) — WorktreeInfo enrichment fields + JSON additions.
  Anchor: Interface Contract JSON fragment
  (`.ace-tasks/8xg.t.k9y-…/…-worktree-table.s.md:112`). Verification:
  `bin/ace-test ace-git-worktree test/fast/models/worktree_info_test.rb`.
- **step_04** (depends: step_01) — `Molecules::WorktreeProbe` (single-worktree
  read-only payload incl. `_current` + changed `.ace-tasks/` paths, committed and
  uncommitted). Anchor: Expected Behavior 12 / "Probe isolation and concurrency".
  Verification: `bin/ace-test ace-git-worktree test/fast/molecules/worktree_probe_test.rb`.
- **step_05** (depends: step_04) — `Organisms::WorktreeProbeRunner` fork pool
  (16 cap, 5s timeout, pgid kill, order preservation, sequential fallback).
  Anchor: Expected Behavior 12. Verification:
  `bin/ace-test ace-git-worktree test/fast/organisms/worktree_probe_runner_test.rb`.
- **step_06** (depends: step_02, step_03, step_05) —
  `Molecules::TaskAssociationResolver` precedence + ambiguity. Anchor: Expected
  Behavior 3. Verification: `bin/ace-test ace-git-worktree test/fast/molecules/task_association_resolver_test.rb`.
- **step_07** (depends: step_03) — `Molecules::PrStatusResolver` (single bounded
  query, 3-tier match, cell text) + `Molecules::RecentBranchCounter`. Anchor:
  Expected Behavior 6 + Edge Cases. Verification:
  `bin/ace-test ace-git-worktree test/fast/molecules/pr_status_resolver_test.rb`,
  `…/recent_branch_counter_test.rb`.
- **step_08** (depends: step_01, step_03) — `WorktreeTableFormatter` +
  `WorktreeFooterFormatter` width/truncation/footer. Anchor: "Width and truncation
  rules" + `:100` example. Verification:
  `bin/ace-test ace-git-worktree test/fast/molecules/worktree_table_formatter_test.rb`,
  `…/worktree_footer_formatter_test.rb`.
- **step_09** (depends: step_05..step_08) — `Organisms::WorktreeListReport`
  pipeline (filters before split, JSON completeness, empty states, quiet,
  full/compact) + manager/lister delegation cleanup. Anchor: Expected Behavior
  1-11. Verification: `bin/ace-test ace-git-worktree test/fast/organisms/worktree_list_report_test.rb`,
  `bin/ace-test ace-git-worktree`.
- **step_10** (depends: step_09) — `ListCommand` flag contract + `CLI::Commands::List`
  options + help text; remove `--show-tasks`. Anchor: Interface Contract CLI
  fragment. Verification: `bin/ace-test ace-git-worktree test/fast/commands/list_command_test.rb`,
  `bin/ace-git-worktree list --show-tasks` exits non-zero, `bin/ace-git-worktree list --help`.
- **step_11** (depends: step_10) — docs: `docs/usage.md`, e2e scenario
  `TS-WORKTREE-002/TC-003` flag removal, CHANGELOG + version bump. Anchor:
  Deliverables / ux-usage Notes. Verification: `bin/ace-lint ace-git-worktree/docs/usage.md`.
- **step_12** (depends: step_11) — acceptance evidence: `COLUMNS=80/120/60`
  runs, JSON parse, `--full`, `--active-within`, `bin/ace-test-e2e ace-git-worktree TS-WORKTREE-001`.

## Test Plan

- Atom tests: duration parse matrix (`30m`, `18h`, `2d`, `5`, `abc`, `-3h`, ``, `0`,
  `999d`); age formatting (m/h/d/w/mo/y, `never`, future); truncation
  (middle/right/left, width < 4, exact fit).
- Model tests: task index build from fixture `.ace-tasks/` tree (spec ids incl.
  subtasks, `worktree` metadata, archive tree), validation of junk 3-char names,
  candidate ranking/tie-break.
- Probe/probe-runner: payload correctness on a real temp repo (commits, dirty
  counts, symlink, task-file diffs); fork isolation (order deterministic, <=16
  alive, timeout kill renders `?`, no orphan pgid, sequential fallback).
- Association: every precedence source, rejection of unmatched name, `+N`
  ambiguity, repeated-run determinism.
- PR: branch/head_sha/task_reference match, open-over-merged preference,
  ambiguous -> `-`, provider failure -> `-`.
- Formatter: pinned COLUMNS (40/60/80/120), all minima then Path drop, alignment,
  right-trim, separator width, full mode untruncated absolute paths.
- Report/command: compact default shape, footer counts with filters,
  `--quiet`, zero-active message, zero-worktrees message, JSON schema per spec,
  invalid duration/mutual exclusion/`--show-tasks` exit codes, COLUMNS=60 `Path`
  dropped.

## Risk Assessment

- **Primary risk**: fork contract leaks (orphan `git`, child writing to terminal,
  nondeterministic ordering) or hangs on slow FS. Mitigation: child redirected to
  `/dev/null`, pgid kill with TERM->KILL, results stored by index, single clock
  snapshot, sequential fallback; tests cover timeout + ordering + concurrency cap.
- **Secondary risk**: JSON consumers of `list --format json` (only documented
  consumer is humans/scripts; additive keys only). Mitigation: keep existing keys
  and `to_h` shape, add fields only; JSON test asserts both.
- **Secondary risk**: width math vs. spec. Mitigation: pinned-COLUMNS tests derived
  from the spec's stated targets/minima (71-column minimum before Task width).
- Rollback: single-command revert to `WorktreeManager#list_all` legacy path is not
  kept (ADR-024); revert the task's commits instead.

## Freshness Summary

- Task spec read: `.ace-tasks/8xg.t.k9y-…/…-worktree-table.s.md` (fresh, 2026-10-17).
- Draft usage read: `.ace-tasks/8xg.t.k9y-…/ux-usage.md` (fresh).
- Bundle-loaded sources read: `list_command.rb`, `cli/commands/list.rb`,
  `worktree_manager.rb`, `worktree_lister.rb`, `worktree_info.rb`,
  `cleanup_reporter.rb`, `cleanup_pr_resolver.rb`, `current_task_linker.rb`,
  `task_id_extractor.rb`, `git_command.rb`, `worktree_metadata.rb`,
  `ace-git/providers/{base,evidence}.rb`, `ace-git/organisms/repo_status_loader.rb`,
  `ace-overseer/organisms/status_collector.rb`, `docs/usage.md`,
  `test/e2e/TS-WORKTREE-001…`, `test/fast/**` list tests — all match the bundle.
- Plan artifact: this file (fallback creation; `ace-task plan` stalled).
