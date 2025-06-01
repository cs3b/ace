# Ship Release Workflow Instruction

**Goal:** To provide a step-by-step checklist for consistently executing project releases, including versioning,
tagging, building (if applicable), publishing, and post-release activities. This workflow ensures all necessary
actions are taken for a successful release.

**Prerequisites:**

* The [`load-env`](./load-env.md) workflow instruction has been run to load project context.
* The [`prepare-release`](./prepare-release.md) workflow (or equivalent process) has been completed, meaning all
  features, fixes, and documentation for the release are finalized and ready.
* You have the necessary permissions to push to the repository, create tags, and publish to package registries.
* Familiarity with the project's Git workflow (typically a Pull Request-based strategy for contributions to the
  main branch) as outlined in [`docs-dev/guides/version-control.md`](../guides/version-control.md).
* The main conceptual guide [`docs-dev/guides/ship-release.md`](../guides/ship-release.md) has been reviewed for
  understanding the overall process.

## Process Steps

### 1. Preparation & Pre-flight Checks

1. **Verify Current Branch:** Ensure you are on the main development branch (e.g., `main`, `master`) or a
   release preparation branch intended for this release.
   * _Guidance: Consult [`docs-dev/guides/version-control.md`](../guides/version-control.md) for your project's branching strategy._

2. **Pull Latest Changes:** Fetch and integrate the latest changes from the remote repository.
   * `git pull origin <current_branch_name>`

3. **Run Tests & Linters:** Execute all automated tests and code linters to ensure the codebase is stable and
   meets quality standards. Address any failures before proceeding.
   * _Refer to language-specific testing commands in [`docs-dev/guides/ship-release/`](../guides/ship-release/)
     (e.g., `rust.md`, `ruby.md`, `typescript.md`)._

4. **Verify Task Completion:** Ensure all project management tasks, issues, or tickets slated for this release
   are completed and properly tracked (e.g., marked as "done" in your task tracking system).

5. **Confirm Feature Completion:** Verify that all features, bug fixes, and improvements planned for this
   release are fully implemented and tested.

6. **Verify Release Documentation:** Check that all release-specific documentation artifacts (e.g., ADRs,
   guides, task files) are accurate and up-to-date.
      detailed design docs, test case summaries, user experience notes) within the
      `docs-project/current/{release_dir}/` directory (where `{release_dir}` is the specific directory for the
      current release, e.g., `v.0.3.0-new-feature-release`) are complete, reviewed, and accurate according to the
      release scope.
