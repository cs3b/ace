# Independent review: protected campaign draft contract

Reviewed author commit `623cba4cdb3064147ef4ef3aeb3b5d951d6eaa3c` against baseline `85c9704fe` in `/Users/mc/Ps/ace-protected-campaign-contract`, 2026-10-05.

## Verdict

**Approve integration as a draft contract and accurate research/open-question record. Not approved for implementation readiness or task promotion.** Keep ig3 `draft` / `needs_review: true`. No actionable defect was found that blocks integrating these four specification files in that state.

The review followed `.agents/skills/as-task-review/SKILL.md` and the loaded task/review workflow, limited by the explicitly authorized independent specification review: no author edits, task metadata mutation, tests, probes, authentication or deployment work. No additional agents were delegated and no blocked native probe was retried.

## Verified source claims

- CampaignManager is the existing campaign owner. Its constructor and start/record_round/status/finish interfaces are present (`ace-review/lib/ace/review/organisms/campaign_manager.rb:19,27,82,146,152`). CampaignStore owns the retained store and flock transaction (`campaign_store.rb:20`). The proposed `verify_result!` method and protected deployment roots are clearly labeled future requirements, not installed support.
- ReceiptVerifier presently constructs CampaignManager from `repo_root` (`ace-assign/lib/ace/assign/molecules/receipt_verifier.rb:223–239`). Endcap passes the journal repository to that verifier (`authority/endcap.rb:316–317`). Therefore canonical artifact-reader injection alone does not resolve the campaign-owner seam.
- Endcap imports kind `review`, normalizes both artifacts and campaign.result, and verifies pending imported bytes before acceptance (`authority/endcap.rb:288–317`). CanonicalEvidence has distinct pending and committed read interfaces. The draft preserves those owners and wire framing rather than inventing a campaign service/import kind.
- Earlier executed-evidence ingress is a real unresolved incompatibility. CampaignExecutionEvidence consumes accepted collection and approval references (`campaign_execution_evidence.rb:24–39`). AttemptCoordinator requires a succeeded managed attempt, coordinator-accepted receipt, campaign-free receipt and exact operation (`attempt_coordinator.rb:767–782`). Protected Endcap's final `accept_review` authority mutation is not that coordinator terminal/receipt transition, and its operations omit collection admission (`authority/endcap.rb:17,277–283`). A final campaign receipt cannot prove the earlier approval needed to generate itself.
- Model versus actor is also a real incompatibility. CampaignEvidence compares executed report model to approval reviewer (`campaign_evidence.rb:188–201`); CampaignExecutionEvidence compares that reviewer to receipt actor (`campaign_execution_evidence.rb:34–36`); Endcap derives `uid-<UID>` (`authority/endcap.rb:126,279–281`); ReceiptVerifier compares campaign approval reviewer to receipt actor (`receipt_verifier.rb:237–239`). Both executed model provenance and authenticated independent actor must remain verifiable.

## Intent and dependency preservation

The four-file diff preserves R1 history/dispositions, R2's one repair owner, explicit sessions/worktrees, configuration provenance, stricter consumer gates, authorization and recovery, and R3's mandatory downstream foundation. It adds explicit protected acceptance requirements rather than substituting the xz9.0 campaign-free checkpoint for whole-program completion.

No new R2-before-qkb dependency is introduced: the contract explicitly says qkb delivers its existing provider-neutral consumers first and R2 subsequently integrates them. This matches qkb's existing ordering statement and R3's ig3 dependency. xz9.3 is neither modified nor made responsible for this seam.

The two research alternatives for each unresolved gap are plausible proposals, not claims of available functionality. Managed campaign-free child attempts preserve the existing succeeded-attempt evidence model, provided the documented exact child/parent subject/round/candidate authorization is completed. Nonterminal subreceipts deliberately change that model and require the explicit public admission contract the draft requests. Both identity alternatives preserve actor independence and executed report/model provenance when completed; neither authorizes a caller assertion as proof.

## Required closure before readiness

1. Select and specify the exact authenticated, non-circular collection/check/approval execution-receipt admission and read semantics, including child/parent or subreceipt binding and terminal behavior.
2. Select and specify the exact actor/model/report schema and corresponding R1 and Assign equality checks.

The proposed locking contract also needs the already-listed implementation review of reentrant store calls: current CampaignStore opens a fresh flock descriptor per transaction, while status/finish acquire transactions themselves. Holding an outer store transaction and naively calling those interfaces is not an established safe composition. The draft explicitly requests that check, so this is a recorded readiness obligation rather than an unreported claim of existing safety.

No executed acceptance evidence was generated. The mandatory positive, isolation, forged-result, restart, drift/corruption, race/replay and historical-visibility matrix is an implementation requirement; provider stubs or this review cannot satisfy it.
