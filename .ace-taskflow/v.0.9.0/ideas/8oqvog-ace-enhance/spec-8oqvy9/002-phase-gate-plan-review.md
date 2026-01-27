# Phase 2: Plan Review (The Gate)

## Goal
To ensure the `spec.md` produced by the Architect is accurate, safe, and aligned with the user's intent *before* any code is written.

## Mechanism: The Pause
Unlike a continuous script, the Overseer **must support suspension**.

1.  **State Transition**: Overseer moves from `PLANNING` to `PLAN_REVIEW`.
2.  **Action**:
    *   Overseer saves state (`status: waiting_for_approval`).
    *   Overseer notifies the Coworker (User Interface).
    *   **Process Exits/Suspends**: The Overseer loop may actually stop here to save resources, or enter a low-power polling mode.

## User Interaction
1.  User receives notification: "Plan ready for Task #123".
2.  User inspects `spec.md`.
3.  **Feedback Loop**:
    *   *Reject/Refine*: User provides comments. Overseer reverts to **Phase 1 (Planning)** with added feedback context.
    *   *Approve*: User signals approval (e.g., `ace-coworker approve <session-id>`).

## Outcome
*   **Approved**: Transition to **Phase 3 (Execution Loop)**.
*   **Rejected**: Return to **Phase 1**.