7. **Critical: Validate Root Release Document Name:** Ensure the main documentation file for this release,
   located in `docs-project/current/{release_dir}/`, is correctly named `v.x.y.z-codename.md` (e.g.,
   `v.0.3.0-new-feature-release.md`).
   * _Refer to naming standard:
     [`docs-dev/guides/ship-release.md#standard-release-documentation-naming`](../guides/ship-release.md#standard-release-documentation-naming)._

### 2. Version Bumping

8. **Determine New Version:** Decide on the new semantic version (MAJOR.MINOR.PATCH) based on the changes
   included in the release.
   * Example: `v1.2.3`
   * _User Input: New version number: \_\_\_\_\_\_\_\_\_\_ (e.g., `v.0.2.4` or `1.3.0`)_

9. **Update Version in Project Files:** Modify all designated files where the project version is stored.
   * _Refer to [`docs-dev/guides/ship-release.md#2-version-update`](../guides/ship-release.md#2-version-update) and
     language-specific guides in [`docs-dev/guides/ship-release/`](../guides/ship-release/) for typical file
     locations._

10. **Update CHANGELOG.md:** Add a new entry to the `CHANGELOG.md` file (usually at the project root) detailing
    the changes in this release. If `CHANGELOG.md` does not exist, create it, typically starting with a header
    for this first release. Follow existing format and conventions (e.g., Keep a Changelog) if the file already
    exists.
    * _Refer to [`docs-dev/guides/ship-release.md#2-version-update`](../guides/ship-release.md#2-version-update) for
      CHANGELOG best practices._

### 3. Committing Version Changes

11. **Stage Changes:** Add the updated version files and `CHANGELOG.md` to the Git staging area.
    * `git add <path_to_version_file_1> <path_to_version_file_2> ... CHANGELOG.md`

12. **Commit Changes:** Commit the staged files with a standardized commit message.
    * Example: `git commit -m "chore(release): Prepare release vX.Y.Z"` (replace `vX.Y.Z` with the new version)
    * Or: `git commit -m "chore: Bump version to vX.Y.Z"`

### 4. Tagging the Release

13. **Create Git Tag:** Create an annotated Git tag for the new version.
    * `git tag -a vX.Y.Z -m "Release version X.Y.Z"` (replace `vX.Y.Z` with the new version, ensuring 'v' prefix
    consistency if used)
  * _Note: Some tooling, like `npm version`, may create tags automatically. Consult language-specific guides in
    [`docs-dev/guides/ship-release/`](../guides/ship-release/)._

### 5. Building (If Applicable)

14. **Execute Build Process:** If your project requires a compilation or build step before publishing (e.g.,
    TypeScript to JavaScript, Rust compilation, Ruby gem build):
    * Run the necessary build command(s).
    * _Refer to language-specific build commands in [`docs-dev/guides/ship-release/`](../guides/ship-release/)._

15. **Commit Build Artifacts (If Necessary):** If build artifacts are intended to be part of the repository (less
    common for libraries, more common for web apps), commit them.

### 6. Pushing to Remote Repository

16. **Push Commits:** Push the release commit(s) to the current branch (e.g., `main`, `master`, or your release
    preparation branch).
    * `git push origin <current_branch_name>`

17. **Push Tags:** Push the newly created Git tag to the remote repository.
    * `git push origin vX.Y.Z` (replace `vX.Y.Z` with the new version)
    * Or push all tags: `git push origin --tags`
  * _Alternatively, `git push origin --tags` or for some workflows
    `git push origin <current_branch_name> --follow-tags`._

### 7. Publishing the Package/Library

18. **Authenticate (If Required):** Ensure you are authenticated with the target package registry (e.g., npm,
    crates.io, RubyGems).
    * _Refer to language-specific authentication instructions in
      [`docs-dev/guides/ship-release/`](../guides/ship-release/) and official documentation for your package
      manager._

19. **Execute Publish Command:** Publish the package using the language/ecosystem-specific command.
    * _Refer to specific publishing instructions in [`docs-dev/guides/ship-release/`](../guides/ship-release/)._

20. **Verify Publication:** Confirm that the new version of the package is available on the registry's website.

### 8. Post-Release Activities

21. **Finalize Integration (If Applicable):**
    * If changes were made on a dedicated release preparation branch (not `main`/`master`):
      * Ensure all changes from the release preparation branch are present on the main branch (e.g., `main`,
        `master`). This is typically done by merging a Pull Request from the release branch into the main branch
        _before_ tagging and publishing from the main branch.
      * Alternatively, if tagging and publishing were done from the release branch itself, create and merge a
        Pull Request from the release branch into the main branch (`main`, `master`) to integrate the release
        changes.
      * Optionally, delete the release preparation branch locally and remotely after successful integration:
        * `git branch -d <release_prep_branch>`
        * `git push origin --delete <release_prep_branch>`
    * _Guidance: The exact steps depend on whether the release (tagging/publishing) was performed directly on the
      main branch or on a temporary release branch that now needs to be integrated. Consult
      [`docs-dev/guides/version-control.md`](../guides/version-control.md) and project architecture documents for
      specific PR and integration strategies._

22. **Announce Release:** Communicate the new release to users and stakeholders (e.g., update release notes page,
    blog post, team channels).
    * _Refer to communication strategies in
      [`docs-dev/guides/ship-release.md#communication`](../guides/ship-release.md#communication)._

23. **Monitor:** Begin monitoring the application/library for any unexpected issues or increased error rates
    following the release.
    * _This step helps catch any release-related regressions early._

24. **Archive Release Documentation:** Move the completed release-specific documentation directory from
    `docs-project/current/` to `docs-project/completed/` to reflect the successful release.
      `docs-project/current/` to `docs-project/done/`.
  * Example: `mv docs-project/current/vX.Y.Z-codename docs-project/done/`
  * _This signifies the release's active development documentation phase is complete._

## Reference Documentation

* **Primary Conceptual Guide:** [`docs-dev/guides/ship-release.md`](../guides/ship-release.md)
* **Language-Specific Instructions:**
  * [`docs-dev/guides/ship-release/rust.md`](../guides/ship-release/rust.md)
  * [`docs-dev/guides/ship-release/ruby.md`](../guides/ship-release/ruby.md)
  * [`docs-dev/guides/ship-release/typescript.md`](../guides/ship-release/typescript.md)
* **Version Control Strategy:** [`docs-dev/guides/version-control.md`](../guides/version-control.md)
* **Release Content Preparation:** [`docs-dev/workflow-instructions/prepare-release.md`](./prepare-release.md)
* **Troubleshooting Tests:** [`docs-dev/workflow-instructions/fix-tests.md`](./fix-tests.md)
* **Project Management (Versioning Context):**
  [`docs-dev/guides/project-management.md`](../guides/project-management.md)
