---
:input_tokens: 45619
:output_tokens: 1142
:total_tokens: 46761
:took: 4.76
:provider: google
:model: gemini-2.5-flash-lite
:timestamp: '2025-07-31T07:03:41Z'
:finish_reason: stop
:provider_specific:
  :prompt_token_details:
  - :modality: TEXT
    :tokenCount: 45619
:cost:
  :input: 0.004562
  :output: 0.000457
  :cache_creation: 0.0
  :cache_read: 0.0
  :total: 0.005019
  :currency: USD
---

# Define Redraft and Replan Task Workflows

## Intention

To define two distinct AI workflow files (`redraft-task.wf.md` and `replan-task.wf.md`) that allow for the verification of task content without altering the task itself, leveraging existing project structures and principles.

## Problem It Solves

**Observed Issues:**
- Current workflow system may not have explicit workflows for task content verification without modification.
- Need for a clear, documented process to review task content (e.g., objectives, estimates, dependencies) before committing to changes.
- Lack of specific workflows to handle scenarios where a task needs to be redrafted or replanned due to new information or a change in scope, without immediately modifying the original task.

**Impact:**
- AI agents might attempt to modify tasks directly when only verification is needed, leading to unintended changes.
- Inefficient review processes if there's no clear workflow for pre-modification verification.
- Difficulty in capturing the intent of "verification" versus "modification" within the workflow system.

## Key Patterns from Reflections

- **Workflow Self-Containment (ADR-001)**: Both `redraft-task.wf.md` and `replan-task.wf.md` must be self-contained, embedding all necessary context, templates, and examples.
- **XML Template Embedding (ADR-002)**: Utilize `<documents>` and `<template>` tags for embedding task templates or verification checklists if needed.
- **Consistent Path Standards (ADR-004)**: Reference task files using consistent relative paths (e.g., `.ace/taskflow/current/tasks/task-XYZ.md`).
- **Universal Document Embedding System (ADR-005)**: If guides or other documents are referenced, use the `<documents>` container structure.
- **ATOM Architecture**: These workflows would likely orchestrate `task-manager` (organism) and potentially `llm-query` (organism) for generating summaries or suggesting edits.
- **YAML Front Matter**: Task files themselves use YAML front matter for metadata, which these workflows will read and display.

## Solution Direction

1. **`redraft-task.wf.md`**: This workflow will focus on reviewing and suggesting edits to the *content* of a task (e.g., description, objective, acceptance criteria) without changing its metadata (ID, status, estimate, dependencies).
2. **`replan-task.wf.md`**: This workflow will focus on reviewing and suggesting changes to the *planning* aspects of a task (e.g., estimate, priority, dependencies, due date) without altering its core description or objective.

## Critical Questions

**Before proceeding, we need to answer:**
1. What specific aspects of a task should `redraft-task.wf.md` focus on verifying (e.g., clarity of objective, completeness of acceptance criteria, adherence to standards)?
2. What specific planning aspects should `replan-task.wf.md` focus on verifying (e.g., accuracy of estimate, relevance of priority, correctness of dependencies)?
3. How will these workflows present the task content for verification without offering modification options by default?

**Open Questions:**
- Should these workflows generate a separate "verification report" or simply display the task content with annotations?
- What level of detail should be provided for verification (e.g., full task content, summary, specific sections)?
- How will these workflows handle the "no modification" constraint programmatically (e.g., by not invoking `task-manager` commands that alter state)?

## Assumptions to Validate

**We assume that:**
- The `task-manager` tool can read and display task content and metadata without requiring modification. - *Needs validation*
- AI agents can effectively parse and understand task content and metadata from YAML front matter and Markdown descriptions. - *Needs validation*
- There is a clear distinction between "task content" and "task planning" that can be effectively separated by the workflows. - *Needs validation*

## Expected Benefits

- **Clearer Task Review Process**: Dedicated workflows for verification improve clarity and prevent accidental modifications.
- **Enhanced Task Quality**: Facilitates thorough review of task content and planning before changes are committed.
- **Improved AI Agent Guidance**: Provides AI agents with specific instructions for verification tasks.
- **Maintainability**: Standardized workflows for a common development process.

## Big Unknowns

**Technical Unknowns:**
- The exact CLI commands or methods available within `task-manager` or other tools to *display* task details without offering modification options.
- The feasibility of AI agents reliably identifying "suggestions for redraft" vs. "suggestions for replan" based on task content alone.

**User/Market Unknowns:**
- How often will developers or AI agents need to perform a pure verification step versus direct modification?
- What specific criteria will users (human or AI) use to deem a task "verified" or requiring "redraft/replan"?

**Implementation Unknowns:**
- The precise structure and content of the `redraft-task.wf.md` and `replan-task.wf.md` files to ensure they are self-contained and actionable.
- How to integrate these workflows with the `task-manager` tool or other relevant components to read and display task information.