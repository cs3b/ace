# Load Environment Workflow Instruction

**Goal:** Load the necessary context for development, including general process documentation,
project-specific details, and the current project state. This workflow instruction focuses *only*
on loading context, not initiating task execution (see `work-on-task`).

## Prerequisites

- Executed within the project's root directory.
- `docs-dev/` and `docs-project/` directories exist and are populated according to project standards.
- `docs/blueprint.md` exists and is reasonably up-to-date.

## Input

- User request to load the environment context.

## Process Steps

1. **Load General Process & Guides:**
    - Understand the overall development process: [docs-dev/guides/project-management.g.md](docs-dev/guides/project-management.g.md)
    - Review core development standards (link to specific guides as needed):
    - [Coding Standards](docs-dev/guides/coding-standards.g.md)
    - [Testing Guidelines](docs-dev/guides/testing.g.md)
    - [Documentation Standards](docs-dev/guides/documentation.g.md)
    - [Version Control](docs-dev/guides/version-control-system.g.md)
    - [Release Process](docs-dev/guides/release-publish.g.md)
    List available general workflow instructions: [docs-dev/workflow-instructions/](docs-dev/workflow-instructions/)

2. **Load Project-Specific Context:**
    - Review project objectives: [docs/what-do-we-build.md](docs/what-do-we-build.md)
    - Examine high-level architecture: [docs/architecture.md](docs/architecture.md)
    - Check project structure and key files: [docs/blueprint.md](docs/blueprint.md).

3. **Determine Current Work State:**
    - Identify active release directory: [docs-project/current/](docs-project/current/)
    - List tasks within the active release: [docs-project/current/*/tasks/*.md](docs-project/current/)
    - Review task details as needed (e.g., [docs-project/current/*/tasks/NN-*.md](docs-project/current/)).

4. **Check Recent Changes:**
    - View recent commits: `git log -n 5 --oneline`
    - View recent file changes: `git diff --name-status HEAD~5..HEAD`

## Output / Success Criteria

1. **General Process Understood:** Core development guides and available commands are known.
2. **Project Context Loaded:** Project goals (`what-do-we-build.md`), architecture
   (`architecture.md`), and structure (`blueprint.md`) are understood.
3. **Current State Identified:** The active release directory in `docs-project/current/` and its
   tasks are known. Recent code changes are reviewed.
4. **Environment Ready:** Working directory clean, dependencies installed, latest code pulled.
5. **Ready for Next Step:** Context is loaded, allowing the user to proceed with selecting a task
   and initiating work using `work-on-task`.

## Reference Documentation

- [Project Management Guide](docs-dev/guides/project-management.g.md)
- [Coding Standards Guide](docs-dev/guides/coding-standards.g.md)
- [Testing Guidelines Guide](docs-dev/guides/testing.g.md)
- [Documentation Standards Guide](docs-dev/guides/documentation.g.md)
- [Version Control Guide](docs-dev/guides/version-control-system.g.md)
- [Release Process Guide](docs-dev/guides/release-publish.g.md)
- [What do we build](docs/what-do-we-build.md)
- [What is our architecture](docs/architecture.md)
- [What is our blueprint](docs/blueprint.md)
- [`Work on Task` Workflow Instruction](docs-dev/workflow-instructions/work-on-task.wf.md)
