---
id: 07
status: done
priority: medium
dependencies: [] # Potentially depends on 06 if structure changes significantly
---

# Task Title: Separate Context Loading and Task Execution Flow

## Description
Clarify and separate the responsibilities of loading the development environment/context from the process of guiding the execution of a specific task. Eliminate overlap between commands like `load-env` and `lets-start`.

## Implementation Details / Notes
- **Analyze Current Flow:** Review `load-env.md` and `lets-start.md` to identify how they handle context loading vs. task execution guidance.
- **Define Separated Roles:**
    - **`load-env`:** Define its sole responsibility as loading the project context. This includes general guides/commands, project-specific guides/commands, the project blueprint (`blueprint.md` from Task 06), `what-do-we-build.md`, `architecture.md`, current release path (`project/current/`), and potentially recent commits/changes. It should *not* guide task selection or execution.
    - **`lets-start`:** Redefine this command. Its primary purpose should be to initiate the *execution workflow* for a *specific task* that the user selects (after having run `load-env`). It should guide the developer through the standard implementation process outlined in `guides/project-management.md` (Plan -> TDD -> Commit -> Reflect). Alternatively, `lets-start` could simply load the environment (`load-env`) and then trigger a separate `run-task` command/process.
- **Update Command Documentation:**
    - Rewrite `load-env.md` to focus purely on context loading.
    - Rewrite `lets-start.md` to focus on initiating the task execution workflow, referencing the standard process from guides. Remove context-loading aspects.
- **Update Workflow Guides:** Ensure `docs/unified-workflow-guide.md` and `guides/project-management.md` clearly describe this two-step process: 1. Load context (`load-env`). 2. Start working on a task (`lets-start`).

## Acceptance Criteria / Test Strategy
- `load-env.md` documentation clearly describes its role as context loading only (including project blueprint).
- `lets-start.md` documentation clearly describes its role in initiating the task execution workflow for a selected task, referencing the standard implementation process.
- Overlap in functionality between the two commands is removed.
- Workflow guides (`unified-workflow-guide.md`, `project-management.md`) are updated to reflect the separated context loading and task execution initiation steps.