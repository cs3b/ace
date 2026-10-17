# Release-candidate status (gad.2) — preparation only, PUBLICATION NOT AUTHORIZED

Per Captain standing correction (3): release candidate preparation is
authorized; publication is NOT authorized. This document records RC state
and validation evidence only. No gem build/push/release actions were
performed.

## Versioned records (already merged to origin/main via reviewed PRs)

| Gem | Version | Delivered via | Validation evidence at exact merged head |
|---|---|---|---|
| ace-handbook | 0.35.1 | PR cs3b/ace#35 (b97e7b75f) | ace-handbook suite green: 82 tests / 603 assertions (R1 re-executed at exact head; report .ace-local/evidence/8wj-review/8x9xcv1-review-r1.md) |
| ace-git-worktree | 0.26.1 | PR cs3b/ace#36 (ba31afa7, re-based 1a8fa820) | package suite green: 549 tests / 1594 assertions (reviewer re-executed, report 3808bd27; red/green regression evidence 0a72376d → e6c9088f → 27c6d59d) |

## RC status

- ace-handbook 0.35.1 and ace-git-worktree 0.26.1 are versioned, changelogged,
  and integrated into origin/main through reviewed, host-integrated PRs.
- Candidate validity: commits at exact integrated heads; both packages green
  at those heads under the canonical bundle.
- NOT done (unauthorized / out of scope): gem building, tagging, changelog
  final-release squashes, RubyGems publication, install acceptance.

## Limitations carried into RC status

- Monorepo full-suite (ace-test-suite --target all): UNRESOLVED failures +
  ace-assign 442s stall (see fullsuite-correction.md). No full-suite pass
  supports these candidates; package-level evidence only.
- Live install acceptance of the repaired ace-git-worktree on downstream
  consumers has not been performed (only source-tree demonstration on real
  Lab).
