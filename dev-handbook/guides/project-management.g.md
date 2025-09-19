# Project Management Guide

## Goal

This guide defines the core development philosophy, project structure, task management system, and standard
workflows used within this toolkit, ensuring clarity, maintainability, and effective knowledge sharing for
both human developers and AI agents.

Our development workflow is centered around:

- Iterative, task-based development
- Clear documentation and knowledge preservation
- Transparent progress tracking
- Quality-driven releases
- Workflow Instructions driven AI interactions

Our development workflow emphasizes planning before implementation ("Slow Vibe Coding").
We use a workflow instruction-based approach for AI interactions. Each workflow instruction in the
`workflow-instructions/` directory represents a specific workflow or interaction pattern with clear
inputs, processes, and success criteria.

## Directory Structure

The `dev-taskflow` directory organizes project documentation and management:

```text
dev-taskflow
├── architecture.md
├── backlog
│   └── v.0.1.0-preflight-for-coding-agent
├── blueprint.md
├── current
├── done
│   ├── v.0.0.1
│   ├── v.0.2.0-dev-docs-review
│   ├── v.0.2.1-spec-form-diff
│   ├── v.0.2.2-feedback-to-process
└── what-do-we-build.md
```

(Use `tree dev-taskflow -L 2` from the project root to view the current structure)

> **Strategic vs Operational Planning**
> High-level direction is captured in the [Project Roadmap](dev-taskflow/roadmap.md) and detailed in the
> [Strategic Planning Guide](dev-handbook/guides/strategic-planning.g.md).
> Release planning and day-to-day execution described in this guide must align with the roadmap's objectives
> and timelines.

## Task Management

### 2. Version Naming

Tasks are managed within the `dev-taskflow/` subdirectories, representing a simple Kanban-style flow:

- **`dev-taskflow/backlog/`**: Contains directories for future, planned releases. Release directories must use
  specific semantic versions, including the patch level, followed by a descriptive codename (e.g.,
  `dev-taskflow/backlog/v.0.3.0-new-feature-suite/`). Tasks are defined and planned here.
- **`dev-taskflow/current/`**: Contains the directory for the currently active release, following the same
  naming convention: a specific semantic version (including patch level) and a codename (e.g.,
  `dev-taskflow/current/v.0.2.0-streamline-workflow/`). Active development happens here.
- **`dev-taskflow/done/`**: An archive containing directories of completed and released work, with release
  directories also following the `v.X.Y.Z-codename` convention (e.g., `dev-taskflow/done/v.0.1.0-initial-setup/`).

Within a release directory (primarily in `dev-taskflow/current/`), individual tasks are represented by
**structured Markdown files** (`.md`).

#### Optional Release Backlog Subdirectory

This holds notes or draft tasks. The AI agent can be instructed to run the
`dev-handbook/workflow-instructions/lets-spec-from-release-backlog.md` workflow instruction to process items from
this internal backlog and integrate them as structured tasks into the *same* release\\\'s `tasks/` directory.
This workflow instruction can also target a specific release in the main `dev-taskflow/backlog/` if needed.

#### Standard Task File Format

Each task `.md` file should follow this structure:

```markdown
---
id: <unique_task_id> # e.g., v.0.2.3+task.1, v.0.3.0+task.5 (See 'Task ID Convention' below)
status: [pending | in-progress | done | blocked] # See also VALID_STATUSES in lint-task-metadata for more
priority: [high | medium | low] # See also VALID_PRIORITIES in lint-task-metadata
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
- Links to relevant documentation (e.g., `dev-handbook/guides/coding-standards.md`), ADRs (`dev-handbook/decisions/...`),
> or external resources. **Always use root-relative paths (starting from the project root), not paths relative
> to the task file (e.g., `../../guides/coding-standards.md`).**

**Acceptance Criteria / Test Strategy**:
- How will we know this task is successfully completed?
- Specific tests to write or run (unit, integration, manual).
- Expected outcomes or observable behaviors.
- Use Markdown checklists for breaking down implementation steps:
  - [ ] Sub-task or step 1
  - [ ] Sub-task or step 2
```

This structured format ensures clarity for both humans and AI agents interacting with the tasks. Providing
comprehensive details in the \"Implementation Details / Notes\" and \"Acceptance Criteria\" is key for effective
AI collaboration.

