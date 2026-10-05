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

## Exact technical decision inventory for review

These are technical contract closures; they do not require a new product policy
or choosing between human preferences. Both execution-model and authenticated
reviewer identity must persist and be verified.

| Gap | Exact baseline source and types | Concrete alternatives and owner scope |
|---|---|---|
| Earlier execution receipt admission | `CampaignExecutionEvidence#review` lines 24–29 / `#approval` lines 32–39 consume `{attempt_id: String, digest: SHA256 String}` accepted references. `AttemptCoordinator#evidence` lines 767–782 requires a **succeeded managed attempt**, a coordinator-accepted receipt, `campaign == nil`, and exact `review-collect` or `review` operation. `Endcap::OPERATIONS` line 17 has no collection-admission operation; `accept_review_plan` lines 277–283 only permits review. Its authority_mutation is not itself a coordinator receipt_accepted/terminal transition. | Preferred review candidate: stage existing qjl-owned managed child execution attempts for check/collection/independent approval, accept their campaign-free execution receipts through authenticated existing coordinator ownership, then import those proofs into the parent campaign finish acceptance. Define exact child-to-parent subject/round/candidate binding and authorization before promotion. Alternative: extend the existing qjl evidence read/admission contract to validate nonterminal canonical execution subreceipts inside the parent journal, keeping final acceptance distinct; this changes the succeeded-attempt evidence rule and requires an explicit public contract. Neither alternative may treat Endcap's final approval mutation or upload as earlier executed proof. R2 owns integration across Review evidence adapters and Assign coordinator/Endcap; no new controller/journal or xz9.3 changes. |
| Report executor versus reviewer actor | `CampaignEvidence#approval` lines 188–201 reads `producer` / `reviewer` as Strings and compares `report.execution.model` String to reviewer. `CampaignExecutionEvidence#approval` lines 34–36 compares the same reviewer to `review.reviewer.actor` String. `Endcap` line 126 sets actor `uid-<UID>` from Integer reviewer_uid; lines 279–281 bind the receipt to that actor. `ReceiptVerifier#verify_campaign` lines 237–239 compares approval reviewer to receipt actor. | Preferred review candidate: retain `reviewer` as authenticated actor; add an explicit report-model selection bound to executed report references/model identities in R1 approval evidence, separate from actor. R1 validates report execution coverage, Assign validates actor/UID/process-purpose and binds that exact report set in the accepted execution receipt. Alternative: a structured reviewer object with distinct actor and executed model/report fields, replacing R1's current string API coherently (pre-1.0, no compatibility shim). Reviewer cannot select either field without executed/provenance verification. R2 owns R1 approval/session validation and existing receipt adapter integration; protected UID attribution remains unchanged. |

Independent review must select and complete the exact schemas/admission semantics,
not simply mark these gaps implementation details. Preferred candidates above are
proposals, not accepted requirements or claims of existing protected support.
