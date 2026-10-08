# Unify review loop ownership and effective policy -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: One repair owner

**Action:** Run an assignment whose review yields two independent verified Medium findings.

**Expected:** One inventory and repair batch, one focused verification, terminal dispositions and a single consumed outcome.

## Scenario 2: Resume worktree session

**Action:** Restart from a linked worktree after review; continue feedback using the recorded session.

**Expected:** Correct session resolves without ad-hoc API workaround; mismatched repository input fails.

## Scenario 3: Absent authorization

**Action:** Request a delivery outcome without authority for a required external action.

**Expected:** Status identifies the blocked action; no action is executed or inferred from silence.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.

## Scenario 4: Shared store and receipt path boundary

**Action:** Complete a bound session in the repository's shared store; consume it in the owning linked worktree, while a second PR has a newer session.

**Expected:** Automation uses the explicit first session, materializes verified immutable receipt artifacts inside its worktree, and preserves source provenance. Another PR's session or a symlink/traversal escape is rejected; the existing receipt verifier's path rules remain intact.

## Scenario 5: Conflicting policy before execution

**Action:** Compose a consumer requiring more completed rounds than its permitted execution cap, or two automatic repair owners for the same review stage.

**Expected:** Preflight reports the source of the incompatible settings/owners and starts no provider or repair operation. An explicitly requested standalone feedback command remains usable.


## Protected campaign consumption amendment (draft)

An assignment review consumer supplies its exact accepted campaign/result and
canonical candidate to the existing protected owner. R2 ig3 must resolve the
existing CampaignManager authority's repository/worktree/session/policy identity
and verify immutable canonical imported artifact bytes. The current xz9.0
checkpoint refuses campaign-bearing receipts; this is not R2/R3 completion.

Wrong worktree, stale candidate/result, revoked policy, missing authoritative
campaign or a worker-forged accepted result refuses. Neither worker-local
.ace-local files nor journal_repository can stand in for campaign authority.
The exact proposed mapping, source API and import schema are specified in
`../protected-campaign-contract.md`; readiness gaps are explicit in
`../protected-campaign-readiness-inputs.md`. Task remains draft / needs_review.


## Scenario 6: Protected exact campaign lookup

**Action:** The mapped independent reviewer submits the bounded review receipt
with `campaign: {id, result: {path, sha256}}` and the same result in `artifacts`.
The existing authority resolves registered subject/candidate generation and
imports bytes through CanonicalEvidence before CampaignManager validation.

**Expected:** Current accepted campaign, policy, head/base, completed round/session
and independent attribution match. Only the existing journal CAS accepts the
receipt. A worker-selected campaign path or forged finish JSON fails without a
canonical accepted receipt. The source-only proposed `verify_result!` method is
not an installed CLI command.

## Scenario 7: Restart and historical evidence

**Action:** Restart authority, fetch an authorized exact retained artifact after
candidate advance, then attempt fresh acceptance using that old result.

**Expected:** Historical bytes remain retrievable under xz9's exact purpose and
current visibility authorization. Fresh acceptance refuses stale generation,
head/base or policy. Missing R1 store/index requires retained-owner restoration;
worker `.ace-local` files and campaign records beside the journal are never used.


## Scenario 8: Accepted execution children precede campaign finish

**Action:** The authenticated launcher registers collection/check/approval managed
child definitions bound to the parent's exact round/scope/head/base/generation.
Each child selects its own captured numeric prepared subtree (for example 010);
its receipt scope matches that selection, while parent_scope remains separate.
Real child workers submit campaign-free results; independently assigned reviewer
processes admit exact direct reviews; launcher/supervisor finishes each child
using protected cleanup/no-writer proof.

**Expected:** R1 consumes only succeeded accepted child receipts at their exact
canonical commits. Wrong parent/phase/round/operation/generation is rejected.
Approval persists authenticated reviewer actor separately from `report_models`;
model text never replaces UID/actor independence. Parent campaign finish waits
for these earlier accepted proofs. Missing 9c2 proof keeps child finish blocked.

The exact source API is the proposed single-transaction
`CampaignManager#with_verified_result!(...) { |projection| ... }`, specified in
`../protected-campaign-technical-closure.md`; nested status/finish calls are
forbidden while its store lock is held. This is not an installed CLI command.
