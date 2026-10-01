# Deliver final candidates with authorized model escalation -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Final candidate delivery

**Action:** Supply a valid synthesis package and ready configured roles to the pilot assignment.

**Expected:** One fresh final candidate enters full delivery and receives independent review.

## Scenario 2: Missing family or authority

**Action:** Remove DeepSeek readiness or omit Astra authorization when escalation is required.

**Expected:** Explicit blocked setup/escalation; no silent fallback or expensive launch.

## Scenario 3: No merge authority

**Action:** Finish all implementation/review checks without merge authorization.

**Expected:** Candidate remains ready for the applicable approval step; no merge or deployment.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.
