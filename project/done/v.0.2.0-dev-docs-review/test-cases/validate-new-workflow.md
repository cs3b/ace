# Test Cases for Unified Workflow (v0.2.0)

## Feature: Unified Task Management & Workflow Streamlining

### Process Validation Scenarios
- [ ] **Scenario 1: Starting a New Task**
  - Run `load-env`. Verify it identifies `project/current/v.0.2.0/`.
  - Run `lets-start`. Verify it guides selection of a task file (e.g., `tasks/01-consolidate-task-systems.md`) and references its structure.
- [ ] **Scenario 2: Processing PR Feedback**
  - Simulate fetched PR data (JSON files) in a temporary `docs/{pr_path}` structure within `project/current/v.0.2.0/`.
  - Run `lets-spec-from-pr-comments {path_to_v0.2.0}`.
  - Verify that new/updated `.md` task files are created in `project/current/v.0.2.0/tasks/` with correct formatting, sequence prefixes, dependencies, and `comment_ids`.
- [ ] **Scenario 3: Reviewing Progress**
  - Manually add/modify task files in `project/current/v.0.2.0/tasks/` (e.g., change status in frontmatter).
  Run `review-kanban-board`. Verify its description guides checking the status within the task files in `project/current/`.
- [ ] **Scenario 4: Preparing a Minor Release (Simulated)**
  - Review `guides/prepare-release/prepare-release-documentation.md`.
  - Verify it clearly states the *minimal* required documentation for a patch release using the `prepare-release/v.x.x.x/` structure.
  - Run `lets-release`. Verify it points to the updated guide.
- [ ] **Scenario 5: Self-Reflection**
  - Run `self-reflect`. Verify it correctly references `project/current/` for task status and the appropriate location for ADRs/guides for updates.

### Consistency Checks
- [ ] **Terminology:** Search codebase (`docs-dev/`) for outdated terms like "1-next", references to `_dev/kanban/`, or inconsistent task state names. Verify they have been updated to "current" and aligned terminology.
- [ ] **Command/Guide Linking:** Manually review key commands (`lets-commit`, `lets-tests`, etc.). Verify they link to the relevant guide in `docs-dev/guides/` and don't excessively duplicate content.
- [ ] **Task File Format:** Check generated/updated task files (from Scenario 2) against the standard format defined in `docs/unified-workflow-guide.md`.

## Test Environment Setup
- A clean checkout of the repository branch containing the v0.2.0 changes.
- Sample PR feedback JSON data (can be derived from `project/task-manager/feedback/pr-comments.json`).

## Sample Test Data
- Use sample PR comment JSON for Scenario 2.
- Create sample task files with varying statuses for Scenario 3.