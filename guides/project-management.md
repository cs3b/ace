# Project Management Guide

## Goal
This guide defines the core development philosophy, project structure, task management system, and standard workflows used within this toolkit. It serves as the central reference for how work is organized, tracked, and executed, enabling effective collaboration between human developers and AI agents.

# Project Management Guide

Our development workflow is centered around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases
- Workflow Instructions driven AI interactions

Our development workflow emphasizes planning before implementation ("Slow Vibe Coding"). We use a workflow instruction-based approach for AI interactions. Each workflow instruction in the `workflow-instructions/` directory represents a specific workflow or interaction pattern with clear inputs, processes, and success criteria.

## Directory Structure

The `docs-project` directory organizes project documentation and management:

```
docs-project
├── architecture.md
├── backlog
│   └── v.x.y.z-preflight-for-coding-agent
├── blueprint.md
├── current
├── done
│   ├── v.0.0.1
│   ├── v.0.2.0-dev-docs-review
│   ├── v.0.2.1-spec-form-diff
│   ├── v.0.2.2-feedback-to-process
└── what-do-we-build.md
```
(Use `tree docs-project -L 2` from the project root to view the current structure)

> **Strategic vs Operational Planning**  
> High-level direction is captured in the [Project Roadmap](docs-project/roadmap.md) and detailed in the [Strategic Planning Guide](docs-dev/guides/strategic-planning-guide.md).  
> Release planning and day-to-day execution described in this guide must align with the roadmap’s objectives and timelines.

## Task Management

### 1. Task Organization

Tasks are managed within the `docs-project/` subdirectories, representing a simple Kanban-style flow:

- **`docs-project/backlog/`**: Contains directories for future, planned releases (e.g., `docs-project/backlog/v.0.3.0-feature-x/`). Tasks are defined and planned here.
- **`docs-project/current/`**: Contains the directory for the currently active release (e.g., `docs-project/current/v.0.2.0-streamline-workflow/`). Active development happens here.
- **`docs-project/done/`**: An archive containing directories of completed and released work.

Within a release directory (primarily in `docs-project/current/`), individual tasks are represented by **structured Markdown files** (`.md`).

##### Optional Release Backlog Subdirectory

This holds notes or draft tasks. The AI agent can be instructed to run the `docs-dev/workflow-instructions/lets-spec-from-release-backlog.md` workflow instruction to process items from this internal backlog and integrate them as structured tasks into the *same* release's `tasks/` directory. This workflow instruction can also target a specific release in the main `docs-project/backlog/` if needed.

#### Standard Task File Format

Each task `.md` file should follow this structure:

```markdown
---
id: <unique_task_id> # e.g., v.0.2.3-1, v.0.3.0-5 (See 'Task ID Convention' below)
status: [pending | in-progress | done | blocked]
priority: [high | medium | low]
dependencies: [<task_id_1>, <task_id_2>] # List of IDs this task depends on
comment_ids: [<github_comment_id_1>] # Optional: Links back to PR comments
---

# Task Title: A clear, concise title

## Description
Briefly describe the goal of this task. What should be achieved?

## Implementation Details / Notes
- Specific steps required for implementation.
- Pointers to relevant code sections or files.
- Design considerations, constraints, or decisions made.
- Links to relevant documentation (e.g., `docs-dev/guides/coding-standards.md`), ADRs (`docs-dev/decisions/...`), or external resources. **Always use root-relative paths (starting from the project root), not paths relative to the task file (e.g., `../../guides/coding-standards.md`).**

## Acceptance Criteria / Test Strategy
- How will we know this task is successfully completed?
- Specific tests to write or run (unit, integration, manual).
- Expected outcomes or observable behaviors.
- Use Markdown checklists for breaking down implementation steps:
  - [ ] Sub-task or step 1
  - [ ] Sub-task or step 2
```
This structured format ensures clarity for both humans and AI agents interacting with the tasks. Providing comprehensive details in the "Implementation Details / Notes" and "Acceptance Criteria" is key for effective AI collaboration.

#### Task ID Convention

The `id` field in the task file's frontmatter serves as a unique identifier for the task across the entire project history. The convention is:

`v.X.Y.Z-<task-number-in-release>`

Where:
- `v.X.Y.Z` is the semantic version of the release the task belongs to.
- `<task-number-in-release>` is a sequential number (starting from 1) assigned to the task within that specific release.

**Rationale:**
- **Unique Identification:** This format ensures every task has a globally unique ID, preventing conflicts when referencing tasks from different releases.
- **Cross-Release Referencing:** Allows unambiguous linking to tasks from past or future releases (e.g., in dependency lists or documentation).
- **Intra-Release Referencing:** Within the context of a single release, tasks can often be referred to more simply by their `<task-number-in-release>` (e.g., "depends on task 5"), as the release version is implied.

