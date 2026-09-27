# Implementation Plan — 8wq.t.1qb (all four slices, single PR)

Generated 2026-09-27. Fallback path: `ace-task plan` generation is broken in this
environment (Codex CLI rejects `--full-auto`; Gemini CLI auth tier error), so this plan
is written from the task specs (orchestrator + 8wq.t.1qb.0/.1/.2/.3) per the documented
plan-retrieval fallback. Operator asked for all subtasks delivered on ONE PR
(branch `ace-review-round-efficiency`, worktree `.ace-wt/ace-t.1qb`).

## Slice order

`.0` → `.1` (builds on its evidence model) → `.2` (independent) → `.3` (independent).
One logical step per commit; `ace-test <package> …` green before each commit.

## .0 Delta review mode — `ace-review --pr <id> --delta [head]`

- CLI: `--delta` optional-value option in `cli/commands/review.rb`; `delta` attr on
  `ReviewOptions`.
- New molecule `molecules/delta_resolver.rb`:
  - explicit head: resolve via `git rev-parse`, require 40-hex;
  - auto (no arg): newest session under `.ace-local/review/sessions/review-*` whose
    `metadata.yml` has matching `pr_url` and a `diff_manifest.head_sha`; refuse when none
    (never silently fall back to full review);
  - ancestry: `git merge-base --is-ancestor <ref> <head>` — refuse on non-ancestor
    (covers force-push), fail closed;
  - delta diff: `git diff <ref>..<head>` in project root; refuse with clear message when
    objects unavailable locally.
- `extract_pr_content` delta path: fetch metadata + file inventory (skip full-diff
  fetch), compute delta diff, `DiffScope.select` it, manifest records
  `delta_reference_head` / `delta_base_head` / scope "delta since `<ref>`"; oversized
  delta check unchanged.
- Reference session auto-attaches as evidence (`ReviewEvidence.build`) so prior findings
  carry forward.
- Empty delta → no-op round: session + report written without any model call; report
  states scope, carries prior findings + dispositions, verdict "no new findings in
  delta"; convergence stays agent-side per `review/pr.wf.md` (report is the verdict
  carrier).
- Session metadata records reference head → later bare `--delta` chains from it.

## .1 Exempt-path scopes — `exempt_paths` config

- New molecule `molecules/exempt_paths.rb`:
  - validate at config load: array of non-empty glob strings; over-broad pattern
    (matches a fixed probe set covering root/nested/dotfile paths) refused with the
    pattern named;
  - `classify(paths, patterns)` → `{exempt, non_exempt}` via `SubjectFilter.glob_match?`.
- `preset_manager.resolve_preset` surfaces `exempt_paths`; validation runs in
  `prepare_review_config` (config-load refusal).
- Full rounds: exempt paths excluded from subject and listed in manifest; never a no-op
  (explicit operator intent; empty remaining subject fails through existing
  "no changed files" path honestly).
- Delta rounds: fully-exempt delta → no-op exempt session (zero model calls) listing
  paths + justifying patterns; mixed delta → review non-exempt part only, exempt paths
  enumerated in manifest and report.
- Shares the .0 no-op session writer.

## .2 Subject chunk strategies — DECISION: REMOVE

Rationale: `SubjectStrategy.for` is invoked nowhere in lib/exe (tests only); the
documented config block is commented out and unread; oversized diffs already fail with
an explicit budget-vs-actual refusal (review_manager oversized-diff guard); delta
scoping (.0) is the intended large-PR answer; findings-merge quality would be a new
unproven surface. ADR-024: remove the dead path, keep the honest refusal.

- Delete `molecules/subject_strategy.rb`, `molecules/strategies/{full,chunked,adaptive}_strategy.rb`,
  their tests (`test/fast/molecules/subject_strategy_test.rb`, `strategies/*_test.rb`,
  `test/feat/adaptive_strategy_integration_test.rb`), `Errors::UnknownStrategyError`,
  the `subject_strategy` require in `review.rb`, the commented config block in
  `.ace-defaults/review/config.yml`, and the two unit-coverage references in
  `test/e2e/TS-REVIEW-001-review-workflow/scenario.yml`.
- CHANGELOG (package + root) documents the removal and the standing refusal.

## .3 pi token usage — measured only, explicit unavailable

Discovery (done, live pi CLI 0.87.1): `--mode json` assistant messages carry
`usage: {input, output, cacheRead, cacheWrite, reasoning, totalTokens, cost}`.

- `PiClient.normalize_usage`: map `input→input_tokens`, `output→output_tokens`,
  `cacheRead→cached_tokens`, `totalTokens→total_tokens`; absent stays absent (never 0).
- `PiClient.build_metadata`: measured-only — drop the `length/4` estimate fallback;
  tokens present only when the CLI supplied them; `usage_status: "measured" |
  "unavailable"` (unavailable includes pi version when cheaply known).
- `ace-llm` QueryInterface: derive top-level `usage:` from client metadata
  (`{model, input_tokens, output_tokens, cached_tokens, total_tokens}`, measured fields
  only; nil when none). Fixes `result[:usage]` for ALL providers (was always nil — the
  actual reason sessions said "usage unavailable"), making review's `usage_source`
  derivation work as designed.
- Tests: pi client mapping + unavailable path; QueryInterface derivation; review
  metadata usage_source.

## Verification

- `ace-test ace-review all`, `ace-test ace-llm-providers-cli all`, `ace-test ace-llm all`
  (bundle-exec mode, as CI runs them).
- Scripted two-round delta scenario (manual/e2e-style) before final delivery.

## Out of scope

- Verdict semantics changes; implementing chunking; exempt-path CLI override;
  pricing/cost model changes.
