---
title: "ACE Overseer: Agentic Workflow Orchestration and Delegation Tool"
filename_suggestion: feat-orchestration-overseer
enhanced_at: 2026-01-19 20:49:02 +0000
archived_reason: converted to task 235 (ace-overseer v0.1.0). Quality progression modes (work/fast/beauty) handled by ace-assign presets. HIL deferred to backlog.
task_ref: v.0.9.0+task.235
llm_model: gflash
source: "taskflow:v.0.9.0"
id: 8oiv85
status: obsolete
tags: []
created_at: "2026-01-19 20:49:02"
---

# ACE Overseer: Agentic Workflow Orchestration and Delegation Tool

## Problem
Currently, executing complex, multi-stage agentic development requires manual chaining of specialized ACE tools (`ace-search`, `ace-git-commit`, `ace-review`). There is no single, high-level agent (C00 level) responsible for managing the overall workflow progression, delegating tasks, and enforcing quality gates based on defined goals.

## Solution
Introduce `ace-overseer` as the primary agentic workflow orchestrator. This tool operates in three configurable modes, defining the quality and focus of the current development stage:
1. **Make It Work (Functional)**: Focus on correctness and passing basic tests.
2. **Make It Fast (Performance)**: Focus on optimization and efficiency.
3. **Make It Beauty/Compact (Refinement)**: Focus on code style, adherence to project standards, and documentation.

The `ace-overseer` gem will act purely as a delegator, using `ace-llm` for high-level decision-making (e.g., determining if a task is ready to transition from Mode 1 to Mode 2) and calling specialized ACE tools for execution (e.g., `ace-review` for quality checks, `ace-taskflow` for state updates).

## Implementation Approach

1. **New Gem:** `ace-overseer` following the `ace-*` pattern.
2. **ATOM Architecture:** The core logic will reside in an **Organism** (`WorkflowOrchestrator`) that manages state transitions between the three modes.
3. **Delegation:** The Orchestrator will delegate analysis and review to `ace-review` and `ace-lint`, and task progression to `ace-taskflow`.
4. **Workflows:** Define three core workflow instructions (`make-it-work.wf.md`, `make-it-fast.wf.md`, `make-it-beauty.wf.md`) within the gem's `handbook/workflow-instructions/` directory. These workflows will contain the LLM instructions for the C00 agent.
5. **CLI Interface:** Simple, deterministic commands:
   - `ace-overseer start <task_id>`: Initializes the workflow in Mode 1.
   - `ace-overseer progress`: Attempts to move the current task to the next mode, engaging Human-In-the-Loop (HIL) if necessary.

## Considerations
- **Configuration Cascade:** The quality thresholds and specific tools used for each mode (e.g., which `ace-review` preset to use for 'Beauty' mode) must be configurable via `.ace/overseer/modes.yml` (ADR-022).
- **State Management:** Must integrate tightly with `ace-taskflow` to store the current mode and progression status within the task metadata.
- **Agent Integration:** Requires a high-level agent definition (`overseer.ag.md`) that exposes the `start` and `progress` commands to external agents (like Claude Code).
- **Transparency:** All delegation decisions and mode transitions must be logged using the standard Prompt Caching Pattern (`.cache/ace-overseer/sessions/`) for inspectability.

## Benefits
- Provides a single, high-level entry point for complex agentic development.
- Enforces structured progression and quality gates (Work -> Speed -> Beauty).
- Simplifies the creation of high-level agent skills by abstracting away tool chaining.

---

## Original Idea

```
ace-overseer - a better name then coworker; it should work on 3 modes -> 1. make it work; 2. make it fast; 3. make it beauty/compact; and the progression might be backward, when we findout something the result in deeper refactoring, or we break things badly ... (and overseer only delegate ( delegate analysysi, delegate review, delegate work, etc it never perform any work exceptusing it advisors and calling other agents - C00 level, know enough to make decision about progressing, and releasing the features, or running HIL, enganging human in the loop

TC-005: FAIL ❌

  - Issue: The --context flag does not prepend ace-bundle project context to the prompt output
  - Expected: Output should include project context from ace-bundle (loaded via context: project frontmatter or
  bundle.presets: [project])
  - Actual: Output only contains the original prompt content
  - Root Cause: The prompt frontmatter context: project is not a valid ace-bundle bundle configuration. When ace-bundle
   loads the file as a template, it doesn't recognize this as a preset reference and only returns the source content.
  - Possible Test Issue: The E2E test scenario may be outdated, or the feature needs implementation work to properly
  handle the context: project shorthand format.

  Observations

  1. Core workflow works perfectly: Setup, archive, symlink management, and Base36 ID generation all function as
  expected.
  2. Base36 ID format confirmed: Archives use 6-7 character lowercase alphanumeric IDs (e.g., 8oiusn.md, 8oiutu.md).
  3. Symlink management is correct: _previous.md always points to the most recent archive.
  4. Context loading issue: The --context flag integration with ace-bundle doesn't work with the simple context:
  project frontmatter format shown in the test. The proper ace-bundle format would be bundle.presets: [project] in the
  frontmatter, but even this doesn't work in testing.
  5. Possible improvements needed:
    - Add special handling for context: <preset-name> format in ContextLoader
    - Or update the E2E test to use the correct ace-bundle bundle frontmatter format
    - Or document the expected frontmatter format more clearly
```