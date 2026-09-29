# qk1.0 Implementation Report — forge-neutral worktree PR lifecycle

Task: `8wr.t.qk1.0` (parent `8wr.t.qk1`, foundation `8wk.t.l1e`)
Branch: `qk1.0-forge-neutral-pr-lifecycle` (worktree `.ace-wt/qk1-0-forge-neutral-pr-lifecycle`)
Exact reviewed head: **`72f2aa8542ce8c850f77aaac830d1d9f6f4b6194`**
Base: `main` (worktree branched from `02a9b7544`; main advanced independently to `9425eaf6d` during the session — no overlap with this slice's packages)

## Delivered surface

- **ace-git**: lifecycle evidence (`ProviderPullRequest` provenance fields, `ProviderPullRequestIdentity`, `ProviderMutationReceipt`, `ProviderCleanupProof` + `CLEANUP_PROOF_STATUSES`); classified failure taxonomy (`ProviderIdentityMismatchError`, `ProviderConflictingMatchesError`, `ProviderExpectedHeadConflictError`, `ProviderUnsupportedCapabilityError`, `ProviderUnknownOutcomeError`); `PrReference` atom (number / `owner/repo#n` / URL); `ServerRegistry.resolve_for`/`matching_servers`/`servers_for_owner_repo`; `PullRequestLifecycle` organism; `ace-git pr show|create|update|ready|merge` CLI with `--server`/`--default-server`/`--format json`; config-driven provider loading (`git.providers: [github, forgejo]`); shared `verify_expected_head!` guard in `Providers::Base`.
- **ace-git-github**: lifecycle parity — exact-match lookup, idempotent create reconciliation (created/existing/conflict/unknown-outcome), head-verified update/ready, atomic expected-head merge via `gh pr merge --match-head-commit`; fork head-repository URL provenance.
- **ace-git-forgejo**: lifecycle parity — `fj pr search` exact-match lookup, idempotent create with post-send reconciliation, head-verified `fj pr edit`; `ready` and `merge` are classified `ProviderUnsupportedCapabilityError` (fj offers no draft-to-ready command and no atomic expected-head merge precondition — per spec, refused rather than raced). Fork provenance from the `From \`owner/repo:branch\`` view segment.
- **ace-git-worktree**: PR checkout through `PullRequestEvidenceResolver` + `PullRequestCheckoutPreparer` (fetches the exact declared source repo/ref — fork or canonical — and proves the fetched SHA against evidence head before creating anything); task PR creation proves the pushed branch SHA (`expected_head`) through the neutral `PullRequestCreator`; `--server`/`--default-server` on create/cleanup with `--remote` kept as local-git-remote-only; cleanup digests bind server identity + per-item provider proof, and `--apply` recomputes the full report immediately before executing; removed all GitHub coupling (`ace/git/github` requires, `PrFetcher`, raw-`gh` `PrCreator`, gemspec dependency) with a standing `ForgeNeutralityTest` audit.

## Verification (executed 2026-09-28, in the worktree)

| Command | Result |
|---|---|
| `ace-test ace-git all` | 542 tests, 1335 assertions, 0 failures |
| `ace-test ace-git-github all` | 75 tests, 213 assertions, 0 failures |
| `ace-test ace-git-forgejo all` | 60 tests, 204 assertions, 0 failures |
| `ace-test ace-git-worktree all` | 534 tests, 1508 assertions, 0 failures (18 pre-existing skips) |
| `ace-test-suite` | 9709 passed / 2 failed / 22 skipped; 45/47 packages green |

**Suite failures are pre-existing, not from this slice** (verified by re-running both packages on the untouched main tree, where they fail the same way or worse):

1. `ace-review` — raw-`gh` coupling; on main it cannot even load (`cannot load such file -- ace/git/github`); in the worktree it loads via path deps and fails on real `gh auth status` in the test environment. ace-review's forge migration is qk1.1's scope.
2. `ace-test-runner` — `test_suite_config_includes_all_testable_packages` expects suite config to list `ace-lab`; fails identically on unmodified main.

## Scenario evidence (mapped to success criteria)

1. **Create by PR / by task across forges** — provider contract parity suites (`test/contract/provider_pull_request_lifecycle_contract_test.rb` in both provider gems) prove identical normalized evidence, idempotent create, stale-head, conflict, and unknown-outcome classification on scripted `gh`/`fj` fixtures; canonical vs fork source checkout proven against real temporary git repositories (`pull_request_checkout_preparer_test.rb`: matching-remote fetch with tracking, URL fetch without remote-ref pollution, SHA-mismatch rejection).
2. **Neutral lifecycle keeps identity, classifies failures** — shared `Ace::TestSupport::PullRequestLifecycleContract` (12 cases per provider) + `pull_request_lifecycle_test.rb` + `pr_test.rb` cover URL/selection mismatch-before-mutation, duplicate-match conflict, unsupported merge, unknown outcome with reconciliation identity; none claim success.
3. **Dry-run/no-pr/local-only perform no provider mutation** — PR dry-run never constructs the checkout preparer and passes `nil` checkout; `--no-pr` and dry-run task paths never construct the forge PR creator (flunk-guard stubs); local branch/traditional modes never resolve a server; `--no-pr` keeps task creation provider-free.
4. **Cleanup preview/apply preserves evidence** — provider proof statuses (`no_pr`, `open`, `closed_unmerged`, `merged`, `offline`, `authentication_error`, `malformed`) are distinct and only confirmed merged proof removes candidates; changed proof/server/digest invalidates the approved digest and refuses apply (`test_apply_recomputes_report_and_rejects_stale_digest`, `test_changed_provider_proof_invalidates_digest`); dirty/locked/primary protections untouched.
5. **No direct GitHub fetcher/dependency or raw gh/fj parsing in worktree correctness paths** — `forge_neutrality_test.rb` scans every library file and the gemspec; grep audit is clean.

## Notes for review (qkc / lab-overseer l2d.3)

- Forgejo capability gaps are classified, not guessed: `fj` v0.6.0 (per the forgejo-cli wiki) has no `pr create --draft`, no ready command, and no merge expected-head flag — all three surface as `ProviderUnsupportedCapabilityError` / non-draft evidence, matching the spec's "unsupported capability, not an unsafe fallback".
- `ace-git` gained `git.providers` config (default `[github, forgejo]`) so consumers no longer need direct provider-gem dependencies; provider packages register on require, lazily loaded on first resolution.
- Local-only isolation caveat: the orchestrator-level guard asserts the forge seam (PR creator construction) rather than `ServerRegistry` constants, because the group test runner's load path resolves a stale installed `ace-git` for that specific test file (verified consistent under `bundle exec`).

## Independent review (delivery gate)

- Reviewer: `ace-review --preset code-valid --model codex:astra:high --subject pr:347` (session `.ace-local/review/sessions/review-8wru69`, 2026-09-28).
- 6 findings (3 high, 3 medium); all 6 verified:
  - **Fixed in `0d104f869`**: bind every `gh` data/mutation command to the resolved server repository via `--repo` (GitHub half of 8wruavkr); create worktrees from the exact verified SHA instead of mutable `FETCH_HEAD` (8wruavks); refuse Forgejo fork-head PR creation before any command (8wruavkt); split Forgejo title/body edits into separate `fj pr edit` subcommands (8wruavkv); set + verify the PR worktree upstream and report it (8wruavku).
  - **Deferred to `8wr.t.uj0`**: Forgejo-side `fj` repository binding (no documented `--repo` on `fj pr` subcommands; needs the real surface on the lab) and authoritative Forgejo merge-commit proof (8wruavkw) — the conservative retain-without-proof behavior is the spec-mandated default.
- Gate re-run after fixes: ace-git 542, ace-git-github 75, ace-git-forgejo 62, ace-git-worktree 536 — all green.
