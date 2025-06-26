# Load Environment Workflow Instruction

**Goal:** Load the necessary context for development, including general process documentation,
project-specific details, and the current project state. This workflow instruction focuses *only*
on loading context, not initiating task execution (see `work-on-task`).

## Prerequisites

- Executed within the project's root directory.
- `dev-handbook/` and `dev-taskflow/` directories exist and are populated according to project standards.
- `docs/blueprint.md` exists and is reasonably up-to-date.

## Input

- User request to load the environment context.

## Process Steps

1. **Load General Process & Guides:**
    - Understand the overall development process: [dev-handbook/guides/project-management.g.md](dev-handbook/guides/project-management.g.md)
    - Review core development standards (link to specific guides as needed):
    - [Coding Standards](dev-handbook/guides/coding-standards.g.md)
    - [Testing Guidelines](dev-handbook/guides/testing.g.md)
    - [Documentation Standards](dev-handbook/guides/documentation.g.md)
    - [Version Control](dev-handbook/guides/version-control-system.g.md)
    - [Release Process](dev-handbook/guides/release-publish.g.md)
    List available general workflow instructions: [dev-handbook/workflow-instructions/](dev-handbook/workflow-instructions/)

2. **Load Project-Specific Context:**
    - Review project objectives: [docs/what-do-we-build.md](docs/what-do-we-build.md)
    - Examine high-level architecture: [docs/architecture.md](docs/architecture.md)
    - Check project structure and key files: [docs/blueprint.md](docs/blueprint.md).

3. **Determine Current Work State:**
    - Identify active release directory: [dev-taskflow/current/](dev-taskflow/current/)
    - List tasks within the active release: [dev-taskflow/current/*/tasks/*.md](dev-taskflow/current/)
    - Review task details as needed (e.g., [dev-taskflow/current/*/tasks/NN-*.md](dev-taskflow/current/)).

4. **Check Recent Changes:**
    - View recent commits: `git log -n 5 --oneline`
    - View recent file changes: `git diff --name-status HEAD~5..HEAD`

## Output / Success Criteria

1. **General Process Understood:** Core development guides and available commands are known.
2. **Project Context Loaded:** Project goals (`what-do-we-build.md`), architecture
   (`architecture.md`), and structure (`blueprint.md`) are understood.
3. **Current State Identified:** The active release directory in `dev-taskflow/current/` and its
   tasks are known. Recent code changes are reviewed.
4. **Environment Ready:** Working directory clean, dependencies installed, latest code pulled.
5. **Ready for Next Step:** Context is loaded, allowing the user to proceed with selecting a task
   and initiating work using `work-on-task`.

## Reference Documentation

- [Project Management Guide](dev-handbook/guides/project-management.g.md)
- [Coding Standards Guide](dev-handbook/guides/coding-standards.g.md)
- [Testing Guidelines Guide](dev-handbook/guides/testing.g.md)
- [Documentation Standards Guide](dev-handbook/guides/documentation.g.md)
- [Version Control Guide](dev-handbook/guides/version-control-system.g.md)
- [Release Process Guide](dev-handbook/guides/release-publish.g.md)
- [What do we build](docs/what-do-we-build.md)
- [What is our architecture](docs/architecture.md)
- [What is our blueprint](docs/blueprint.md)
- [`Work on Task` Workflow Instruction](dev-handbook/workflow-instructions/work-on-task.wf.md)
