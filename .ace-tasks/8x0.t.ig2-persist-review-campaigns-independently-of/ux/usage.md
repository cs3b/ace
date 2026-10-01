# Persist review campaigns independently of head receipts -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Resume across HEAD

**Action:** Record a verified round at H1; observe H2; request campaign status from a fresh process.

**Expected:** History is intact; H1 evidence is stale for H2; acceptance is false until required current evidence exists.

## Scenario 2: Replay or incomplete report

**Action:** Submit the same completed round twice, then submit conflicting or incomplete evidence.

**Expected:** Identical replay does not increment counters; conflict fails; incomplete work remains an attempt, not a clean round.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.

## Scenario 3: Existing CLI and campaign dry-run

**Action:** Exercise existing local/PR review entrypoints with repeated subject/model/evidence flags, then `ace-review campaign start --subject subject.json --contract requirements.md --profile delivery --dry-run`.

**Expected:** Existing entrypoints retain their current semantics; campaign dry-run validates inputs without creating a campaign, executing models or changing Git. Empty contract and malformed/mixed subject identities fail.

## Scenario 4: Mixed heads and concurrent recording

**Action:** Record two required module reports bound to different heads; concurrently replay a complete same-head round with the same ID.

**Expected:** Mixed-head reports do not form a complete round. Identical valid replay counts once; conflicting content fails without losing the accepted record. Status JSON exposes stale evidence separately from preserved history.