#### Task ID Convention

The `id` field in the task file\'s frontmatter serves as a unique identifier for the task across the entire
project history. The convention is:

`v.X.Y.Z+task.<sequential_number>`

Where:

- `v.X.Y.Z` is the specific semantic version of the release the task belongs to (e.g., `v.0.3.0`). The patch

> version `Z` must be explicit and not a placeholder like `x`.

- `+task.<sequential_number>` is build metadata, as per SemVer, indicating the task sequence within that

> specific release, starting from 1 (e.g., `+task.1`, `+task.12`).

**Important:** While this section describes the *format* of the Task ID, the actual generation of a new, unique, and correctly sequenced task ID **must** be done using the `task-manager generate-id` command. This command ensures the correct sequential number is used for the current release. Always run `task-manager generate-id VERSION` from the project root to obtain the ID for a new task.

**Rationale:**

- **Unique Identification:** This format ensures every task has a globally unique ID, preventing conflicts when

> referencing tasks from different releases.

- **Cross-Release Referencing:** Allows unambiguous linking to tasks from past or future releases (e.g., in

> dependency lists or documentation).

- **Intra-Release Referencing:** Within the context of a single release, tasks can often be referred to more

> simply by their `<task-number-in-release>` (e.g., \"depends on task 5\"), as the release version is implied.

**Important Note:** This ID convention applies only to the `id` field in the frontmatter. The **filename
convention** for task files is `NNN-task-name.md` (where `NNN` is a zero-padded, three-digit number reflecting
the order within the release\'s `tasks/` directory, e.g., `001-task-name.md`, `010-another-task.md`), ensuring
simple alphabetical sorting and quick identification within the file system.

### 3. Task Workflow

We follow semantic versioning (MAJOR.MINOR.PATCH):

- MAJOR: Breaking changes (x.0.0)
- MINOR: New features (0.x.0)
- PATCH: Bug fixes (0.0.x)

1. **Planning**: Tasks are defined in the appropriate release directory (e.g., `v.0.3.0-example-feature/`)
   within `dev-taskflow/backlog/`. For example, a task file might be
   `dev-taskflow/backlog/v.0.3.0-example-feature/tasks/001-new-feature.md`.

1. **Activation**: When a release becomes active, its directory (e.g., `v.0.2.0-active-sprint`) is moved from
   `dev-taskflow/backlog/` to `dev-taskflow/current/`. For example:
   `mv dev-taskflow/backlog/v.0.2.0-active-sprint dev-taskflow/current/`.

1. **Execution**: Developers work on tasks within `dev-taskflow/current/{release_dir}/tasks/`, updating the
   status in the task file\'s frontmatter as they progress (`pending` -> `in-progress` -> `done`).

1. **Completion**: Once all tasks for a release in `dev-taskflow/current/` are marked `done`, the release
   process begins.

1. **Archiving**: After a release is successfully published, its directory (e.g., `v.0.2.0-active-sprint`) is moved
   from `dev-taskflow/current/` to `dev-taskflow/done/` as part of the publish release process. This archival step
   signifies the completion of the release lifecycle and preserves the complete development context. For example:
   `mv dev-taskflow/current/v.0.2.0-active-sprint dev-taskflow/done/`.

   The archival process is detailed in the [Publish Release Guide](dev-handbook/guides/release-publish.g.md) and
   executed through the [Publish Release Workflow](dev-handbook/workflow-instructions/publish-release.wf.md).

### 4. Task Transitions

#### Tooling for Task Progression

- **`task-manager next`**: Identifies the next actionable task in the current release (by default, or a
  specified release). This tool considers task dependencies, prioritizes `in-progress` tasks over `pending` ones,
  and sorts tasks numerically by their sequential ID number (e.g., `+task.2` before `+task.10`).
- **`task-manager generate-id VERSION`**: Generates the next available full task ID (e.g., `v.X.Y.Z+task.N+1`) for a
  specified release (or the current release by default). This helps in creating new task files with correctly
  formatted and unique IDs.
- **`task-manager list`**: Lists all tasks within a specified release (or the current release by default).
  Tasks are topologically sorted based on their dependencies, and then secondarily by their task ID\'s sequential
  number. The output for each task includes its ID, status, title, and dependencies. The \"next actionable task\"
  (as would be identified by `task-manager next`) is highlighted in the list.
- **`release-manager current`**: Determines the appropriate directory for storing newly created
  tasks and returns version information. Returns the path to the current release directory (e.g.,
  `dev-taskflow/current/v.X.Y.Z-codename`) and version string (e.g., `v.X.Y.Z`) when a current release exists,
  or the backlog tasks path (`dev-handbook/backlog/tasks`) and empty version when no current release is detected.
  This tool is essential for automated task creation workflows.
- **`# Run project-specific lint command`**: Includes a task metadata linter (`dev-handbook/tools/lint-task-metadata`) that validates task
  files in `dev-taskflow/backlog` and `dev-taskflow/current` for correct ID format, required fields (status,
  priority), valid values, and other conventions.

When moving a task between states, follow these guidelines:

#### Task State Transitions

Key checks when updating a task\'s `status` field:

1. **`pending` → `in-progress`**:

- Task specification (Description, Implementation Details, Acceptance Criteria) is clear.
- Dependencies listed in dependencies are met (i.e., those tasks are done).
- Implementation plan is understood.
- Test strategy is defined.

1. **`in-progress` → `done`**:

- All implementation steps (including Markdown checklist items) are completed.
- All acceptance criteria are met.
- Corresponding tests (unit, integration) are passing.
- Code adheres to project coding standards.
- Relevant documentation (code comments, guides, examples) has been updated.
- Changes have been committed following version control guidelines.
- If applicable, the Pull Request incorporating the changes has been reviewed and merged.
- Any decisions made or significant learnings are documented (e.g., in the task file, an ADR in

  > `dev-handbook/decisions/`, or a `self-reflect` log).

Moving a whole release directory follows the same logic: ensure all contained tasks meet the criteria for the
next state (`backlog` -> `current`, `current` -> `done`).

### 5. Implementation Process

#### Specification Workflows

Tasks and release structures are typically generated through one of three primary workflows, facilitated by
`lets-spec-*` workflow instructions (located in `dev-handbook/workflow-instructions/`):

1. **PR Feedback (`lets-spec-from-pr-comments`)**: Processes comments on a Pull Request to generate specific,
   actionable tasks (usually resulting in a Patch release) aimed at addressing the feedback. Tasks are created
   directly in the `dev-taskflow/current/` release directory.
1. **Feature Requirements (`lets-spec-from-frd`)**: Parses a Feature Requirement Document (FRD) to outline a new
   capability. This typically generates tasks for a Feature release, potentially planned in
   `dev-taskflow/backlog/` first.
1. **Product Requirements (`lets-spec-from-prd`)**: Parses a high-level Product Requirement Document (PRD). This
   often results in multiple releases (Major, Feature) and sets up the initial structure and tasks, usually
   starting in `dev-taskflow/backlog/`.

#### General Implementation Process (per task) - Integrating AI Collaboration

1. **Planning & Understanding (Planning Before Prompting)**: Before involving the AI in coding, *thoroughly*
   understand the task requirements (from the `.md` file). Plan the implementation approach:
    - Break down the task into smaller, logical steps.
    - Identify potential challenges or areas needing clarification.
    - Outline the intended design, interfaces, and test structures.
    - Gather necessary context (relevant existing code, patterns, `docs/blueprint.md`,
      `docs/architecture.md`). This detailed planning is crucial input for guiding the AI effectively.
2. **Test-Driven Development (AI-Assisted)**:
    - **Write Tests (Test Phase in `work-on-task`)**: Guide the AI to generate failing tests based on the planned
      structure and acceptance criteria using the testing phase described in the
      `dev-handbook/workflow-instructions/work-on-task.md` workflow. *Review generated tests carefully.*
    - **Implement Code**: Provide the AI with specific, small steps from your plan (e.g., implement function X
      based on this signature and pseudocode). *Review generated code rigorously.*
    - **Refactor**: Guide the AI in refactoring for clarity and efficiency once tests pass.
3. **Documentation & Committing (`lets-commit`)**: Document decisions within the code or task file. Guide the
   AI to generate or help format commit messages according to conventions using the
   `dev-handbook/workflow-instructions/lets-commit.md` workflow. *Review commit messages.* Commit changes frequently.
4. **Review & Reflection**: After completing a task or a significant work segment, engage in self-reflection.
      Analyze the implemented solution, the effectiveness of any AI collaboration, update relevant documentation, and
      capture learnings. Use the [`dev-handbook/workflow-instructions/create-reflection-note.wf.md`](../workflow-instructions/create-reflection-note.wf.md)
      workflow to capture these insights. These individual reflection notes serve as valuable input for the
      retrospective process.

**Key AI Collaboration Principles in this workflow:** Treat the AI as a junior developer needing guidance.
> Provide detailed context and specific instructions derived from your planning phase. Review all AI output
> critically. Refer to `dev-handbook/guides/coding-standards.md` for more on AI collaboration best practices.

## Agent Operational Boundaries

To ensure project integrity and prevent unintentional modifications to critical or archived areas, the AI
agent's operations are guided by path-based restrictions defined in the project's `docs/blueprint.md`
file. These restrictions specify:

- **Read-Only Paths**: Files and directories that the agent should not attempt to modify. This is useful for
  protecting completed work (like released tasks or documentation) or sensitive configuration files.

- **Ignored Paths**: Files, directories, or glob patterns that the agent should disregard entirely during its
  operations (e.g., search, read, edit). This typically includes build artifacts, version control directories,
  temporary files, and other non-essential items.

By adhering to these rules, the agent can operate more safely and efficiently within the project. For the
specific configurations of these paths for this project, please refer to the "Read-Only Paths" and
"Ignored Paths" sections in `docs/blueprint.md`.

### Policy on Done Tasks with Changing Referenced Files

While agents are automatically prevented from modifying done tasks via the `dev-taskflow/done/**/*` ignore rule,
there are edge cases where human intervention may be necessary when referenced files change. This policy clarifies
when such updates are acceptable:

#### Prohibited Modifications (Never Allowed)

- **Content Changes**: Modifying task scope, objectives, implementation details, or completion status
- **Historical Revision**: Changing decisions, rationale, or outcomes documented in the task
- **Status Changes**: Altering completion status, priority, or dependencies after the task is done

#### Allowed Reference Updates (Human Oversight Required)

- **Broken Link Fixes**: Updating file paths when referenced files are moved or renamed
- **Security Annotations**: Adding critical security notices or deprecation warnings as addendum notes
- **Accessibility Improvements**: Fixing broken links that prevent navigation or reference resolution
- **Metadata Additions**: Adding clarifying notes that preserve historical context while improving usability

#### Process for Human Updates

When human updates to done tasks are necessary:

1. **Justification Required**: Document the specific reason (security, broken links, accessibility)
2. **Additive Approach**: Prefer adding clarifying notes rather than modifying original content
3. **Preserve History**: Maintain original context and decision-making rationale
4. **Clear Attribution**: Mark human modifications with timestamps and reasons
5. **Minimal Scope**: Limit changes to the specific issue being addressed

#### Examples

**Acceptable**: Adding a note that a referenced file has moved:

```
> **Update Note (2024-01-15)**: Referenced file `old/path/file.md` has been moved to `new/path/file.md`
```

**Acceptable**: Adding a security notice:

```
> **Security Notice (2024-01-15)**: The library referenced in this task has known vulnerabilities. See [security advisory](#link) for details.
```

**Unacceptable**: Changing the task's implementation approach or completion criteria after it's marked done.

This policy maintains the balance between preserving historical accuracy and ensuring practical usability of project documentation.

## Related Documentation

Essential standards and guidelines:

- [Coding Standards](dev-handbook/guides/coding-standards.g.md)
- [Testing Guidelines](dev-handbook/guides/testing.g.md)
- [Documentation Standards](dev-handbook/guides/documentation.g.md)
- [Publish Release Process](dev-handbook/guides/release-publish.g.md) (Final deployment and archival)
- [Release Codenames Guide](dev-handbook/guides/project-management/release-codenames.g.md) (Philosophy and approach for release naming)
- [Error Handling](dev-handbook/guides/error-handling.g.md)
- [Performance](dev-handbook/guides/performance.g.md)
- [Security](dev-handbook/guides/security.g.md)

- [Troubleshooting Workflow](dev-handbook/guides/debug-troubleshooting.g.md)
- [Strategic Planning Guide](dev-handbook/guides/strategic-planning.g.md)
- [Project Roadmap](dev-taskflow/roadmap.md)
