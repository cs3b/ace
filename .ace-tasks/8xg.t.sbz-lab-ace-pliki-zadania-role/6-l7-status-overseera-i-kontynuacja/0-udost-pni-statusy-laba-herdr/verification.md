# Verification results — 8xg.t.sbz.6.0 (2026-10-18)

Branch: `l7-statuses` (worktree `.ace-wt/l7-statuses`), commits `5118ed51b..517bb356b`.

## Automated tests

- `bin/ace-test ace-herdr all` — 610 tests, 2510 assertions, 0 failures.
- `bin/ace-test ace-lab all` — 211 tests, 707 assertions, 0 failures (4 pre-existing skips).
- `bin/ace-test-suite` — 51 packages, 11675 tests, 38444 assertions, 0 failures (41 pre-existing skips).
- New coverage: `ace-herdr/test/fast/molecules/status_composer_test.rb` (9),
  `ace-herdr/test/fast/commands/status_test.rb` (10),
  `ace-lab/test/molecules/config_state_classifier_test.rb` (9),
  `ace-lab/test/molecules/lab_state_scanner_test.rb` (5),
  `ace-lab/test/models/status_report_test.rb` (7),
  `ace-lab/test/organisms/status_service_test.rb` (4),
  `ace-lab/test/commands/status_test.rb` (10).
- `bin/ace-lint` on all changed docs (usage/README/CHANGELOG in both gems): pass.

## Acceptance scenarios (spec §Plan weryfikacji)

1. **Positive / integration** — configuration and local state visible without any lab-owner process;
   Herdr shows the real layout; worktree associations preserved:
   - `ace-lab status` (worktree root): `Lab configuration: missing (defaults only...)`,
     `tasks present (18)`, `assignments present (1)`, exit 0.
   - `ace-lab status` with a valid overlay (/tmp project): `configured — .ace/lab/config.yml
     (topology: N project(s), N agent(s), N service(s))`, exit 0.
   - `ace-herdr status`: runtime reachable → tree or `No live herdr workspaces.` (valid empty), exit 0.
   - `ace-git-worktree list` (k9y) untouched: still the enriched task-association view; no second
     implementation added (diff touches no worktree-association code; docs point to k9y).
2. **Error / incomplete input** — marked, never an empty-and-ready lab:
   - Herdr unavailable (PATH without `herdr`): `herdr CLI not found or not executable: herdr`,
     exit 1 — no empty layout rendered.
   - Broken YAML overlay: full report printed, then
     `Error: lab status reported source errors: invalid lab configuration: <path> could not be parsed as YAML`,
     exit 1.
   - No configuration at all: `missing (defaults only...)`, exit 0 — distinct from a valid empty
     overlay (`configured ... topology: 0 project(s), 0 agent(s), 0 service(s)`, exit 0).
   - Panes referencing vanished tabs/workspaces render in a synthetic `(unlinked)` group
     (unit-pinned in `status_composer_test.rb`).
3. Result usable by the next role/tool: table default, `--format json` emits the full composed
   tree / report schema (documented in both `docs/usage.md`).

## Scope discipline

- Packages touched: `ace-herdr/`, `ace-lab/` (+ this task folder). No changes to
  `ace-git-worktree`, `ace-overseer`, `ace-runtime`; no new gem dependencies; strictly read-only
  commands; no new state owner (ADR-034).

## Independent review

- Merge gate per AGENTS.md: executed tests (above) + independent reviewer verdict.
- Round 1 (fresh-context reviewer agent, range `5118ed51b..517bb356b`): **FAIL** — one blocking
  finding: `ConfigStateClassifier#deep_merge_documents` inverted ADR-22 cascade precedence
  (user overlay overrode project overlay; non-stable sort also made order unspecified); no test
  pinned multi-overlay precedence. Five non-blocking notes: `Dir.home` prefix heuristic for the
  project/user overlay split, `documents.empty?` mapped to `:invalid` instead of missing, brittle
  `[:note]` deref in `first_error`, scoped `--workspace` renders unscoped workspaces as 0-tab
  shells (documented), `entries` is a directory-children count.
- Fix commit (see below): merge now mirrors the canonical resolver (`documents.reverse.reduce`,
  nearest overlay wins); overlay split keys on `~/.ace` not `$HOME` prefix; empty cascade →
  `defaults_only`; `first_error` safe-navigation; new regression tests
  `test_project_overlay_wins_over_user_overlay`, `test_project_rooted_under_home_is_still_the_project_overlay`,
  `test_no_documents_at_all_is_missing_not_invalid`. Re-run: ace-lab 214 tests / 0 failures,
  ace-herdr 610 tests / 0 failures.
- Round 2 verdict recorded below.

