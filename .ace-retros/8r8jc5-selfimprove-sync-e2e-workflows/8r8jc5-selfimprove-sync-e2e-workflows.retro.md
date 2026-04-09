---
title: Sync all E2E workflows to one behavior-first contract
type: standard
tags:
  - self-improvement
  - e2e
  - workflow-sync
status: active
---

# What happened

The E2E guide, failure workflows, and lifecycle workflows drifted apart. The guide and failure handling were moving toward behavior-first evidence, while `manage`, `review`, `plan-changes`, and `rewrite` still encouraged artifact-heavy scenarios.

# Actual result

The workflow stack was internally inconsistent:
- some docs said to judge behavior from impact and real output
- other workflows still optimized for counts, captures, and convenience artifacts

# Expected result

All E2E workflows and guides should enforce the same runner/verifier model:
- minimal required evidence
- behavior-first verification
- synthetic artifacts treated as debt, not proof

# Root cause

- Ambiguous instructions
- Missing validation
- Missing example

The pipeline had no single enforced evidence taxonomy across all stages.

# Fix applied

- Synced `manage`, `review`, `plan-changes`, and `rewrite` to the same artifact model as the guide, `analyze-failures`, and `fix`
- Added explicit focus on:
  - `command-capture`
  - `state-oracle`
  - `optional-support`
- Made oracle quality and synthetic artifact debt first-class review/planning concepts
- Made rewrite rules prefer simpler runner/verifier pairs over support-artifact accumulation

# Expected impact

- Fewer workflow contradictions when authoring or fixing E2E tests
- Better portability across providers and agent styles
- Lower false-positive risk from artifact choreography
