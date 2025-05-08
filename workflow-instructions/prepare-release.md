# Prepare Release Workflow Instruction

## Goal
Guide the developer through the process of finalizing, validating, tagging, and publishing a new project release based on the work completed in the `docs-project/current/` directory.

## Prerequisites
- All tasks intended for the release in `docs-project/current/{release_dir}/tasks/` have `status: done`.
- Code changes associated with the release are merged into the main branch.
- Developer has necessary permissions to push tags and publish releases (e.g., to RubyGems, npm).
- Familiarity with the project's release process, versioning, and documentation standards.

## Process Steps

1.  **Confirm Task Completion & Readiness:**
    *   Run `docs-dev/workflow-instructions/review-kanban-board.md` to verify all tasks in `docs-project/current/{release_dir}/tasks/` are `done`.
    *   Ensure the main branch is up-to-date and all related code PRs are merged.

2.  **Review Changes & Determine Version:**
    *   Review changes since the last release tag (e.g., `git log <last_tag>..HEAD`).
    *   Determine the correct semantic version bump (Patch, Minor, Major).
    *   Identify the current version from the project's version file. (See [Project Blueprint](docs-project/blueprint.md) for file location).

3.  **Prepare Release Documentation:**
    *   Update `CHANGELOG.md` (at project root) with a new entry summarizing changes for the determined version.
    *   Finalize any release-specific documentation in `docs-project/current/{release_dir}/`. (See [Release Process Guide](docs-dev/guides/ship-release.md) for details on required documents).
    *   Ensure the root documentation file within the release directory uses the standard `v.x.y.z-codename.md` naming convention matching the directory name. (See [Release Process Guide](docs-dev/guides/ship-release.md)).

4.  **Update Version & Commit:**
    *   Update the version number in the designated project file(s).
    *   Commit the version bump and documentation changes (e.g., `git commit -am "chore(release): Bump version to vX.Y.Z"`).

5.  **Final Validation:**
    *   Run the full test suite (using your project's standard test command, e.g., `your_test_runner_command`. See `docs-dev/guides/testing/<your_lang>.md` or `docs-dev/guides/task-cycle/<your_lang>.md` for details).
    *   Run linters/static analysis.
    *   Perform any required manual smoke tests.
    *   Review the `CHANGELOG.md` entry for accuracy.

6.  **Archive Release & Commit State:**
    *   Move the completed release directory from `docs-project/current/` to `docs-project/done/`:
        ```bash
        mv docs-project/current/{release_dir} docs-project/done/
        ```
    *   Commit the archiving of the release documentation:
        ```bash
        git add docs-project/
        git commit -m "chore(project): Archive release vX.Y.Z docs"
        ```

7.  **Tag and Push:**
    *   Create an annotated Git tag:
        ```bash
        git tag -a vX.Y.Z -m "Release version X.Y.Z"
        ```
    *   Push the main branch commits and the new tag:
        ```bash
        git push origin <main_branch>
        git push origin vX.Y.Z
        ```

8.  **Publish Release Artifact:**
    *   Build and publish the package using project-specific commands or scripts. (See [Release Process Guide](docs-dev/guides/ship-release.md) and language-specific sub-guides for details).

9.  **Post-Release Actions:**
    *   Announce the release (optional).
    *   Monitor for any immediate issues.

## Input
- Confirmation that all tasks are done and code is merged.
- Determined version number.

## Output / Success Criteria
- [ ] All tasks for the release in `docs-project/current/{release_dir}/` confirmed `done`.
- [ ] `CHANGELOG.md` and other required release documentation updated.
- [ ] The root documentation file within the release directory uses the standard `v.x.y.z-codename.md` naming convention.
- [ ] Project version file updated and committed.
- [ ] Final validation checks (tests, linters) pass.
- [ ] Release documentation directory moved from `docs-project/current/` to `docs-project/done/` and committed.
- [ ] Annotated Git tag created and pushed successfully.
- [ ] Release artifact (e.g., gem, package) built and published successfully.

## Reference Documentation
- [Release Process Guide](docs-dev/guides/ship-release.md) (Primary Guide)
- [Project Management Guide](docs-dev/guides/project-management.md) (Task flow, versioning)
- [Version Control Guide](docs-dev/guides/version-control.md) (Tagging, commit messages)
- [Documentation Standards Guide](docs-dev/guides/documentation.md)
- [Project Blueprint](docs-project/blueprint.md) (For project-specific file locations)
- Workflow Instructions: `docs-dev/workflow-instructions/review-kanban-board.md`, `docs-dev/workflow-instructions/create-api-docs.md`
