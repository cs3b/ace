# Question: Gate Mechanics (Pause/Resume)

## The Problem
Autonomous loops are dangerous without checks. We need "Gates" where the system stops and waits for a human signal.

## Proposed Solution: The "Suspended" State

When the Overseer hits a Gate (e.g., `PLAN_REVIEW`):
1.  It writes `status: suspended` and `gate: plan_review` to `state.json`.
2.  **It exits.** The process terminates.

### Why Exit?
*   Saves system resources.
*   Simplifies recovery (Resuming is just "Starting with existing state").
*   Prevents "zombie" processes.

### Resuming
The user runs:
```bash
ace-coworker approve <session-id>
```
This command:
1.  Updates `state.json` (e.g., `gate_status: approved`).
2.  Spawns a new `ace-overseer` process.
3.  The Overseer reads the state, sees the approval, and transitions to the next phase.

## Questions to Answer
1.  **Notifications**: How does the user know a Gate has been reached? (System notification? TUI status update?)
2.  **Rejection**: What happens if the user says "No"? Does the Overseer need a "Feedback" input channel?
