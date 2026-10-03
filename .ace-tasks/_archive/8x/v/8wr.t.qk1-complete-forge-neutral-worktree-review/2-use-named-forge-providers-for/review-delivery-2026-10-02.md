---
step: '170'
name: review-pr
completed_at: '2026-10-02T20:34:33Z'
---

# Step 170 — convergence review: final state

## Outcome

Review convergence achieved in substance; campaign bookkeeping is structurally
blocked by ace-review's hard packet budget. Decision on merge handed to the
Captain (per the merge gate: executed tests + independent reviewer verdict).

## Campaign 8x128u (delivery-v1, PR cs3b/ace#359)

- 16 completed rounds, clean streak 8, independent approval recorded on r86
  (reviewer gpt-6-sol, tests check receipt accepted) at head 887e7328b.
- `campaign finish` is rejected for two reasons:
  1. Three historical High findings carried stale non-terminal dispositions
     (open/skip from rounds predating the terminal-status convention). Their
     source feedback files are now terminal (invalid/invalid/done + resolution).
  2. Current-evidence requires a fresh completed round at the live head — and
     the full-PR review packet no longer renders: ~406 KB, ~128.8k conservative
     tokens vs ace-review's hard 128,000 input budget (atoms/prompt_budget.rb,
     explicitly non-configurable). Delta references are rejected for full
     scope; diff subjects are forced to span base..head (same packet); the
     successor campaign 8x1upi (started with a changes-scope policy and reason)
     hits the identical wall for the same reason.

## Review coverage (complete)

- Full-PR independent reviews: rounds r4 through r86 (16 recorded rounds,
  60+ sessions over the campaign lifetime; 30+ distinct full reviews).
- Executed review sessions at every subsequent head: 887e7328b (r87),
  315d6012b (r88), e8ce7afe7 (r89), b5ce5476d (r91).
- Final plain delta review review-8x1uqw covering 887e7328b..b04b5dcbd (the
  only commits without campaign sessions): 0 High, 1 Medium (label-ensure
  error-reporting polish, dispositioned pending).

## Defects found and fixed during convergence (r65-r92, all with tests)

1. Forgejo label ensure-create on fresh repositories (+403/404 org-label fallback)
2. Post-create definitive-looking failures no longer clear the create guard (duplicate-POST class)
3. Issue identity locks held across task relocation (parent and descendants)
4. GitHub label ensure-create with lookup-first flow
5. Canonical (provider+web repo+number, case/scheme-normalized, digest-keyed) issue lock and ownership identity
6. Parent/child lock acquisition ordering (up-front sorted sets incl. archive parent)
7. Post-create IdentityMismatch retains task/link/subtask as cleanup record
8. Pending-clear previous-ID persistence across reparent
9. Clear intent persisted before reconciliation + replay honoring the create guard
10. Pending clear completes after authoritative create absence
11. issue_sync_reconcile_create honored in create_pending (no duplicate POST on replay)
12. macOS bundle-dir fj credential paths (forgejo-cli.forgejo-cli / Cyborus.forgejo-cli)
13. Scheme-less server URL ports preserved; gh api --slurp+--jq incompatibility removed

## Open items (all pending Mediums, recorded in campaign findings)

1. Nested descendant ID format contract (reparenter emits grandchild IDs the
   single-segment validator rejects; doctor scans direct children only) —
   needs an ID-format follow-up task.
2. fj keys file `hosts: null` escapes as NoMethodError instead of a classified
   ProviderAuthenticationError.
3. GitHub label-ensure error-reporting polish (lookup/creation failures may
   surface only through the attach error).

The canonical "duplicate POST after bounded-absence retry" concern was
dispositioned invalid ~30 times: designed trade-off absent forge-side
idempotency keys; read failures keep the guard, only authoritative absence
authorizes the documented identical-link retry.

## Tests

- Touched packages green at HEAD 315d6012b+ (ace-git 554, ace-git-github 81,
  ace-git-forgejo 104, ace-task 493; 2 pre-existing skips).
- Full mono-repo suite green except ace-assign's suite-runner 120s parallel
  cap timeout (passes standalone: 755 tests, 0 failures; source identical to main).

## Asks to the Captain

1. Merge decision on the recorded evidence (recommended: review substance is
   complete; every commit has executed independent review coverage; tests green).
2. If campaign acceptance is required first: the packet budget in ace-review
   (hard 128k, currently non-configurable) needs a deliberate change (ADR) and
   a fresh full round; or a per-package multi-scope successor design.
3. Gem publishing remains withheld (batched post-merge per delivery protocol).

