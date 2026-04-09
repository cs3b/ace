---
id: 8r8m9r
title: e2e-fix-loop-stalled-on-scenario-contract-drift
type: standard
tags: []
created_at: "2026-04-09 14:50:51"
status: active
---

# e2e-fix-loop-stalled-on-scenario-contract-drift

## What Went Well

- We eventually identified the real dominant failure mode: false positives from missing or synthetic evidence, not widespread product regressions.
- The suite is now much closer to a behavior-first model: required artifacts were reduced, support artifacts were downgraded, and many brittle verifier expectations were removed.
- The guide and E2E workflows are now aligned on the same artifact taxonomy and failure-analysis rules, which was missing at the start of the loop.
- Canonical failed-TC identity was tightened around `summary.r.md`, which removed one major source of drift during repeated reruns.

## What Could Be Improved

- We tried to fix too many reds by editing scenario files before stabilizing the harness signal, so we kept patching symptoms on top of incomplete runner evidence.
- The suite mixed three different problems:
  - runner did not emit deterministic evidence
  - verifier/spec expected stale or synthetic proof
  - some scenarios had real behavior mismatches
  We did not separate those layers early enough.
- Several fixes were scenario-local when the real issue was scenario-family or harness-level, so reruns surfaced a different TC in the same scenario and made progress look fake.
- The old suite design had been implicitly tuned to one agent style, so Codex exposed hidden artifact-choreography assumptions that were not obvious while the suite still looked green.
- Missing-artifact failures were too opaque. When a TC produced nothing, the report said “missing files” but did not prove whether the runner started, what it attempted, or where execution stopped.

## Key Learnings

- The problem was not mainly “Codex cannot name files correctly.” The real issue was that many scenarios encoded hidden artifact contracts that one model happened to satisfy more often than another.
- Verifier intelligence helps only after the runner contract is deterministic. A smarter verifier on top of incomplete or synthetic evidence just makes the diagnosis more confident, not more correct.
- The correct strengthening direction is:
  - deterministic per-TC execution manifests
  - minimal required evidence
  - semantic verification over state and command output
  - explicit distinction between behavior failure and evidence failure
- Scenario-wide review is mandatory before editing a red scenario. Fixing only the currently named TC misses shared contract drift and creates the illusion that the fix “did nothing.”
- Suite-level reports are useful for trends, but scenario summaries and per-TC artifacts remain the canonical source for exact failure identity and diagnosis.

## Workflow Proposals

- Add deterministic per-TC meta-artifacts for every pipeline run:
  - `tc.start.json`
  - `commands.ndjson`
  - `artifacts.json`
  - `tc.final.json`
- Keep two failure axes in reports:
  - `behavior-status`
  - `evidence-status`
  so missing artifacts stop looking like product regressions.
- Treat the following as different queues, not one generic red list:
  - harness/evidence failures
  - scenario/spec contract failures
  - real behavior regressions
- When a scenario stays red after a fix, force a full scenario review before any more edits, even if only one TC is named in the report.
- Use recurrence-aware suite summaries so repeated `artifact-incomplete` failures are surfaced as harness debt, not as a fresh scenario bug every run.

## Action Items

- Finish the harness changes that make per-TC manifests and failure axes first-class in `ace-test-runner-e2e`.
- Re-run the still-problematic scenarios only after the stronger manifests are in place, so the next failures identify the correct layer.
- Review the remaining red scenarios by family:
  - stateful workflow
  - provider-live
  - filesystem/git
  and remove any last required support artifacts.
- Keep future E2E rewrites short and behavior-first: command captures plus one or two real state oracles, nothing more.

## What Could Be Improved

## Action Items
