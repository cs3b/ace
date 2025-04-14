---
id: 04
status: pending
priority: medium
dependencies: [01, 03] # Depends on unified system and guides being updated
---

# Task Title: Define Session Logging Command and Process

## Description
Define a command and process for logging key information after each significant interaction with the coding agent. This log should facilitate context restoration and review of the development process.

## Implementation Details / Notes
- **Define the Command:** Propose a command name (e.g., `log-session`, `capture-context`). Document its purpose and expected inputs/outputs in a new `.md` file within `docs-dev/commands/`.
- **Define Log Content:** Specify the structure and content of the session log file. It must include:
    - Unique Identifier (Timestamp + sequence/hash).
    - Summary of User Request (Rephrased concisely).
    - Summary of Agent Action/Response.
    - A generated "Context Loading Prompt" to resume the current state in a new chat.
- **Define Storage:** Session logs should be stored within the current release directory, e.g., `docs-dev/project/current/{release_dir}/sessions/`.
- **Define Session Boundary:** Clarify when a new session log is created versus when the last one is updated (e.g., new distinct command vs. follow-up clarification).
- **Context Loading Prompt Generation:** Detail the requirements for generating the context loading prompt. It should reference key files/directories modified or discussed, and the current task/goal.
- **Integration:** Describe how this command fits into the overall workflow defined in `docs/unified-workflow-guide.md`.
- **Tooling (Optional):** Consider if any helper script is needed or if it's purely a documentation/manual process initially.

## Acceptance Criteria / Test Strategy
- A new command file (e.g., `docs-dev/commands/log-session.md`) exists, clearly defining the process.
- The standard format for session log files is documented.
- The process for generating the context loading prompt is described.
- The rules for creating vs. updating logs are defined.
- The updated workflow guide incorporates the session logging step.
