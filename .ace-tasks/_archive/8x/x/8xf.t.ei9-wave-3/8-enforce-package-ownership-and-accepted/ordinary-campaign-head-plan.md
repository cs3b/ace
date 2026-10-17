# Ordinary campaign ownership and accepted-head assessments

Approved contract, source base `8ccd84d50`; isolated `codex/ei9-ordinary-campaign`.
No deployment, publication, external messages, blocked Hermes work or installed
runtime dependency-profile work is included. Installed acceptance stays open.

## Source facts

- `ace-review` CampaignManager/Store already own campaign identity, append-only
  attempts/rounds/findings, finite phases and provider retry reservations. Reuse
  them; Assign remains the sole execution journal.
- CampaignManager.with_verified_result! validates current accepted snapshots;
  verify_retained_result! validates original heads and canonical execution after
  later changes. CampaignEvidence takes source-owned check/review/approval readers
  and validates provider/model completion plus all original artifact digests.
- CampaignPolicy preserves discovery/delivery limits, clean streak, recurring
  blockers and unknown-execution retry refusal. Head assessment never adds a
  round, resets these counters or authorizes new provider attempts.
- CampaignManager currently requires exact current head/base. Its head_transitions
  are observations only. Finding assessments support repair/severity changes;
  there is no implemented nonsemantic head-carry authority to call.
- OrdinaryReviewEvidence now provides actual native producer/reviewer origins,
  exact candidate refs and imported receipts. Direct acceptance deliberately
  refuses campaigns until this join exists. Protected Endcap campaign mapping,
  reservation generation and launch tickets are not ordinary identities.

## Owner and interface contract

1. Compose the existing CampaignStore/Manager into the installed ordinary owner,
   with private artifact/store directories and a held root-selected
   CampaignConsumerPolicy reference. No local ambient campaign fallback.
   Register the exact campaign/contract/policy association against the running
   canonical delivery attempt, preserving source-owned native origin.
2. Source-owned callbacks resolve ordinary accepted review events and immutable
   original report bytes at the exact journal prefix. Command test callbacks use
   the existing real root-witnessed CommandExecution receipt. No fake protected
   campaign_execution children, actor aliases or worker check assertions.
3. Extend CampaignEvidence with an explicit source-owned independence validator
   for actual native process/session origins; retain actor inequality as the
   default for all existing protected/local callers. Existing report execution
   metadata and findings remain required for campaign rounds.
4. Add a closed append-only head assessment to the SAME campaign history. It
   binds prior accepted snapshot identity, original reviewed head/base, current
   candidate acceptance ref/head/base/tree, owner-derived complete bounded diff
   and context inventory/digests, classification, bounded rationale, fresh target
   test references, and current canonical supervisor identity. Caller labels alone
   cannot attest diff completeness. Compare the canonical source bundles through
   CandidateTransfer's bounded lifetime-scoped read view.
5. `nonsemantic` may carry the prior independent report only after complete
   contextual/risk assessment and successful current-head tests. `substantial`
   and `uncertain` require an actually executed independent delta review bound to
   exact original/target heads and full affected scope. Missing/incomplete/corrupt
   or revoked evidence refuses. Patch-id or unchanged label alone never approves.
6. Include the head-assessment prefix and evidence bindings in accepted snapshot
   identity. Historical readers retain original reviewed heads/artifacts; current
   readers validate current accepted head, policy and cancellation. Do not rewrite
   old receipts or count an assessment as a completed review round.
7. Replace the obsolete fixed acceptance reference with a versioned contract that
   distinguishes `reviewed_head` from `accepted_head` and binds the assessment
   chain. Merge guard/Forge head precondition selects accepted_head. Direct review
   has equal values. No compatibility fallback or false current-head review claim.
8. Hold the existing ordinary lifecycle exclusion before campaign store and
   journal CAS locks. Validate source references within the same scope/prefix;
   keep exact mutation IDs and reconcile lost replies without duplicate rounds.

## File ownership

This slice owns CampaignManager/Store/Evidence and related pure contracts/tests,
new ordinary campaign composition/operation/evidence module, owner configuration
selection, acceptance-reference schemas/consumers, and a minimal bounded diff read
on CandidateTransfer::CampaignReadView. The materializer author owns CommandPolicy,
CommandOwnerAdmission and CommandExecutor plus with_candidate_reference resolver;
no copying or editing their WIP. Compose from committed shared changes only.

## Acceptance responsibilities

- Pure campaign tests: finite budgets unchanged, counters survive head moves,
  unknown execution retains original ID, historical head/checks survive current
  changes, assessments cannot erase findings or manufacture completed rounds.
- Source-view tests: incomplete/oversized/missing Git objects refuse; exact
  context/diff digest derives from canonical bundles, not caller paths.
- Ordinary Unix/Git integration: actual accepted native origins, same-account
  independent sessions, canonical report imports, current-head root test proof,
  supervisor assessment, nonsemantic carry, material/uncertain delta requirement,
  policy/cancellation/restart/replay refusal and preservation.
- Consumer tests: reviewed_head remains original, accepted_head matches exact
  Forge target; forged assessment-chain digest and stale candidate refuse before
  effects; protected strict defaults remain intact.
- Source closure requires bin/ace-test and fresh actual configured Pi verdict.
  Root owns integrated broad suite, versions and eventual installed acceptance.
