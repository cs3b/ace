---
id: 8pqwbj
title: Task 296 Phase-2 to Phase-3 Contract Drift
type: conversation-analysis
tags: []
created_at: "2026-02-27 21:32:48"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8pqwbj-task-296-phase-3-contract-drift.md
---
# Reflection: Task 296 Phase-2 to Phase-3 Contract Drift

**Date**: 2026-02-27
**Context**: Focused retrospective on why the phase-2 implementation of task 296 required unplanned phase-3 rewrite to reach the final markdown-first runtime contract for `ace-sim`.
**Author**: Codex (GPT-5)
**Type**: Conversation Analysis

## What Went Well

- The team converged quickly once the runtime contract was made explicit: `input.md -> user.bundle.md -> user.prompt.md -> output.md`.
- The phase-3 rewrite stayed bounded to runtime, defaults, tests, and docs without destabilizing unrelated packages.
- Final behavior was validated with package tests and reflected in task lineage (`296.03`) as the authoritative completion record.

## What Could Be Improved

- Phase-2 specification left artifact format underconstrained, allowing YAML-chain behavior that later conflicted with intended markdown-first flow.
- Source semantics were ambiguous in phase-2 (`<idea-ref|task-ref>`), while the working runtime needed `--source` as a readable file path.
- Step config contract did not enforce required bundle sections, instruction shape, or reporting tags, so early prompts were structurally weak.
- Acceptance criteria validated “runner works” but did not include a strict artifact tree contract that would have caught drift before release.

## Key Learnings

- Proof-before-code only prevents rework when proof artifacts are encoded as non-negotiable acceptance gates.
- For pipeline tools, filenames/extensions and handoff semantics are public behavior and must be specified explicitly in draft specs.
- Prompt quality is a contract issue, not cosmetic: missing section/report constraints leads to fragile runs and downstream rewrites.
- Review gates should block promotion when artifact contracts, source semantics, and prompt structure are not fully locked.

## Conversation Analysis (For conversation-based reflections)

### Challenge Patterns Identified

#### High Impact Issues

- **Contract drift between phase-2 and final runtime intent**: Phase-2 shipped YAML-oriented chain while final expected model was markdown-first.
  - Occurrences: 1 major drift window (`v0.2.0 -> v0.3.0`)
  - Impact: Required unplanned phase-3 rewrite across runtime, defaults, docs, and tests
  - Root Cause: Phase-2 behavioral spec did not lock artifact names/formats and first-step input semantics as hard acceptance criteria

#### Medium Impact Issues

- **Step prompt contract under-specification**: Initial step files were minimal bundle stubs instead of sectioned prompt configs.
  - Occurrences: 1
  - Impact: Poor prompt composition quality and missing explicit reporting structure

- **Ambiguous source model**: Initial contract allowed logical task/idea references; runtime value path required direct file input.
  - Occurrences: 1
  - Impact: CLI/runtime behavior changed post-release to enforce readable file path

#### Low Impact Issues

- **E2E timing mismatch**: E2E coverage had to be realigned after runtime contract correction.
  - Occurrences: 1
  - Impact: Additional verification rewrite effort, low architectural risk

### Improvement Proposals

#### Process Improvements

- Add mandatory `Artifact Chain Contract` section to task drafts for pipeline features:
  - `step_input_filename`
  - `bundle_filename`
  - `prompt_filename`
  - `step_output_filename`
  - `chain_handoff_rule`
- Add mandatory `Source Semantics` section with one canonical source type and validation rules.
- Add mandatory `Prompt Contract` section defining required bundle sections and output/report tags.
- Require a “golden-run” command sequence plus expected artifact tree before a task leaves draft.

#### Tool Enhancements

- Update task draft template to include contract blocks above as first-class required fields.
- Update task review workflow readiness checklist to fail when artifact/source/prompt contracts are missing or contradictory.
- Add a draft-time lint rule in workflow guidance: if a task defines chained stages, it must define exact handoff file contract.

#### Communication Protocols

- During drafting, explicitly separate “conceptual behavior” from “artifact-level behavior” and require both for pipeline tasks.
- During review, ask one forcing question: “Can another engineer reproduce the exact run artifact tree from this spec without making choices?”
- During implementation handoff, include one canonical command and one canonical expected tree in task notes.

### Token Limit & Truncation Issues

- **Large Output Instances**: None material in this focused phase-2→phase-3 analysis pass.
- **Truncation Impact**: None.
- **Mitigation Applied**: Scoped analysis to `27a1f5bfb..HEAD`, with runtime focus on `2fc78a260..bbd7eb23a`.
- **Prevention Strategy**: Continue narrowing diff windows and validating conclusions against direct file-level deltas.

## Action Items

### Stop Doing

- Approving pipeline tasks where artifact filenames/formats are implied rather than explicit.
- Treating source input type as an implementation detail in task specs.
- Accepting minimal prompt stubs for step configs when prompt structure is behavior-critical.

### Continue Doing

- Proof-before-code sequencing for new runtime/pipeline surfaces.
- Evidence-based retros tied to concrete commit windows and file diffs.
- Capturing unplanned corrective work in orchestrator lineage (`task.296.03` style).

### Start Doing

- **Draft task seed A**: Harden `ace-taskflow` draft template with required sections:
  - `Artifact Chain Contract`
  - `Source Semantics`
  - `Prompt Contract`
- **Draft task seed B**: Harden `ace-taskflow` review workflow with blocking checklist items for contract completeness and contradiction checks.
- **Draft task seed C**: Add “golden-run + expected artifact tree” requirement for any task introducing chained stage execution.

## Technical Details

- Analysis baseline: `27a1f5bfb` (phase-2 endpoint marker context on `main`) to `HEAD` (2026-02-27).
- Runtime correction window: `2fc78a260` (`ace-sim` v0.2.0) to `bbd7eb23a` (`ace-sim` v0.3.0).
- Key corrected contracts:
  - artifacts: `input.md`, `user.bundle.md`, `user.prompt.md`, `output.md`
  - source: readable file path enforced by CLI and resolver
  - chain: step `N` output copied into step `N+1` input

## Additional Context

- Related task files:
  - `.ace-taskflow/v.0.9.0/tasks/_archive/296-build-sim-ace/296.02-simulation-workflo.s.md`
  - `.ace-taskflow/v.0.9.0/tasks/_archive/296-build-sim-ace/296.03-first-artifact.s.md`
  - `.ace-taskflow/v.0.9.0/tasks/_archive/296-build-sim-ace/296-orchestrator.s.md`
- Related superseded task:
  - `.ace-taskflow/v.0.9.0/tasks/_archive/297-task-sim-ace/297-sim-scenariostep-contracts.s.md`
