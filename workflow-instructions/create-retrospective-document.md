# Create Retrospective Document Workflow Instruction

## Goal

To create a comprehensive retrospective document for a completed release cycle (or other significant period). This workflow focuses on synthesizing information from various sources, including completed tasks, ADRs, individual reflection logs (outputs of former `self-reflect` actions), compact session logs, commit history, and direct user/team input, to analyze what went well, what didn't, and identify actionable improvements.

## Prerequisites

- A defined period for the retrospective (e.g., a completed release cycle, a specific project phase).
- Access to relevant data sources for the period, such as:
  - Completed task files (`docs-project/done/{release_dir}/tasks/*.md` or `docs-project/current/{release_dir}/tasks/*.md` if reflecting mid-release).
  - Architectural Decision Records (ADRs) (`docs-project/adr/`).
  - Individual reflection logs (e.g., `docs-project/done/{release_dir}/reflections/YYYYMMDD-taskID.md` or similar user-maintained logs).
  - Compact session logs (`docs-project/current/{release_dir}/sessions/*.md` or `docs-project/done/{release_dir}/sessions/*.md`).
  - Commit history (`git log`).
  - The standard retrospective template (`docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md`).

## Process Steps

1. **Define Scope & Identify Target Release/Period:**
    - Confirm the release or period for which the retrospective is being created (e.g., `docs-project/done/v1.2.0`, or "Sprint X").
    - Locate the primary directory for this period if applicable (e.g., `docs-project/done/{release_dir}/`).

2. **Create Retrospective Document:**
    - Create a new file for the retrospective. Standard location: `docs-project/done/{release_dir}/retrospective.md` or `docs-project/retrospectives/YYYYMMDD-retrospective.md` if not tied to a specific release `done` directory.
    - Apply the standard retrospective template (`docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md`) to this new file.

3. **Gather & Synthesize Information:**
    - **Completed Tasks:** Review task files (`.md`) for objectives, outcomes, challenges, and time taken.
    - **Commit History:** Use `git log --since="YYYY-MM-DD" --until="YYYY-MM-DD"` (or similar filters like `bin/gl`) for the period to understand the sequence of changes and effort distribution.
    - **Session Logs:** Review `log-compact-session.md` outputs for daily progress, obstacles, and immediate context shifts.
    - **Reflection Logs:** Review individual reflection notes (previously associated with `self-reflect.md` outputs or other personal/team reflection practices) for deeper insights, learnings, and pain points.
    - **ADRs:** Check any ADRs created or modified during the period for significant decisions and their rationale.
    - **Direct Input:** Collect direct feedback from team members or the user regarding their experiences during the period.

4. **Facilitate Retrospective Analysis (Fill Template):**
    - Guide the user/team to populate the retrospective template sections using the synthesized information:
        - **What went well? (Continue Doing):** Identify successful practices, tools, or collaborations.
        - **What didn’t go so well? (Stop Doing / Improve):** Identify ineffective practices, bottlenecks, or areas of frustration.
        - **What did we learn?** Summarize key learnings.
        - **What should we try next time? (Start Doing / Action Items):** Propose specific, actionable improvements.

5. **Identify and Prioritize Action Items:**
    - Extract concrete, actionable improvements from the "Start Doing" section.
    - For each action item, consider its impact, effort, and owner.
    - Plan how these action items will be tracked (e.g., creating new tasks in `docs-project/backlog/`, adding to a process improvement board).

6. **Save and Share:**
    - Save the completed retrospective document.
    - Share with relevant stakeholders.

## Input

- Path to the target release directory (if applicable, e.g., `docs-project/done/{release_dir}/`).
- Dates defining the retrospective period (if not tied to a specific release).
- Access to data sources:
  - Task files.
  - Commit history (e.g., via `git log` or `bin/gl`).
  - Compact session logs (`log-compact-session.md` outputs).
  - Individual reflection logs.
  - ADRs.
- The retrospective template path.
- Optional: Direct user/team input.

## Output / Success Criteria

- [x] A `retrospective.md` file is created within the completed release directory.
- [x] The file uses the standard retrospective template structure (`docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md`).
- [x] Key insights (Stop/Continue/Start) are captured based on the release cycle.
- [x] Actionable improvements are identified.

## Reference Documentation

- [Retrospective Template](docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md)
- [`log-compact-session` Workflow Instruction](docs-dev/workflow-instructions/log-compact-session.md) (Potential input for retrospectives)
- [Project Management Guide](docs-dev/guides/project-management.md) (For context on tasks, releases)
