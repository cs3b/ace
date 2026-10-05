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
The exact source-owned protected lookup schema awaits this amendment's readiness
review; task is reopened draft / needs_review, preserving historical reviews.
