# Phase 1: Planning (The Architect)

## Goal
To generate a comprehensive, actionable technical specification (`spec.md`) from a high-level user request or task description.

## Actors
*   **Overseer**: Initiates the request and validates the output existence.
*   **Worker (Role: Architect)**: Analyzes the codebase and requirements to produce the design.

## Workflow
1.  **Trigger**: User (via Coworker) or Overseer starts the Planning phase.
2.  **Context Loading**:
    *   Overseer prepares the context (Task description, project architecture docs, existing file structure).
3.  **Execution**:
    *   Overseer invokes the **Architect Worker**.
    *   **Prompt**: "Act as a Principal Engineer. Interview the user (if needed) or analyze the task. Produce a `spec.md` that defines the changes."
4.  **Output**: `spec.md` file.

## Validation (The Gate)
The phase is considered complete when:
1.  `spec.md` exists.
2.  (Optional) A "Plan Review" gate is triggered (see Phase 2).
