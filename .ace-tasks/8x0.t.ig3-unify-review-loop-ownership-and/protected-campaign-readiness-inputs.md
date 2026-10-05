# Protected campaign readiness inputs — author analysis, 2026-10-05

Baseline: `85c9704fe`. Scope is specification only; no runtime/tests/native probe,
provider transmission, deployment or auth change was executed. This document is
not an independent readiness verdict. Task remains draft / needs_review.

## Closed proposed decisions

The companion contract fixes the canonical owner (existing CampaignManager /
CampaignStore), protected deployment mapping, stable subject context, existing
Assign import kind/owner, receipt normalization and pending/committed reads,
expected identity/policy tuple, proposed source method, fixed composition,
lock order, restart behavior and mandatory acceptance matrix. Worker paths,
worker-local stores, journal_repository lookup and a second controller/journal
are explicitly excluded. R1 and qkb retain existing ownership; R3 dependencies
and xz9.3's independently executable result scope are preserved.

## Source gaps requiring independent decisions before promotion

1. **Non-circular executed evidence producer.** R1's
   `CampaignExecutionEvidence#review` reads kind `review-collection`, mapped by
   `AttemptCoordinator#evidence` to operation `review-collect` and executed check
   `review-execution`. Its approval reads kind `review-approval`, mapped to
   operation `review`. The existing protected Endcap accepts only its final
   assigned `review` receipt; it exposes no protected `review-collect` receipt
   producer. The final campaign-bearing receipt cannot attest the earlier
   approval required to produce itself. Decide whether existing authenticated
   reviewer receipt ingress is extended to accept those two existing distinct
   execution purposes before campaign finish, or identify a real already-owned
   producer that supplies them. This is required owner integration within R2,
   not an imaginary campaign service or an xz9.3 prerequisite. Until decided,
   positive protected campaign acceptance must remain closed.
2. **Executed model versus authenticated reviewer identity.** R1's
   `CampaignEvidence#approval` requires report execution model equal to approval
   reviewer; protected `Endcap` records `reviewer_actor` as `uid-<UID>`, and
   ReceiptVerifier requires approval reviewer equal to receipt actor. Current
   source therefore cannot identify a provider model and OS reviewer actor as
   the same value. Decide an explicit provenance-preserving separation of
   executed report model from authenticating independent reviewer actor, owned
   by R1's approval validation and the existing qjl receipt attribution. Never
   replace executed model evidence with a caller assertion, or weaken independent
   actor/UID enforcement. Specify that distinction before implementation.

These are actual code incompatibilities, not speculative implementation choices.
The companion API/mapping proposal is reviewable, but it alone cannot honestly
close readiness. No new task or implementation has been created for them.

## Independent review checklist

- Validate the two decisions above against public existing execution receipt
  semantics; record exact ingress/purpose and field equality changes.
- Confirm installed campaign roots and registered subject are selected by the
  existing authority/deployment owner, and no worker config supplies them.
- Confirm candidate head/base/generation and current policy are revalidated in
  the same acceptance transaction; inspect proposed lock order for reentrant
  CampaignStore calls and qjl readers to avoid deadlock.
- Verify pending and committed CanonicalEvidence contexts are identical and
  imported campaign result remains kind review with authenticated attribution.
- Verify historical byte visibility does not imply live acceptance, and missing
  store/index has no worker/journal-repository fallback.
- Confirm no cycle: qkb delivers existing provider-neutral consumers first; R2
  integrates them later. xz9.0 keeps campaign-free source checkpoint; R3/final qkc
  require R2. xz9.3 source/spec remains unchanged.
- Judge acceptance matrix completeness using actual owner objects and public
  interfaces. No specification-only record claims executed proof.

## Source references

- `ace-review/lib/ace/review/organisms/campaign_manager.rb`
- `ace-review/lib/ace/review/molecules/campaign_store.rb`
- `ace-review/lib/ace/review/molecules/campaign_evidence.rb`
- `ace-review/lib/ace/review/molecules/campaign_execution_evidence.rb`
- `ace-review/lib/ace/review/atoms/campaign_contract.rb`
- `ace-assign/lib/ace/assign/authority/endcap.rb`
- `ace-assign/lib/ace/assign/molecules/canonical_evidence.rb`
- `ace-assign/lib/ace/assign/molecules/receipt_verifier.rb`
- `ace-assign/lib/ace/assign/organisms/attempt_coordinator.rb`
- xz9 family `protected-authority-contract.md` and xz9.3 task/usage contract.
