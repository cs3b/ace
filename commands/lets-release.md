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
    *   Use [`_review-kanban-board`](./_review-kanban-board.md) to check the status of tasks in the `docs-dev/project/current/{release_dir}/tasks/` directory.
    *   Ensure all tasks intended for this release have `status: done`.

2.  **Review Changes**:
    *   Review commits since the last release (`git log <last_tag>..HEAD`).
    *   Identify the scope of changes (bug fixes, features, breaking changes) to determine the correct version bump (Patch, Minor, Major).
    *   Check the current version in `lib/aira/version.rb`.

3.  **Prepare Release Documentation**:
    *   Update `CHANGELOG.md` with a new section for this release, summarizing changes.
    *   Finalize any release-specific documentation within the `docs-dev/project/current/{release_dir}/` subdirectories (e.g., `docs/`, `user-experience/`). Refer to `guides/ship-release.md` for guidance on required artifacts based on release type (this will eventually replace `prepare-release-documentation.md`).
    *   Generate or update API documentation if necessary.

4.  **Version Update**:
    *   Determine the new version number based on Semantic Versioning.
    *   Update the `VERSION` constant in `lib/aira/version.rb`.
    *   Update the version in the `.gemspec` file.
    *   Commit these version changes: `git commit -am "chore(release): Bump version to vX.Y.Z"`

5.  **Release Validation**:
    *   Run the full test suite: `bundle exec rspec`
    *   Run linters/static analysis: `bundle exec standardrb`
    *   Manually verify key examples or functionality if applicable.
    *   Review the final `CHANGELOG.md` entry for accuracy and clarity.

6.  **Create Release**:
    *   Create an annotated Git tag: `git tag -a vX.Y.Z -m "Release version X.Y.Z"`
    *   Push the commit and tag: `git push origin main && git push origin vX.Y.Z` (adjust branch name if needed)
    *   Build the gem: `gem build *.gemspec`
    *   Publish the gem: `gem push *.gem`

7.  **Post-Release**:
    *   Move the release directory from `docs-dev/project/current/` to `docs-dev/project/done/`: `mv docs-dev/project/current/{release_dir} docs-dev/project/done/`
    *   Announce the release (optional).
    *   Monitor for any immediate issues.

## Reference Documentation

- [Release Process](../guides/ship-release.md) (Primary Guide)
- [Documentation Standards](../guides/documentation.md)
- [Version Control](../guides/version-control.md)

## Success Criteria

1.  **Tasks Completed**: All tasks for the release in `project/current/` are marked `done`.
2.  **Documentation Complete**:
    *   `CHANGELOG.md` updated accurately.
    *   Required release documentation finalized.
    *   API documentation (if changed) is current.
3.  **Quality Checks Passed**:
    *   All tests passing.
    *   Linters pass.
    *   Version updated correctly in `version.rb` and `.gemspec`.
4.  **Release Artifacts Created**:
    *   Git tag created and pushed.
    *   Gem built and published successfully.
5.  **Project State Updated**: Release directory moved from `current/` to `done/`.
5.  **Project State Updated**: Release directory moved from `current/` to `done/`.
