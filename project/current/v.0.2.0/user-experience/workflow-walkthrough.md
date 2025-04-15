# Sample Walkthrough: Unified Development Workflow

This walkthrough demonstrates using the streamlined workflow for a hypothetical task.

**Goal:** Implement a fix for a bug identified in PR#5 comments.

1.  **Load Context:**
    ```bash
    load-env
    ```
    *(Agent reviews project structure, current release goals (v0.2.0), architecture, recent changes, and identifies `docs-dev/project/current/v.0.2.0/` as the active work area.)*

2.  **Process PR Feedback:**
    *   Fetch feedback for PR#5:
        ```bash
        fetch-comments-by-api https://github.com/org/repo/pull/5 # (Assuming API setup)
        ```
        *(Agent runs the command. Tool fetches data and stores it in `docs-dev/project/current/v.0.2.0/docs/pr-5-YYYYMMDD-HHMMSS/`)*
    *   Generate tasks from feedback:
        ```bash
        lets-spec-from-pr-comments docs-dev/project/current/v.0.2.0/
        ```
        *(Agent runs the command. It analyzes JSON files in `docs/pr-5...` and creates/updates task files like `docs-dev/project/current/v.0.2.0/tasks/04-fix-bug-xyz.md`. This file includes details, dependencies, and links back to comment IDs.)*

3.  **Select & Start Task:**
    ```bash
    lets-start
    ```
    *(Agent lists tasks in `project/current/v.0.2.0/tasks/` with statuses. Developer chooses `04-fix-bug-xyz.md`. Agent displays the task details from the Markdown file.)*

4.  **Implement & Test:**
    *   Write failing test:
        ```bash
        lets-tests
        ```
        *(Agent guides creation of `spec/.../fix_bug_xyz_spec.rb` based on task description/acceptance criteria.)*
    *   Run tests (expect failure): `bin/rspec spec/.../fix_bug_xyz_spec.rb`
    *   Implement fix in `lib/...`
    *   Run tests (expect pass): `bin/rspec spec/.../fix_bug_xyz_spec.rb`
    *   Fix any further issues: `lets-fix-tests` (if needed)

5.  **Commit Changes:**
    ```bash
    lets-commit
    ```
    *(Agent guides staging relevant files (`lib/...`, `spec/...`) and writing a conventional commit message, referencing `guides/version-control.md`.)*
    *   Commit: `git commit -m "fix(component): Resolve bug xyz related to PR#5"`

6.  **Update Task Status:**
    *   Edit `docs-dev/project/current/v.0.2.0/tasks/04-fix-bug-xyz.md`.
    *   Change `status: pending` to `status: done` in the frontmatter.
    *   Commit the task file change: `git add ... && git commit -m "chore(docs): Mark task 04 as done"`

7.  **Review Progress:**
    ```bash
    review-kanban-board
    ```
    *(Agent reminds to check task files in `project/current/v.0.2.0/tasks/` to see overall progress, identifying completed task 04.)*

8.  **Reflect:**
    ```bash
    self-reflect
    ```
    *(Agent prompts review of the session, commit quality, potential guide updates, or ADRs needed based on the fix.)*

This streamlined flow uses the unified task system, integrates PR feedback directly into actionable tasks, and relies on clear commands and guides.