---
title: Enhance ace-review with Action Item Orchestration and Concurrent Verification
filename_suggestion: feat-review-action-item-orchestration
enhanced_at: 2026-01-14 22:48:23
location: active
llm_model: gflash
---

# Enhance ace-review with Action Item Orchestration and Concurrent Verification

## Problem
While `ace-review` excels at generating synthesized feedback, transitioning this unstructured feedback into verifiable, actionable steps requires manual intervention or complex, brittle agent scripting. Agents struggle to autonomously verify complex, multi-faceted review comments without breaking the process into smaller, structured tasks. We need a mechanism to convert LLM-generated review synthesis into a structured, executable workflow.

## Solution
Introduce a new post-processing layer within `ace-review` that converts synthesized review feedback into structured, ephemeral `ReviewActionItem` Models. These action items will be managed by a dedicated `ReviewActionOrchestrator` that leverages `ace-llm` and subagents to concurrently execute verification and exploration steps for each item.

## Implementation Approach
1.  **Action Item Generation:** The `ReviewActionOrchestrator` (a new Organism in `ace-review`) will parse the final synthesized review output and generate `ReviewActionItem` Models. These models will mirror the structure of `ace-taskflow` tasks (status, description, context, required action/command) but remain ephemeral within the review session.
2.  **Concurrent Execution:** The Orchestrator will delegate the verification of each `ReviewActionItem` to specialized subagents via `ace-llm`. This execution must be concurrent (e.g., using Ruby fibers or threads) to maximize efficiency, running tools like `ace-search`, `ace-lint`, or `ace-test` as needed.
3.  **Status Tracking:** A dedicated Molecule will manage the state of each `ReviewActionItem` (e.g., `pending`, `exploring`, `verified`, `failed`), ensuring deterministic status updates that the Orchestrator can rely on.
4.  **Final Synthesis:** Once all concurrent verification steps are complete, the Orchestrator synthesizes a final report detailing the verification results for each action item, providing a clear, evidence-backed summary for the developer.

## Considerations
- **Configuration Cascade:** Concurrency limits and batching size for the action items must be configurable via the `ace-review` configuration cascade (`.ace/review/config.yml`) to avoid hardcoded limits.
- **Output Format:** The `ReviewActionItem` structure must be highly deterministic and parseable (JSON/YAML output mode) for seamless consumption by subsequent agents.
- **Integration:** Requires tight integration with `ace-llm` for managing concurrent subagent calls and potential reuse of `ace-taskflow`'s data model concepts.

## Benefits
- **Increased Autonomy (AX):** Agents can move from generating feedback to actively verifying and exploring solutions, significantly reducing human intervention.
- **Deterministic Verification:** Provides structured, verifiable output for review comments, making the review process more objective and reliable.
- **Efficiency:** Concurrent execution of verification steps drastically speeds up the time-to-resolution for complex reviews.

---

## Original Idea

```
ace-review -> main agent will run review, then for each feedback on synthesis (check if don't hardcodeded limited to 10 elements), create review-recomendations (similar to how task look like) fro each review recomendatons will run exploration and subagents for running each verification - explore agents - all at once and then synthesis when all of the finish. addtional exploration agent update the status of each review-recomendations 

.ace-taskflow/v.0.9.0/tasks/213-ace-refactor/213-migrate-gems-cli-to-hanami-pattern.s.md:200
```