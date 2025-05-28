# Prepare Release Workflow Instruction

## Goal

Guide the AI agent and developer through **drafting a new release** in the project backlog.
This includes creating the initial release directory structure under `docs-project/backlog/`,
copying the standard templates from `docs-dev/guides/prepare-release/`, and breaking the
user-provided release scope into actionable tasks.

## Prerequisites

* Developer has gathered raw release scope notes (features, bug-fixes, refactoring ideas, etc.).
* The current project version is known or can be discovered from the project’s version file.
* Familiarity with the task writing standards and template structure (see
  [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md)).

## Process Steps

1. **Load Context**
   * Read this instruction file and all referenced guides:
     * [Prepare Release Templates](docs-dev/guides/prepare-release/README.md)
     * Language-specific sub-guides in `docs-dev/guides/prepare-release/` as needed.

2. **Gather Release Metadata**
   * Ask the user for:
     * Desired specific semantic version (e.g., `v.0.1.0`, `v.1.2.3`). This must include the patch version.
     * Release codename (derive from user input if not explicitly given).
     * Raw scope notes (bullet list, document paths, or free-form text).

3. **Create Release Directory and Overview File**
   * Create the target release directory using the specific semantic version:
     `docs-project/backlog/v.X.Y.Z-codename/` (e.g., `docs-project/backlog/v.0.3.0-new-feature/`).
   * Create standard sub-directories within the new release directory (e.g., `tasks/`, `docs/`, `decisions/`,
     `codemods/`, `reflections/`, `researches/`, `test-cases/`, `user-experience/`) mirroring the structure found
     in `docs-dev/guides/prepare-release/v.x.x.x/`. Do **not** copy the `_template.md` files into these
     subdirectories at this stage.
   * Copy the main release overview template file from `docs-dev/guides/prepare-release/v.x.x.x/v.x.x.x-codename.md`
     to `docs-project/backlog/v.X.Y.Z-codename/v.x.x.x-codename.md`.
   * Rename the newly copied overview file in the target directory to `v.X.Y.Z-codename.md` (matching the
     directory's version and codename).

4. **Populate Overview Document**
   * Open the new overview file and fill in:
     * Release title, goals, and **Collected Notes** section containing the raw user input.
     * Initial high-level implementation plan (checkbox list) to be refined later.

5. **Break Down Scope Into Tasks**
   * Use the [Breakdown Notes into Tasks Workflow](docs-dev/workflow-instructions/breakdown-notes-into-tasks.md)
     if the raw notes are lengthy or unstructured.
   * For each distinct item in the (possibly refined) user input:
     1. Select the appropriate template family (`tasks`, `decisions`, `docs`, etc.).
     2. Create a new file in the appropriate subdirectory of `docs-project/backlog/v.X.Y.Z-codename/`
        (e.g., `tasks/`, `docs/`) by copying the corresponding `_template.md` from
        `docs-dev/guides/prepare-release/v.x.x.x/[template-family]/_template.md`.
     3. Replace placeholder fields:
        * `id`: Use `bin/tnid v.X.Y.Z` (where `v.X.Y.Z` is the specific version of the current release being
          prepared) to generate the next task ID in the format `v.X.Y.Z+task.<sequential_number>`.
        * `status`: `pending`
        * Title and content derived from the user note.
     4. In the original user note (file or pasted text), append a comment with the created task id for
        traceability.

6. **Ensure Completeness**
   * Verify that **every sentence or bullet** from the user input maps to at least one task file. Highlight any
     ambiguous or under-specified note in the chat and request clarification.

7. **Prepare Commit Message (Do NOT Execute)**
   * Output the following command **verbatim** for the user's convenience, ensuring `v.X.Y.Z` is the specific
     version:

     ```bash
     "chore(backlog): scaffold release v.X.Y.Z-codename – initial structure and tasks"
     ```

   * Do **not** run the command automatically.

8. **Review With User**
   * List all newly created files and their ids.
   * Ask the user to confirm or adjust:
     * Version and codename
     * Any task titles or descriptions that are unclear.
   * Iterate until the user is satisfied.

## Input

* Semantic version and codename (may be requested interactively).
* Raw release scope notes (features, fixes, refactors, docs, etc.).

## Output / Success Criteria

* [ ] A new directory `docs-project/backlog/v.X.Y.Z-codename/` exists (where `v.X.Y.Z` is the specific version).
* [ ] Standard sub-directories (e.g., `tasks/`, `docs/`) and the root overview document are in place within the
      new release directory.
* [ ] All user notes have corresponding task/ADR/doc files with unique ids in the format `v.X.Y.Z+task.N`.
* [ ] Git commit message is displayed in chat ready.
* [ ] User has confirmed that tasks are sufficiently concrete or provided clarifications.

## Reference Documentation

* [Prepare Release Templates](docs-dev/guides/prepare-release/README.md)
* [Breakdown Notes into Tasks Workflow](docs-dev/workflow-instructions/breakdown-notes-into-tasks.md)
* [Write Actionable Task Guide](docs-dev/guides/write-actionable-task.md)
* [Project Management Guide](docs-dev/guides/project-management.md)
* [Version Control Guide](docs-dev/guides/version-control.md)

## Usage Example
>
> “Prepare a new release with the notes in `docs-project/backlog/ideas.md`.
> Expected version: `v.0.3.0`, codename: `atlas`.”

---

This workflow focuses on **drafting** a release in the backlog.
