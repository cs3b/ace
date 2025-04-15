# Load Environment Command

**Goal:** Load the necessary context for development, including general process documentation, project-specific details, and the current project state. This command focuses *only* on loading context, not initiating task execution (see `lets-start`).

## Process Steps

1.  **Load General Process & Guides:**
    *   Understand the overall development process: [Project Management Guide](../guides/project-management.md)
    *   Review core development standards (link to specific guides as needed):
        *   [Coding Standards](../guides/coding-standards.md)
        *   [Testing Guidelines](../guides/testing.md)
        *   [Documentation Standards](../guides/documentation.md)
        *   [Version Control](../guides/version-control.md)
        *   [Release Process](../guides/ship-release.md)
    *   List available general commands: `ls -1 docs-dev/commands/`

2.  **Load Project-Specific Context:**
    *   Review project objectives: `cat docs-dev/project/what-do-we-build.md`
    *   Examine high-level architecture: `cat docs-dev/project/architecture.md`
    *   Check project structure and key files: `cat docs-dev/project/blueprint.md` (Note: Run `generate-blueprint` if this seems outdated).
    *   Review project-specific decisions: `ls -1 docs-dev/decisions/`

3.  **Determine Current Work State:**
    *   Identify active release directory: `ls -1 docs-dev/project/current/`
    *   List tasks within the active release: `ls -1 docs-dev/project/current/*/tasks/*.md`
    *   Review task details as needed (e.g., `cat docs-dev/project/current/*/tasks/NN-*.md`).

4.  **Check Recent Changes:**
    *   View recent commits: `git log -n 5 --oneline`
    *   View recent file changes: `git diff --name-status HEAD~5..HEAD`

## Success Criteria

1.  **General Process Understood:** Core development guides and available commands are known.
2.  **Project Context Loaded:** Project goals (`what-do-we-build.md`), architecture (`architecture.md`), and structure (`blueprint.md`) are understood.
3.  **Current State Identified:** The active release directory in `docs-dev/project/current/` and its tasks are known. Recent code changes are reviewed.
4.  **Environment Ready:** Working directory clean, dependencies installed, latest code pulled.
5.  **Ready for Next Step:** Context is loaded, allowing the user to proceed with selecting a task and initiating work using `lets-start`.
