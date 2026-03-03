---
id: 8pne61
title: Task 280 Post-Delivery — Experiment Validated, Pipeline Not Implemented
type: standard
tags: []
created_at: '2026-02-24 09:26:41'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8pne61-280-post-delivery-pipeline-gap.md"
---

# Reflection: Task 280 Post-Delivery — Experiment Validated, Pipeline Not Implemented

**Date**: 2026-02-24
**Context**: Post-delivery validation of task 280 revealed that the 6-phase goal-mode pipeline from the experiment was not implemented in the production `ace-test-e2e` runner.
**Type**: Post-Delivery Finding

## What Happened

Task 280 designed and validated a 6-phase dual-agent pipeline for goal-mode E2E tests:
- Phases A/B/D/F: deterministic Ruby prep (sandbox, prompt bundling, report generation)
- Phases C/E: focused LLM execution (runner only executes, verifier only evaluates)

The experiment (`experiment/phase-[a-f]`) correctly caught 2 failures in ace-b36ts (TC-003: test-spec-error, TC-007: tool-bug).

But the production code (`ace-test-e2e run`) still uses the old skill-invocation pattern where a single agent handles everything: discovery, sandbox setup, execution, self-evaluation, and reporting. Running the same tests through production reported 8/8 PASS — a false positive for TC-007.

## Why It Happened

1. **Spec deliverables were format-focused**: 280.05/280.06 deliverable checklists focused on file formats, naming conventions, and schema — not on the execution pipeline implementation.
2. **Experiment ran outside the orchestrator**: The experiment explicitly ran "outside the orchestrator" (plan.md line 5). The pipeline phases were manual workflow instructions, not coded into the runner.
3. **Big-bang cutover was naming-only**: The "big-bang" removed legacy naming (goal-*.runner.md → TC-*.runner.md) and report schema keys, but didn't change the execution engine.
4. **Fork agents completed deliverables as listed**: Each subtask fork agent checked off the deliverable checkboxes (format defined, parser updated, --verify flag added) without implementing the underlying pipeline.

## Key Learning

**An experiment that validates architecture is not a substitute for implementing that architecture.** The experiment phases (A-F) should have been translated into Ruby code in the runner, not left as manual workflow instructions.

When specs declare "big-bang cutover", the deliverables must include execution-engine changes — not just format/naming changes. A success criterion like "ace-test-e2e run ace-b36ts TS-B36TS-001 produces same verdicts as experiment" would have caught this.

## Action Items

- Idea file created: `ideas/8pne61-e2e-runner-fix/implement-6-phase-goal-mode-pipeline.idea.s.md`
- Future tasks should include "execution parity with experiment" as acceptance criterion
- Big-bang cutover specs should list execution-engine deliverables explicitly