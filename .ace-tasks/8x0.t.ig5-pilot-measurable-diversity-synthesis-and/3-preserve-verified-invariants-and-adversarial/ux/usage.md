# Preserve verified invariants and adversarial probes -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Reusable verified invariant

**Action:** Export the confirmed early-ownership-release finding and its reproduction.

**Expected:** Catalog records physical completion invariant, version constraints, source evidence and positive/negative controls.

## Scenario 2: Unsupported or stale entry

**Action:** Try importing an unverified suggestion or incompatible-version probe.

**Expected:** It is rejected or explicitly inapplicable; it cannot become acceptance evidence.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.
