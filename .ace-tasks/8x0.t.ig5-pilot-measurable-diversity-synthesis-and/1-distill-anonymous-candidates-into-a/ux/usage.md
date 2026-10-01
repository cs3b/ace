# Distill anonymous candidates into a portable contract -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Portable handoff

**Action:** Run synthesis over completed manifests; open the frozen package in a fresh context.

**Expected:** Contract, architecture decision and referenced probes are sufficient without discovery conversations.

## Scenario 2: Unsupported claim

**Action:** A candidate claims a passing probe but supplies no execution evidence.

**Expected:** Claim stays unsupported; synthesis cannot upgrade it into demonstrated correctness.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.
