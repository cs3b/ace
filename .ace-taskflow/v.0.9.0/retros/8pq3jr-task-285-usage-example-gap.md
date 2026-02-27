# Retro: Task 285 Usage Example Gap

**Date**: 2026-02-26
**Context**: Task 285 delivered simulation infrastructure but lacked a concrete happy-path usage example in the spec. This led to ambiguity about intended UX, config, and command flow.
**Author**: Codex
**Type**: Conversation Analysis

## What Went Well

- The system is modular enough to add a usage example without changing core architecture.
- The team identified the gap quickly once execution began and could articulate the missing artifacts.

## What Could Be Improved

- The original task spec did not include a happy-path usage example (commands, config, expected artifacts), leaving behavior ambiguous.
- There was no UX/sample folder or “worked example” to anchor expectations, so we iterated on intent after implementation started.
- The lack of a minimal diagram or high-level flow made it harder to align on end-to-end expectations.

## Key Learnings

- Specs for new workflows should include at least one explicit happy-path walkthrough.
- Usage artifacts (sample config/prompt/preset and expected output paths) are necessary to validate intent early.
- A simple diagram of the desired flow prevents divergence between intended and built behavior.

## Conversation Analysis (For conversation-based retros)

### Challenge Patterns Identified

#### High Impact Issues

- **Missing Happy-Path Example**: No concrete “run this command and expect these artifacts” guidance.
  - Occurrences: 1
  - Impact: Several hours spent reconciling intent vs implementation; risk of building the wrong UX
  - Root Cause: Spec focused on architecture and rules, not on a runnable end-to-end example

#### Medium Impact Issues

- **Missing UX Artifact Folder**: Past tasks used a `ux/` folder to anchor desired UX, but task 285 did not.
  - Occurrences: 1
  - Impact: Unclear expectations for prompts, presets, and output shape

### Improvement Proposals

#### Process Improvements

- Add a required “Happy Path” section in task specs for workflow features (commands, config, outputs).
- Include a `ux/` or `examples/` directory for workflow-intent artifacts when behavior is user-facing.
- Add a diagram or numbered flow list that illustrates the end-to-end lifecycle (input → simulation → synthesis → writeback).

#### Tool Enhancements

- Add a spec template snippet for “Usage Example” and “Expected Artifacts” that is enforced by review-gate checks.
- Add a review checklist item: “Is there a happy-path command run documented?”

#### Communication Protocols

- Require agreement on a single canonical command sequence before implementation begins.
- Reviewers should ask: “What exact command does a user run, and what do they see?”

## Action Items

### Stop Doing

- Shipping workflow features without a concrete usage example in the spec.
- Assuming architecture documentation implies UX expectations.

### Continue Doing

- Capturing retros immediately after gaps are discovered.
- Isolating UX expectations as first-class artifacts (configs, prompts, presets).

### Start Doing

- Add `ux/` example artifacts for task specs that introduce new workflows.
- Include sample config/prompt/preset and expected output locations in the spec.
- Include a minimal diagram or numbered flow showing the happy-path lifecycle.

## Technical Details

Suggested happy-path spec content template:
- **Command**: `ace-taskflow review-next-phase --task 285 --simulate` (example)
- **Config**: sample `.ace/taskflow/config.yml` entries
- **Prompt/Presets**: sample prompt snippets and preset name
- **Expected Artifacts**: `.cache/ace-taskflow/simulations/<b36ts-id>/...`
- **Flow Diagram**:
  1. Input artifact (idea/task)
  2. Simulate next-phase stages
  3. Synthesize questions
  4. Write back to source

## Additional Context

- The UX example pattern previously lived under `ux/` in other tasks.
- Related retros: `8ppxcf-task-285-simulation-gaps.md`
