# PR #398 — review round 2 response (readiness findings F1–F11)

Date: 2026-10-30. Reviewer verdict under review: REQUEST CHANGES
(`.ace-local/review/pr398-readiness/readiness.md`, candidate `55e14f6b5`).
This record answers every confirmed finding with code, tests and commits.

## Findings → fixes

| Finding | Fix | Commit |
|---|---|---|
| F1 gemset `default: V` versions | `parse_versions` normalizes the RubyGems default-gem format (`json (2.9.4, default: 2.9.1)`), fails closed on non-version parts; real isolated-GEM_HOME probe + fake-runner tests | `912713880` |
| F2 lab overseer + project spaces | `lab_start` boots the lab's OWN overseer session in `overseer-lab`; each project boots in its OWN space (titled by session label, created/reused lazily); report carries pane + per-project workspace ids. herdr spaces are flat — the lab flow owns the sibling spaces (documented in usage.md) | `cc4e2bf40` |
| F3 first turn | `boot_session` sends `agent_prompt` (FIRST_TURN_PROMPT mirroring the guides' "First turn after start") right after `agent_start`; reused sessions are never prompted | `cc4e2bf40` |
| F4 installed mode | `resolve_instructions` selects ace-nav via `Ace::Support::Cli::Toolchain` — installed mode always the installed launcher, unavailable = blocked, never a checkout fallback; `ProviderRegistry#resolve_named_package` skips the checkout dir in installed mode | `cc4e2bf40` + `ae7584842` |
| F5 GitHub revoke | `DELETE /installation/token` authenticated with the ISSUED token (plugin contract now `revoke(profile:, token_ref:, token:)`), `curl -f`; 401 → `:already_invalid`, anything network-shaped → `OutcomeUnknownError`, never a false `:revoked` | `912713880` |
| F6 interrupted handoff | failed `CredentialHandoff#deliver` transitions the record to `revoke-pending` (not live); retry mints a fresh lease; reconcile finishes the pending record by token_ref | `912713880` |
| F7 mismatched retry scope | the requested scope is computed before the live lookup; a live lease with different repos/principal is REFUSED (`Refusal`), idempotency holds only for the identical request | `912713880` |
| F8 stale-body suggestion write | `add_suggestion`/`add_lesson` run the whole read-validate-write cycle under one exclusive lock against current content (`rewrite_case`); regression test lands a reply through the lock window and proves the human decision survives | `276b73b25` |
| F9 terminal-case late writes | shared rule (`refuse_terminal!` + `TerminalCaseError`): closed/cancelled cases never accept a NEW answer or suggestion; identical-answer replay stays an idempotent no-op; the locked write re-checks (TOCTOU test) | `276b73b25` |
| F10 second-captain `{{case}}` | `{{case}}` placeholder + `--hitl-case CASE_ID` on commission; a per-case preset without a case is REFUSED (never silently rendered); the written config records `case` | `a3adb7f55` |
| F11 integrator gate docs | integrator.wf.md and README carry `--tests-head` (required with test evidence) | `a3adb7f55` |

Feedback items from the provider review session (review-8xtdxi): all 13
archived — 8xte508a/c/d/f/g/h/i resolved with the fixes above (hitl),
8xte508b/e and 8xte508k resolved with the overseer work. No pending items.

## Verification

- `bin/ace-test`: ace-lab 636 (0 fail, 4 skip), ace-handbook 67, ace-overseer
  410 (0 fail, 1 skip), ace-hitl 401 (0 fail, 5 skip), ace-coworker 404 —
  all green at the new HEAD.
- Post-fix verification probes
  (`.ace-local/review/pr398-readiness/flow_test_post_fix.rb`): 9/9 pass.
  They adapt the reviewer's expectations to the fixed contracts: the F8
  interleaving hook (stub `HitlSuggestionEditor.apply`) can no longer inject
  between read and lock — that window no longer exists, so the concurrent
  reply is landed deterministically by holding the case lock; F7 now refuses
  (the reviewer's accepted repair); F5 is probed on real curl exit shapes
  (22/401 → `:already_invalid`, 7 → outcome-unknown). The reviewer's
  original `flow_test.rb` probes F6/F7 semantics through the service; the
  equivalent behavior is covered by the in-suite tests above.

## Explicitly still open (per the reviewer's own ordering)

- Hermes → reply transport on the host/lab (producer side) — deferred to
  host/lab as progress .5 records; not claimable from this repo alone.
- Host revoke scheduler; live publication; cold-cycle acceptance on the lab.
- Full review convergence over the whole PR delta at the new HEAD (the two
  earlier packets mis-describe coverage — 77 changed files were skipped;
  re-review must use fresh, complete ranges).