**Important Note:** This ID convention applies only to the `id` field in the frontmatter. The **filename convention** for task files is `NNN-task-name.md` (where `NNN` is a zero-padded, three-digit number reflecting the order within the release's `tasks/` directory, e.g., `001-task-name.md`, `010-another-task.md`), ensuring simple alphabetical sorting and quick identification within the file system.

### 2. Version Naming

We follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes (x.0.0)
- MINOR: New features (0.x.0)
- PATCH: Bug fixes (0.0.x)

### 3. Task Workflow

1. **Planning**: Tasks are defined in the appropriate release directory within `docs-project/backlog/` (e.g., `docs-project/backlog/v.0.3.0/tasks/01-new-feature.md`).
2. **Activation**: When a release becomes active, its directory is moved from `docs-project/backlog/` to `docs-project/current/` (e.g., `mv docs-project/backlog/v.0.2.0 docs-project/current/`).
3. **Execution**: Developers work on tasks within `docs-project/current/{release_dir}/tasks/`, updating the status in the task file's frontmatter as they progress (`pending` -> `in-progress` -> `done`).
4. **Completion**: Once all tasks for a release in `docs-project/current/` are marked `done`, the release process begins.
5. **Archiving**: After a release is successfully shipped, its directory is moved from `docs-project/current/` to `docs-project/done/` (e.g., `mv docs-project/current/v.0.2.0 docs-project/done/`).

### 4. Task Transitions

#### Tooling for Task Progression

- Use `bin/tn` (get-next-task) to quickly identify the next actionable task in the current release. This tool checks all tasks and their dependencies, skipping those that are done or blocked, and surfaces the next one ready to be worked on.

When moving a task between states, follow these guidelines:

#### Task State Transitions

Key checks when updating a task's `status` field:

- **`pending` → `in-progress`**:
    - Task specification (Description, Implementation Details, Acceptance Criteria) is clear.
    - Dependencies listed in `dependencies` are met (i.e., those tasks are `done`).
    - Implementation plan is understood.
    - Test strategy is defined.
- **`in-progress` → `done`**:
    - All implementation steps (including Markdown checklist items) are completed.
    - All acceptance criteria are met.
    - Corresponding tests (unit, integration) are passing.
    - Code adheres to project coding standards.
    - Relevant documentation (code comments, guides, examples) has been updated.
    - Changes have been committed following version control guidelines.
    - If applicable, the Pull Request incorporating the changes has been reviewed and merged.
    - Any decisions made or significant learnings are documented (e.g., in the task file, an ADR in `docs-dev/decisions/`, or a `self-reflect` log).

Moving a whole release directory follows the same logic: ensure all contained tasks meet the criteria for the next state (`backlog` -> `current`, `current` -> `done`).

### 5. Implementation Process

#### Specification Workflows

Tasks and release structures are typically generated through one of three primary workflows, facilitated by `lets-spec-*` workflow instructions (located in `docs-dev/workflow-instructions/`):

1.  **PR Feedback (`lets-spec-from-pr-comments`)**: Processes comments on a Pull Request to generate specific, actionable tasks (usually resulting in a *Patch* release) aimed at addressing the feedback. Tasks are created directly in the `docs-project/current/` release directory.
2.  **Feature Requirements (`lets-spec-from-frd`)**: Parses a Feature Requirement Document (FRD) to outline a new capability. This typically generates tasks for a *Feature* release, potentially planned in `docs-project/backlog/` first.
3.  **Product Requirements (`lets-spec-from-prd`)**: Parses a high-level Product Requirement Document (PRD). This often results in multiple releases (Major, Feature) and sets up the initial structure and tasks, usually starting in `docs-project/backlog/`.

#### General Implementation Process (per task) - Integrating AI Collaboration

1.  **Planning & Understanding (Planning Before Prompting)**: Before involving the AI in coding, *thoroughly* understand the task requirements (from the `.md` file). Plan the implementation approach:
    *   Break down the task into smaller, logical steps.
    *   Identify potential challenges or areas needing clarification.
    *   Outline the intended design, interfaces, and test structures.
    *   Gather necessary context (relevant existing code, patterns, `docs-project/blueprint.md`, `docs-project/architecture.md`). This detailed planning is crucial input for guiding the AI effectively.
2.  **Test-Driven Development (AI-Assisted)**:
    *   **Write Tests (Test Phase in `work-on-task`):** Guide the AI to generate failing tests based on the planned structure and acceptance criteria using the testing phase described in the `docs-dev/workflow-instructions/work-on-task.md` workflow. *Review generated tests carefully.*
    *   **Implement Code:** Provide the AI with specific, small steps from your plan (e.g., implement function X based on this signature and pseudocode). *Review generated code rigorously.*
    *   **Refactor:** Guide the AI in refactoring for clarity and efficiency once tests pass.
3.  **Documentation & Committing (`lets-commit`)**: Document decisions within the code or task file. Guide the AI to generate or help format commit messages according to conventions using the `docs-dev/workflow-instructions/lets-commit.md` workflow. *Review commit messages.* Commit changes frequently.
4.  **Review & Reflection**: After completing a task or a significant work segment, engage in self-reflection. Analyze the implemented solution, the effectiveness of any AI collaboration, update relevant documentation, and capture learnings. Use the [`create-reflection-note.md`](../workflow-instructions/create-reflection-note.md) workflow to capture these insights. These individual reflection notes (e.g., saved in `docs-project/current/{release_dir}/reflections/YYYYMMDD-taskID.md`) serve as valuable input for the [`create-retrospective-document.md`](../workflow-instructions/create-retrospective-document.md) workflow.

**Key AI Collaboration Principles in this workflow:** Treat the AI as a junior developer needing guidance. Provide detailed context and specific instructions derived from your planning phase. Review all AI output critically. Refer to `docs-dev/guides/coding-standards.md` for more on AI collaboration best practices.

## Related Documentation

Essential standards and guidelines:
- [Coding Standards](docs-dev/guides/coding-standards.md)
- [Testing Guidelines](docs-dev/guides/testing.md)
- [Documentation Standards](docs-dev/guides/documentation.md)
- [Release Process](docs-dev/guides/ship-release.md)
- [Error Handling](docs-dev/guides/error-handling.md)
- [Performance](docs-dev/guides/performance.md)
- [Security](docs-dev/guides/security.md)
- [Writing Guides Guide](docs-dev/guides/writing-guides-guide.md)
- [Troubleshooting Workflow](docs-dev/guides/troubleshooting-workflow.md)
- [Strategic Planning Guide](docs-dev/guides/strategic-planning-guide.md)
- [Project Roadmap](docs-project/roadmap.md)
