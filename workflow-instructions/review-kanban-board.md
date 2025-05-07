# Review Project State Workflow Instruction

## Goal
Review the overall state of project tasks across the `docs-project/backlog/`, `docs-project/current/`, and `docs-project/done/` directories to understand progress, identify blockers, prioritize current work, and plan release transitions.

## Prerequisites
- The `docs-project/` directory exists with the `backlog/`, `current/`, and `done/` subdirectories.
- Task files within `docs-project/current/*/tasks/` follow the standard Markdown format with frontmatter (including `status:` and `dependencies:` fields).

## Process Steps

The following CLI tools make it fast and reliable to review the project state and plan next actions:

1. **Summarize Recent Task Progress:**
   - Run `bin/tr` to see a table of recently updated or completed tasks (status: done or in-progress), with their IDs, titles, status, update times, and file paths. Use `--last` to filter by time window (e.g., `bin/tr --last 3.days`).

2. **Find the Next Actionable Task:**
   - Run `bin/tn` to automatically identify the next task in the current release that is not done and has all dependencies met. This helps you focus on the next logical step without manually checking dependencies.

3. **Check Recent Code Changes:**
   - Run `bin/gl` to review recent git commits across the main repo and submodules. This can help you see what has changed recently and spot work that may impact pending tasks.

4. **Review Backlog and Done Releases:**
   - List planned/future releases: `ls -1 docs-project/backlog/`
   - List completed/archived releases: `ls -1 docs-project/done/`

5. **Synthesize & Plan:**
   - Use the outputs of the above tools to:
     - Understand overall progress and what’s left in the current release
     - Identify blockers or unmet dependencies
     - Decide if the current release is ready to ship (all tasks done)
     - Plan when to activate a new release from the backlog

## Example Usage

- At the start of a work session, run `bin/tr` and `bin/tn` to get a snapshot of progress and your next task.
- Before shipping a release, use `bin/tr` to ensure all tasks are done.
- Use `bin/gl` if you need to check for recent code changes that may affect your work.

These tools automate what used to require manual grepping and inspection, making kanban/project review much faster and less error-prone.

## Input
- User request to review the project state.

## Output / Success Criteria
- [x] Contents of `backlog/`, `current/`, and `done/` are listed and reviewed.
- [x] Statuses and dependencies of tasks in the `current/` release are assessed.
- [x] Blockers or unmet dependencies are identified.
- [x] Overall project progress is understood.
- [x] Next steps are identified (e.g., next task to start, readiness for release, moving a release from backlog).

## Reference Documentation
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
- [Project Management Guide](docs-dev/guides/project-management.md) (Describes the directory structure and task format)
- Standard Task `.md` file format.

## Usage Example
Invoke this workflow instruction:
- At the start of a work session to understand the current state.
- Periodically to check progress on the current release.
- Before deciding to start the release process for the current release.
- When planning to activate a new release from the backlog.

Example Invocation:
> "Run the `review-kanban-board` workflow instruction to check the project status."
