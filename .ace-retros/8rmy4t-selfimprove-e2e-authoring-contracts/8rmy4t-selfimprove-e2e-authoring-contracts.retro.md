---
id: 8rmy4t
title: selfimprove-e2e-authoring-contracts
type: standard
tags: [self-improvement, process-fix, e2e]
created_at: "2026-04-23 22:45:22"
status: active
---

# selfimprove-e2e-authoring-contracts

Date: 2026-04-23
Context: Applied after the three-batch E2E recovery retro and the follow-up handbook/runner contract update for retained E2E authoring.

## What Went Well

- The self-improvement was implemented at both layers that mattered: handbook/workflows and runner enforcement. That avoids the usual failure mode where the docs say one thing and the loader silently permits something else.
- Adding exact artifact-contract validation in `ace-test-runner-e2e` reduced the migration surface sharply once grouped capture shorthand was parsed correctly. After the parser fix, only four real scenario contracts needed updates.
- The resulting rules are simpler to explain and review: runner/setup declare the evidence, verifier consumes it, wildcard references are invalid, and retained deterministic TCs are a first-class style instead of an accidental loophole.

## What Could Be Improved

- The original handbook language was too absolute about “only real outcomes under results/”, which pushed scenarios into awkward verifier-only files or hidden helper manifests instead of a clear declared-evidence model.
- The current E2E process still relies on prose and spot-checks for some higher-level quality rules, especially downstream retained-suite sweeps after public contract changes. The workflow now requires this, but there is not yet a dedicated automation helper for it.
- Provider-backed scenario verification can still be slow enough to make process-change validation expensive. `ace-sim TS-SIM-001` loaded cleanly in dry-run but full execution stalled long enough that the validation had to stop short of a full green rerun.

## Action Items

- Keep the new two-style vocabulary in future E2E review output: `public-surface` vs `retained-contract`.
- Treat verifier-only artifact references and wildcard artifact paths as immediate contract bugs, not as acceptable temporary authoring shortcuts.
- Use grouped shorthand only for exact sibling captures such as `.stdout`, `.stderr`, `.exit`; do not rely on the verifier to infer missing files from a directory declaration.
- When public contract changes rename status words, JSON keys, or lifecycle semantics, update downstream retained E2E scenarios in the same change set instead of waiting for suite reruns to expose them.
- Follow up later with optional automation for downstream retained-suite sweeps so this rule is enforced earlier than manual retro review.
