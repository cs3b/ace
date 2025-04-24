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

2. **Git Flow Model**:
   ```bash
   # Feature development
   git checkout -b feature/new-tool develop
   git commit -m "feat: Add new browser tool"
   git push origin feature/new-tool

   # Release preparation
   git checkout -b release/1.2.0 develop
   git commit -m "chore: Bump version to 1.2.0"
   git tag -a v1.2.0 -m "Release version 1.2.0"
   ```

### 2. Release Process

1. **Pre-Release Checklist**:
   ```markdown
   ## Release Checklist

   ### Required
   - [ ] Version file updated
   - [ ] CHANGELOG.md updated
   - Finalize any release-specific documentation within the `docs-project/current/{release_dir}/` subdirectories (e.g., `docs/`, `user-experience/`). The specific artifacts required (like ADRs, detailed docs, test cases, user guides) should align with the scope defined during the specification phase (using `docs-dev/workflow-instructions/lets-spec-from-pr-comments.md`, `docs-dev/workflow-instructions/lets-spec-from-frd.md`, or `docs-dev/workflow-instructions/lets-spec-from-prd.md` workflow instructions) which corresponds to the release type (Patch, Feature, Major). Ensure all necessary documents are complete and accurate.
   - [ ] **Ensure the root documentation file within the release directory (`docs-project/current/{release_dir}/`) is named according to the standard `v.x.y.z-codename.md` (matching the directory name).**
   ```

2. **Version Update**:
   Increment the version number in the designated version file(s) and any relevant package manifests.
   Update the `CHANGELOG.md` (typically at the project root) with details for the new version.
   ```plaintext
   // Example: path/to/version/file
   VERSION = "1.2.0";

   // Example: package.json
   "version": "1.2.0",

   // Example: CHANGELOG.md (root level)
   ## [1.2.0] - YYYY-MM-DD

   ### Added
   - Description of new feature A
   - Description of new feature B

   ### Fixed
   - Description of bug fix C
   - Description of bug fix D
   ```

3. **Tagging and Publishing**:
   Ensure all changes, including the version bump and `CHANGELOG.md` update, are committed to version control.
   Create an annotated Git tag for the release version.
   Push the commit(s) and the tag to the remote repository.
   Publish the package to the relevant registry using standard commands or helper scripts for your ecosystem.
   ```bash
   # Ensure all changes are committed
   git commit -am "chore: Prepare release vX.Y.Z"

   # Create annotated git tag
   git tag -a vX.Y.Z -m "Release version X.Y.Z"

   # Push commits and tag
   git push origin <branch_name> # e.g., main or develop
   git push origin vX.Y.Z

   # Publish the package using appropriate ecosystem commands
   # (See language-specific examples)
   # Or run a custom publish script: ./scripts/publish.sh
   ```
   *Note: Ensure you have the necessary credentials and permissions configured for the target package registry.*

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
   ```bash
   # Example installation commands using appropriate package manager
   # (See language-specific examples)
   ```

## Language/Environment-Specific Examples

For specific commands, scripts, or configurations related to building, tagging, and publishing packages in different ecosystems (e.g., npm, RubyGems, PyPI, Maven, Cargo), please refer to the examples in the [./ship-release/](./ship-release/) sub-directory.

## Related Documentation
- [Project Management Guide](docs-dev/guides/project-management.md) (Task flow, versioning)
- [Documentation Standards Guide](docs-dev/guides/documentation.md)
- [Version Control Guide](docs-dev/guides/version-control.md) (Tagging, Commit Messages)
- [Writing Guides Guide](docs-dev/guides/writing-guides-guide.md)
- Relevant Workflow Instructions: `docs-dev/workflow-instructions/lets-release.md`, `docs-dev/workflow-instructions/docs/generate-api-docs.md`, `docs-dev/workflow-instructions/review-kanban-board.md`

## Reference Templates
- Release checklist items are often included in the main release overview template (`docs-dev/guides/prepare-release/v.x.x.x/v.x.x.x-codename.md`).

## Helper Scripts
- Consider using helper scripts (e.g., `scripts/publish.sh`, `scripts/release.sh`) to automate parts of the release process like building, testing, tagging, and publishing.

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
