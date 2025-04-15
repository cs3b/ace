# Log Session Command (log-session)

## Goal
Capture the state of the current development session, including user requests, agent actions, and key context, to facilitate session resumption and process review.

## Process Steps

1.  **Trigger Command:** The user invokes `log-session` typically after a significant interaction or at the end of a work segment.
2.  **Agent Summarization:** The AI agent analyzes the recent interaction history within the current chat/session.
3.  **Identify Key Elements:** The agent identifies:
    *   The primary user request(s) in the segment.
    *   The main actions taken by the agent in response.
    *   The key files, directories, tasks, or concepts involved.
    *   The current objective or next step.
4.  **Generate Log Content:** The agent constructs the log content, including:
    *   A unique identifier (Timestamp recommended).
    *   A concise summary of the user request(s).
    *   A concise summary of the agent's actions/responses (e.g., "Generated patch for Task 03", "Created ADR-002", "Answered question about X").
    *   A "Context Loading Prompt" designed to restore the current state in a new session.
5.  **Determine Log Location:**
    *   Identify the current release directory (e.g., `docs-dev/project/current/v.0.2.0-StreamlineWorkflow/`).
    *   Target the `sessions/` subdirectory within that release directory.
6.  **Save Log File:**
    *   Create a filename using the timestamp (e.g., `YYYYMMDD-HHMMSS-log.md`).
    *   Save the generated log content to this file.
    *   *Initial Implementation:* The agent might present the formatted log content for the user to manually save to the correct location. Future implementations could involve direct file saving capabilities.
7.  **Confirm Save:** Inform the user that the session log has been generated and specify the path where it was (or should be) saved.

## Log File Format (`*.md`)

```markdown
# Session Log: YYYY-MM-DD HH:MM:SS

## Request Summary
[Concise summary of the user's main goal or request during this session segment.]
(E.g., "User asked to implement Task 03: Update Guides.")

## Agent Action Summary
[Concise summary of the primary actions taken by the agent.]
(E.g., "Generated patch updating guides/README.md and guides/ship-release.md, deleted guides/prepare-release/prepare-release-documentation.md, and added notes to docs/unified-workflow-guide.md.")

## Context Loading Prompt (Copy and paste to resume session)

---
# Context Loading Prompt: Resume [Brief Description of State]

**Goal:** [State the next immediate objective]
(E.g., Continue work on v0.2.0, starting Task 04.)

**Current State:**
- Tasks 01, 02, 03 of v0.2.0 release are complete.
- Files modified/reviewed recently: [List key files, e.g., `guides/ship-release.md`, `tasks/03-*.md`]
- Current release directory: `docs-dev/project/current/v.0.2.0-StreamlineWorkflow/`
- Last action: Completed updates to guides as per Task 03.

**Files/Directories to Load/Review:**
- `docs-dev/project/current/v.0.2.0/` (Load this entire directory context)
  - `tasks/04-define-session-logging.md` (Next task)
  - `docs/unified-workflow-guide.md` (Recently modified)
  - Other relevant files based on recent interaction...

**Next Objective:** [Explicitly state the next step]
(E.g., Begin implementation of Task 04: Define Session Logging Command.)
---

```

## Integration into Workflow
The `log-session` command should be used periodically, especially:
- Before switching context to a different task.
- After complex interactions or generating significant artifacts (code, documentation).
- At the end of a development session.

This complements `self-reflect`, which focuses on deeper analysis and actionable improvements, while `log-session` focuses on capturing the immediate state for context restoration.

## Success Criteria

- The process for logging a session is clearly defined.
- The standard format for the session log file (including the Context Loading Prompt) is documented.
- The storage location within the current release's `sessions/` directory is specified.
- The distinction between `log-session` and `self-reflect` is clear.

## Prerequisites
- An active development session with recent interactions.
- A defined current release directory (`docs-dev/project/current/{release_dir}/`).