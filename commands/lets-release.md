# Let's Release Command

This command guides the process of finalizing and publishing a new release.

## Essential Reading

First review these key documents:
- [Release Guide](../guides/ship-release.md)
- [Project Management](../guides/project-management.md) (for versioning and task flow)
- [Version Control](../guides/version-control.md) (for tagging)
- [Documentation Guide](../guides/documentation.md)

## Process Steps

1.  **Confirm Task Completion**:
    *   Use [`review-kanban-board`](./review-kanban-board.md) to check the status of tasks in the `docs-dev/project/current/{release_dir}/tasks/` directory and in `docs-dev/project/current/{release_dir}/README.md`.
    *   Ensure all tasks intended for this release have `status: done` and checkboxes are marked as complete `[x]` in their `.md` files.

2.  **Review Changes**:
    *   Review commits since the last release (`git log <last_tag>..HEAD`).
    *   Identify the scope of changes (bug fixes, features, breaking changes) to determine the correct version bump (Patch, Minor, Major) according to Semantic Versioning.
    *   Check the current project version (location depends on project, e.g., `VERSION` file, `lib/.../version.rb`, `package.json`). Refer to `docs-dev/project/blueprint.md` if unsure.

3.  **Prepare Release Documentation**:
    *   Update `CHANGELOG.md` with a new section for this release, summarizing changes based on commits and completed tasks.
    *   Finalize any release-specific documentation within the `docs-dev/project/current/{release_dir}/` subdirectories (e.g., `docs/`, `user-experience/`). Refer to `guides/ship-release.md` for guidance on required artifacts based on release type.
    *   Generate or update API documentation if the public API has changed.

4.  **Version Update**:
    *   Determine the new version number (e.g., v1.2.3 -> v1.3.0 for a minor release).
    *   Update the version in the designated project file(s) (e.g., `VERSION` file, `lib/.../version.rb`, `package.json`, `.gemspec`). Refer to `blueprint.md`.
    *   Commit these version changes: `git commit -am "chore(release): Bump version to vX.Y.Z"`

5.  **Release Validation**:
    *   Run the full test suite (e.g., `bundle exec rspec`).
    *   Run linters/static analysis (e.g., `bundle exec standardrb`).
    *   Perform manual checks or smoke tests for key functionality if applicable.
    *   Review the final `CHANGELOG.md` entry for accuracy and clarity.
    *   Ensure all changes (including version bump and CHANGELOG) are committed.

6.  **Archive Release Directory**:
    *   Move the release directory from `docs-dev/project/current/` to `docs-dev/project/done/`: `mv docs-dev/project/current/{release_dir} docs-dev/project/done/`
    *   Commit the project state change: `git add docs-dev/project/ && git commit -m "chore(project): Archive release vX.Y.Z"`

7.  **Create Release**:
    *   Create an annotated Git tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
    *   Push the commit and tag: `git push origin <main_branch> && git push origin vX.Y.Z` (adjust branch name if needed).
    *   Build, verify, and publish the gem using the helper script:
        ```bash
        bin/publish
        ```
        *(Note: This script handles `gem build`, basic verification, and `gem push`. Ensure you have push access and RubyGems credentials configured.)*

8.  **Post-Release**:
    *   Announce the release (optional).
    *   Monitor for any immediate issues post-release.

## Reference Documentation

- [Release Process](../guides/ship-release.md) (Primary Guide)
- [Documentation Standards](../guides/documentation.md)
- [Version Control](../guides/version-control.md)
- [Project Blueprint](../project/blueprint.md) (For project-specific file locations)

## Success Criteria

1.  **Tasks Completed**: All tasks for the release in `project/current/` are marked `done`.
2.  **Documentation Complete**:
    *   `CHANGELOG.md` updated accurately.
    *   Required release documentation finalized.
    *   API documentation (if changed) is current.
3.  **Quality Checks Passed**:
    *   All tests passing.
    *   Linters pass.
    *   Version updated correctly in designated file(s).
4.  **Project State Updated**: Release directory moved from `current/` to `done/` and change committed.
5.  **Release Artifacts Created**:
    *   Git tag created and pushed.
    *   Release artifact built and published successfully.
