# Development Philosophy and Project Management

Our development workflow is centered around:
- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases
- Command-driven AI interactions

Our development workflow emphasizes planning before implementation ("Slow Vibe Coding"). We use a command-based approach for AI interactions, replacing the previous prompts-based system. Each command in the `commands/` directory represents a specific workflow or interaction pattern with clear inputs, processes, and success criteria.

## Directory Structure

The `docs-dev` directory organizes project documentation and management:

```
docs-dev/
├── guides/           # Development standards and practices
├── commands/         # AI interaction commands and workflows
├── project/          # Project-specific materials (Task Management)
│   ├── backlog/      # Future planned work (release dirs: e.g., v.0.3.0/)
│   ├── current/      # Current release/sprint tasks (release dir: e.g., v.0.2.0/)
│   └── done/         # Completed work (archive of release dirs)
├── tools/            # Helper scripts (e.g., for fetching data)
└── reflections/      # Session logs and learnings (Optional)
```
(Use `tree docs-dev -L 2` to view the current structure)

## Task Management

### 1. Task Organization

Tasks are managed within the `project/` subdirectories, representing a simple Kanban-style flow:

- **`project/backlog/`**: Contains directories for future, planned releases (e.g., `v.0.3.0-feature-x/`). Tasks are defined and planned here.
- **`project/current/`**: Contains the directory for the currently active release (e.g., `v.0.2.0-streamline-workflow/`). Active development happens here.
- **`project/done/`**: An archive containing directories of completed and released work.

Within a release directory (primarily in `current/`), individual tasks are represented by **structured Markdown files** (`.md`).

#### Standard Task File Format

Each task `.md` file should follow this structure:

```markdown
---
id: <unique_task_id> # e.g., 01, 02-subtask-a, etc. (Sequence prefix is common)
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
- Links to relevant documentation, ADRs, or external resources.

## Acceptance Criteria / Test Strategy
- How will we know this task is successfully completed?
- Specific tests to write or run (unit, integration, manual).
- Expected outcomes or observable behaviors.
- Use Markdown checklists for breaking down implementation steps:
  - [ ] Sub-task or step 1
  - [ ] Sub-task or step 2
```
This structured format ensures clarity for both humans and AI agents interacting with the tasks.

### 2. Version Naming

We follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes (x.0.0)
- MINOR: New features (0.x.0)
- PATCH: Bug fixes (0.0.x)

### 3. Task Workflow

1. **Planning**: Tasks are defined in the appropriate release directory within `backlog/` (e.g., `backlog/v.0.3.0/tasks/01-new-feature.md`).
2. **Activation**: When a release becomes active, its directory is moved from `backlog/` to `current/` (e.g., `mv project/backlog/v.0.2.0 project/current/`).
3. **Execution**: Developers work on tasks within `current/{release_dir}/tasks/`, updating the status in the task file's frontmatter as they progress (`pending` -> `in-progress` -> `done`).
4. **Completion**: Once all tasks for a release in `current/` are marked `done`, the release process begins.
5. **Archiving**: After a release is successfully shipped, its directory is moved from `current/` to `done/` (e.g., `mv project/current/v.0.2.0 project/done/`).

### 4. Task Transitions

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
    - Any decisions made or significant learnings are documented (e.g., in the task file, ADR, or `self-reflect` log).

Moving a whole release directory follows the same logic: ensure all contained tasks meet the criteria for the next state (`backlog` -> `current`, `current` -> `done`).

### 5. Implementation Process

#### Specification Workflows

Tasks and release structures are typically generated through one of three primary workflows, facilitated by `lets-spec-*` commands:

1.  **PR Feedback (`lets-spec-from-pr-comments`)**: Processes comments on a Pull Request to generate specific, actionable tasks (usually resulting in a *Patch* release) aimed at addressing the feedback. Tasks are created directly in the `current/` release directory.
2.  **Feature Requirements (`lets-spec-from-frd`)**: Parses a Feature Requirement Document (FRD) to outline a new capability. This typically generates tasks for a *Feature* release, potentially planned in `backlog/` first.
3.  **Product Requirements (`lets-spec-from-prd`)**: Parses a high-level Product Requirement Document (PRD). This often results in multiple releases (Major, Feature) and sets up the initial structure and tasks, usually starting in `backlog/`.

#### General Implementation Process (per task)

1.  **Planning & Understanding**: Before writing code, thoroughly understand the task requirements (from the `.md` file), plan the implementation approach, and identify potential challenges. Design interfaces and test structures.
2.  **Test-Driven Development**:
    *   Write failing tests that capture the acceptance criteria.
    *   Implement the minimal code required to make the tests pass.
    *   Refactor the code for clarity and efficiency while keeping tests green.
3.  **Documentation & Committing**: Document design decisions within the code or task file. Commit changes frequently using atomic, well-formatted commit messages.
4.  **Review & Reflection**: Use `self-reflect` or manual review to assess the implemented solution, update documentation, and capture learnings.

## Additional Resources

Essential standards and guidelines:
- [Coding Standards](coding-standards.md)
- [Testing Guidelines](testing.md)
- [Documentation Standards](documentation.md)
- [Release Process](ship-release.md)
- [Error Handling](error-handling.md)
- [Performance](performance.md)
- [Security](security.md)
