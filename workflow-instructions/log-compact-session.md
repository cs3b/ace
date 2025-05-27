# Log Compact Session Workflow Instruction (log-compact-session)

## Goal

To capture a compact summary of the current session (what was done, next steps, key file links) primarily for context saving/reloading, especially when dealing with token limits or needing to transfer session state. Streamline content to focus on brevity and essential context for reloading (the "Context Loading Prompt" remains key). Remove deeper analytical/reflection components.

## Prerequisites

- An active development session with recent interactions between user and AI agent.
- A defined current release directory (`docs-project/current/{release_dir}/`).
- The `sessions/` subdirectory exists or can be created within the current release directory.

## Input

- User request to log the current session in a compact format.
- Access to the recent chat/interaction history for the AI agent to summarize compactly.

## Process Steps

1. **Trigger Workflow Instruction:** The user invokes `log-compact-session` typically after a significant interaction, at the end of a work segment, or when needing to save context due to token limits.
2. **Agent Summarization:** The AI agent analyzes the recent interaction history within the current chat/session.
3. **Identify Key Elements:** The agent identifies:
    - The primary user request(s) in the segment.
    - The main actions taken by the agent in response.
    - The key files, directories, tasks, or concepts involved.
    - The current objective or next step.
4. **Generate Log Content:** The agent constructs the log content, including:
    - A unique identifier (Timestamp recommended).
    - A concise summary of the user request(s).
    - A concise summary of the agent's actions/responses (e.g., "Generated patch for Task 03", "Created ADR-002", "Answered question about X").
    - A brief summary of the user request(s), focusing on the core goal.
    - A brief summary of the agent\'s key actions/responses directly related to achieving the goal (e.g., files touched, main outcomes).
    - A "Context Loading Prompt" designed to efficiently restore the current working state in a new session.
5. **Determine Log Location:**
    - Identify the current release directory (e.g., `docs-project/current/v.0.2.0-StreamlineWorkflow/`).
    - Target the `sessions/` subdirectory within that release directory.
6. **Save Log File:**
    - Create a filename using the timestamp (e.g., `YYYYMMDD-HHMMSS-compact-log.md`).
    - Save the generated compact log content to this file.
    - *Initial Implementation:* The agent might present the formatted log content for the user to manually save to the correct location. Future implementations could involve direct file saving capabilities.
7. **Confirm Save:** Inform the user that the compact session log has been generated and specify the path where it was (or should be) saved.

## Log File Format (`*.md`)

```markdown
# Compact Session Log: YYYY-MM-DD HH:MM:SS

## Request Summary
[Concise summary of the user's main goal or request during this session segment.]
(E.g., \"User asked to implement Task 03: Update Guides.\")

## Agent Action Summary
[Brief summary of the primary actions taken by the agent, focusing on outcomes and key files.]
(E.g., \"Updated `guides/README.md` & `guides/ship-release.md` for Task 03. Deleted `guides/prepare-release/prepare-release-documentation.md`.\")

## Context Loading Prompt (Copy and paste to resume session)

---
# Context Loading Prompt: Resume [Brief Description of State]

**Goal:** [State the next immediate objective]
(E.g., Continue work on v0.2.0, starting Task 04.)

**Current State:**
- Tasks 01, 02, 03 of v0.2.0 release are complete.
- Files modified/reviewed recently: [List key files, e.g., `guides/ship-release.md`, `tasks/03-*.md`]
- Current release directory: `docs-project/current/v.0.2.0-StreamlineWorkflow/`
- Last action: Completed updates to guides as per Task 03.

**Files/Directories to Load/Review:**
- `docs-project/current/v.0.2.0/` (Load this entire directory context)
  - `tasks/04-define-session-logging.md` (Next task)
  - `docs/unified-workflow-guide.md` (Recently modified)
  - Other relevant files based on recent interaction...

**Next Objective:** [Explicitly state the next step]
(E.g., Begin implementation of Task 04: Define Session Logging Command.)
---

```

## Integration into Workflow

The `log-session` workflow instruction should be used periodically, especially:

- Before switching context to a different task.
- After complex interactions or generating significant artifacts (code, documentation), especially if needing to pause.
- At the end of a development session, or when token limits are a concern.
- When needing to transfer session state to another instance or agent.

This workflow is designed for quick state capture. For deeper analysis and synthesis of session activities into actionable improvements or project retrospectives, refer to the [`create-retrospective-document.md`](docs-dev/workflow-instructions/create-retrospective-document.md) workflow, which may use these compact session logs as one of its inputs.

## Reference Documentation

- [Project Management Guide](docs-dev/guides/project-management.md)
- [`create-retrospective-document.md`](docs-dev/workflow-instructions/create-retrospective-document.md) (For synthesizing session data into broader reflections)

## Output / Success Criteria

- The process for logging a compact session summary is clearly defined.
- The standard format for the compact session log file, emphasizing brevity and context for reloading (including the "Context Loading Prompt"), is documented.
- The storage location within the current release's `sessions/` directory is specified.
- The purpose is focused on context saving/reloading, distinct from deeper analytical reflections handled by other workflows (e.g., `create-retrospective-document.md`).

## Prerequisites

- An active development session with recent interactions.
- A defined current release directory (`docs-project/current/{release_dir}/`).
