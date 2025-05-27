# Release Process Guide

## Goal

This guide details the standard process for preparing, validating, tagging, and publishing project releases, ensuring consistency and quality control. It covers versioning, Git workflow, checklists, and post-release activities.

## Standard: Release Documentation Naming

To ensure consistency and predictability, all release-specific documentation directories (typically managed under `docs-project/current/` during development and archived to `docs-project/done/`) **must** contain a root documentation file named according to the following convention:

**`v.x.y.z-codename.md`**

- **`v.x.y.z`**: Matches the semantic version of the release (e.g., `v.0.2.3`).
- **`codename`**: A short (ideally 1-4 words), descriptive name for the release, usually reflecting its primary goal or theme (e.g., `feedback-after-zed-extension`). If no specific codename is assigned, use a concise description.
- **`.md`**: The file extension.

**Example:** For a release version `0.2.3` with the codename `feedback-after-zed-extension`, the root file within its directory (`docs-project/current/v.0.2.3-feedback-after-zed-extension/`) must be named `v.0.2.3-feedback-after-zed-extension.md`.

This convention applies to the main overview document for the release. Other files and subdirectories within the release directory can follow project-specific structures.

### 1. Version Control

1. **Semantic Versioning**:
   Maintain the project's version number according to Semantic Versioning (MAJOR.MINOR.PATCH) in a designated location (e.g., a dedicated version file, `package.json`, build script, etc.).

   ```plaintext
   // Example: path/to/version/file or relevant package manifest
   const VERSION = "1.2.3"; // Or similar declaration
   // MAJOR: Breaking changes
   // MINOR: New features, backwards compatible
   // PATCH: Bug fixes, backwards compatible
   ```

2. **Git Workflow for Releases**:
   The project typically follows a Pull Request (PR) based workflow for contributions.
   - **From a Feature Branch:** If release preparations (version bumping, changelog updates) are done on a feature branch or a dedicated release preparation branch, these changes should be integrated into the main branch (e.g., `main` or `master`) via a Pull Request. Once merged, the release (tagging and publishing) is performed from the main branch.
   - **Directly on Main Branch:** For smaller releases or hotfixes, versioning, tagging, and publishing might occur directly on the main branch.
   The key is that the main branch reflects the state of all releases. For detailed procedural steps for creating tags, commits, and handling branches, refer to the [`ship-release.md` workflow instruction](../workflow-instructions/ship-release.md) and the [Version Control Guide](./version-control.md). Project architecture documents may further specify contribution models, especially for external contributions (e.g., from forks).

### 2. Release Process

1. **Pre-Release Considerations**:
   Before initiating a release, it's crucial to have a pre-release checklist. This typically includes verifying that version files and the `CHANGELOG.md` are ready for updates, all release-specific documentation (e.g., in `docs-project/current/{release_dir}/`) is finalized and correctly named (e.g., `v.x.y.z-codename.md`), and all planned features/fixes are merged and tested.
   The actionable pre-release checklist is detailed in the [`ship-release.md` workflow instruction](../workflow-instructions/ship-release.md).

2. **Version Update Concepts**:
   Updating the version involves incrementing the semantic version number in all designated project files (like `package.json`, `Cargo.toml`, or custom version files) and detailing the changes in the `CHANGELOG.md`. The `CHANGELOG.md` should clearly list additions, fixes, and other changes for the new version.
   The [`ship-release.md` workflow instruction](../workflow-instructions/ship-release.md) provides steps for performing these updates.

3. **Tagging and Publishing Concepts**:
   After version updates are committed, an annotated Git tag is created to mark the specific release point in history. Subsequently, the updated code and the new tag are pushed to the remote repository. The final step is publishing the package to the relevant registry (e.g., npm, RubyGems, crates.io). This often requires appropriate credentials.
   For detailed commands and language-specific instructions, consult the [`ship-release.md` workflow instruction](../workflow-instructions/ship-release.md) and the language-specific guides in the [`./ship-release/`](./ship-release/) subdirectory.

### 3. Post-Release

1. **Monitoring**:
   Monitor the application/library's performance and error rates after release using configured monitoring tools (e.g., application performance monitoring (APM) systems, error tracking services).

   ```plaintext
   // Example conceptual monitoring integration
   monitoringTool.trackEvent(
     'deployment.success',
     {
       version: 'v1.2.0',
       environment: getEnvironmentName()
     }
   );
   ```

2. **Communication**:
   Announce the release to users and stakeholders through appropriate channels (e.g., release notes page, blog post, email, Slack/Discord).
   Include highlights, key changes, and installation/update instructions.

   ```markdown
   ## Release Announcement

   Version vX.Y.Z is now available!

   ### Highlights
   - Feature A description
   - Performance improvement B
   - Bug fix C

   ### Installation / Update
   Information on how to install or update to the new version is typically provided, often linking to package manager instructions or language-specific guides.

## Language/Environment-Specific Examples

For specific commands, scripts, or configurations related to building, tagging, and publishing packages in different ecosystems (e.g., npm, RubyGems, PyPI, Maven, Cargo), please refer to the examples in the [./ship-release/](./ship-release/) sub-directory.

## Related Documentation

- [Project Management Guide](docs-dev/guides/project-management.md) (Task flow, versioning)
- [Documentation Standards Guide](docs-dev/guides/documentation.md)
- [Version Control Guide](docs-dev/guides/version-control.md) (Tagging, Commit Messages)
- Relevant Workflow Instructions: [`docs-dev/workflow-instructions/ship-release.md`](../workflow-instructions/ship-release.md) (this guide\'s actionable counterpart), [`docs-dev/workflow-instructions/prepare-release.md`](../workflow-instructions/prepare-release.md), [`docs-dev/workflow-instructions/create-api-docs.md`](../workflow-instructions/create-api-docs.md), `docs-dev/workflow-instructions/review-tasks-board-status.md`

## Reference Templates

- Release checklist items are often included in the main release overview template (`docs-dev/guides/prepare-release/v.x.x.x/v.x.x.x-codename.md`).

## Automation with Helper Scripts

Helper scripts (e.g., `scripts/publish.sh`, `scripts/release.sh`) can be highly beneficial for automating repetitive parts of the release process, such as building, testing, tagging, and publishing. This can reduce manual error and improve consistency. The [`ship-release.md` workflow instruction](../workflow-instructions/ship-release.md) may reference or incorporate such scripts if they exist in the project.

3. **Issue Tracking**:

   ```markdown
   ## vX.Y.Z Issue Template

   ### Environment
   - Version:
   - OS:

   ### Expected Behavior

   ### Actual Behavior

   ### Steps to Reproduce
   ```
