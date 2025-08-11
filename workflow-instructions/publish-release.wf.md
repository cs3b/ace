# Publish Release Workflow Instruction

## Goal

Execute the final deployment and archival phase of project releases, transitioning from active development to published state. This workflow handles version finalization, documentation archival, release validation, and post-release activities.

## Prerequisites

- All features, documentation, and initial release preparations are finalized
- All planned tasks for the release are completed (`status: done`) or explicitly deferred with documented rationale
- You have necessary permissions to modify project documentation structure and create final release artifacts
- Git repository access with push permissions
- Package registry credentials (if applicable)

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`
- Load tools documentation: `docs/tools.md`
- Load current release status: `dev-taskflow/current/*/`
- Check roadmap for release details: `dev-taskflow/roadmap.md`
- Verify changelog exists: `CHANGELOG.md`

## High-Level Execution Plan

### Planning Phase

- [ ] Validate release readiness and all tasks complete
- [ ] Determine final version number from release folder
- [ ] Review quality checks and test results

### Execution Phase

- [ ] Update version numbers across all project files
- [ ] Generate and update changelog
- [ ] Create Git tag and push changes
- [ ] Publish package to registry (if applicable)
- [ ] Archive release documentation
- [ ] Update roadmap to remove completed release
- [ ] Communicate release completion

## Process Steps

### 1. Pre-Publish Validation

1. **Verify Release Readiness:**
   - Confirm all tasks in the current release are marked as `done` or have documented deferral decisions
   - Validate that all acceptance criteria for included features are met
   - Check that any breaking changes are properly documented with migration guides

2. **Determine Final Version Number:**
   - Extract `<major>.<minor>` from the current release folder name
   - Use format `v<major>.<minor>.0` for initial release publication
   - Example: Folder `v.0.3.0-feedback-after-meta.v.0.2` → Version `v0.3.0`
   - _User Input: Confirm final version number: ____________ (e.g., `v0.3.0`)_

3. **Validate Build Process:**
   - Execute `bin/build` to ensure project integrity
   - Verify build completes successfully (or gracefully handles no-op for documentation-only projects)
   - Address any build failures before proceeding

4. **Run Final Quality Checks:**
   - Execute all tests: `# Run project-specific test command`
   - Run code quality checks: `# Run project-specific lint command`
   - Verify no critical issues remain unresolved

### 2. Version Finalization

5. **Update Version Numbers:**
   - Update all project files containing version numbers (e.g., `package.json`, `Cargo.toml`, `VERSION` files)
   - Ensure version consistency across all relevant files
   - Common version file locations:
     - `package.json` (Node.js)
     - `Cargo.toml` (Rust)
     - `setup.py` or `pyproject.toml` (Python)
     - `Gemfile` or `*.gemspec` (Ruby)
     - `VERSION` or `version.txt` files

6. **Generate Final Changelog:**
   - Create or update `CHANGELOG.md` at project root
   - Move entries from `[Unreleased]` section to new version section
   - Add release date: `## [X.Y.Z] - YYYY-MM-DD`
   - Include comparison links at bottom of file
   - Follow the changelog template:

7. **Validate Documentation Consistency:**
   - Verify release documentation file follows naming convention: `v.x.y.z-codename.md`
   - Check that all internal references and links are accurate
   - Confirm documentation reflects actual implemented features

### 3. Release Artifact Creation

8. **Commit Version Updates:**
   - Stage all version-related changes with enhanced validation: `git-add <version_files> CHANGELOG.md`
   - Commit with guided message generation: `git-commit --guided -m "chore(release): prepare v<X.Y.Z> publication"`
   - Example: `git-commit --guided -m "chore(release): prepare v0.3.0 publication"`

9. **Create Release Tag:**
   - Create annotated Git tag with enhanced validation: `git tag -a v<X.Y.Z> -m "Release v<X.Y.Z> <codename>"`
   - Example: `git tag -a v0.3.0 -m "Release v0.3.0 feedback-after-meta"`
   - Verify tag creation: `git tag -l v<X.Y.Z>`

10. **Push Release Changes:**
    - Push commits with safety checks: `git-push --safe origin <current_branch>`
    - Push tags with validation: `git-push --safe origin v<X.Y.Z>` or `git-push --safe origin --tags`

### 4. Package Publication (If Applicable)

11. **Authenticate with Package Registry:**
    - Ensure authentication with relevant package registries (npm, PyPI, RubyGems, etc.)
    - Verify credentials are current and have appropriate permissions
    - Common authentication methods:
      - npm: `npm login` or use `.npmrc` with auth token
      - PyPI: `pip install twine` and use `.pypirc`
      - RubyGems: `gem signin` or use API key
      - Cargo: `cargo login` with token

12. **Execute Package Publication:**
    - Run language-specific publish command
    - Monitor publication process for errors or warnings
    - Common publish commands:
      - npm: `npm publish`
      - PyPI: `twine upload dist/*`
      - RubyGems: `gem push *.gem`
      - Cargo: `cargo publish`

13. **Verify Package Availability:**
    - Confirm package appears on registry website
    - Test installation/download of published package
    - Verify package metadata (version, description, dependencies) is correct

### 5. Documentation Archival

14. **Archive Release Documentation:**
    - Create archive directory: `mkdir -p dev-taskflow/done/`
    - Move current release documentation: `mv dev-taskflow/current/* dev-taskflow/done/v<X.Y.Z>-<codename>/`
    - Example: `mv dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2 dev-taskflow/done/`
    - Verify move completed successfully and `dev-taskflow/current/` is empty

15. **Update Roadmap (Remove Completed Release):**
    - Remove the completed release from roadmap's "Planned Major Releases" table
    - Update cross-release dependencies that reference the completed release
    - Update roadmap's `last_reviewed` date and add entry to Update History
    - Follow roadmap update process:
      - Locate the completed release in "Planned Major Releases" table
      - Remove the entire row for the completed release
      - Update any cross-release dependencies
      - Update `last_reviewed` date at top of file
      - Add entry to "Update History" section
    - Commit roadmap changes with message format:

      ```bash
      "docs(roadmap): remove completed v<X.Y.Z>-<codename> from planned releases"
      ```

16. **Commit Documentation Archival:**
    - Stage archival changes: `git add dev-taskflow/done/v<X.Y.Z>-<codename>/ dev-taskflow/current/`
    - Commit archival: `git commit -m "chore(release): archive v<X.Y.Z>-<codename> documentation"`
    - Example: `git commit -m "chore(release): archive v0.3.0-feedback-after-meta documentation"`

17. **Push Archival Changes:**
    - Push archival commit: `git push origin <current_branch>`

### 6. Release Communication

18. **Prepare Release Announcement:**
    - Draft release announcement highlighting key changes
    - Include installation/update instructions
    - Reference changelog for detailed change information
    - Prepare announcements for relevant channels (internal teams, users, community)

19. **Execute Release Communication:**
    - Publish release announcement through appropriate channels
    - Update project documentation or website if applicable
    - Notify stakeholders and team members
    - Share release notes with user community

### 7. Post-Release Monitoring

20. **Initialize Release Monitoring:**
    - Set up monitoring for error rates and performance metrics
    - Establish alerting for critical issues
    - Begin collecting user feedback on the release

21. **Verify Release Success:**
    - Confirm all release steps completed successfully
    - Validate that published artifacts are accessible and functional
    - Check that documentation archival preserved all necessary information

22. **Update Project Status:**
    - Mark release as `published` in project tracking systems
    - Update roadmaps and planning documents to reflect completed release
    - Begin planning for next release cycle if applicable

### 8. Final Validation and Cleanup

23. **Conduct Release Retrospective:**
    - Document lessons learned from the release process
    - Identify process improvements for future releases
    - Update workflow instructions based on experience

24. **Prepare for Next Development Cycle:**
    - Create new release directory structure if next release is planned
    - Update development environment for next version
    - Communicate next development priorities to team

## Validation Points

### Critical Success Criteria

Before proceeding to the next step, verify:

- [ ] All quality checks pass (tests, linting, build)
- [ ] Version numbers are consistent across all files
- [ ] Changelog accurately reflects release changes
- [ ] Git tags are created and pushed successfully
- Package publication completes without errors (if applicable)
- Documentation archival preserves all release artifacts
- Roadmap updated to remove completed release and maintain accuracy
- Release communication reaches intended audiences

### Rollback Triggers

Stop the process and consider rollback if:

- Critical test failures are discovered
- Package publication fails repeatedly
- Security vulnerabilities are identified
- Major functionality regressions are reported
- Stakeholder approval is withdrawn

## Error Handling

### Common Issues and Resolutions

1. **Build Failures:**
   - Review build logs for specific errors
   - Verify all dependencies are available
   - Check for environment-specific issues
   - For test-related issues:
     - Review test output for specific failures
     - Check for environment-specific test dependencies
     - Verify test database/fixtures are properly configured
     - Consider running tests in isolation to identify conflicts

2. **Version Conflicts:**
   - Check for existing tags with same version number
   - Verify version number format matches project standards
   - Update version files consistently

3. **Publication Errors:**
   - Verify authentication credentials
   - Check package registry status and availability
   - Review package configuration for errors

4. **Documentation Issues:**
   - Ensure proper file permissions for archival operations
   - Verify Git repository status before major moves
   - Backup critical documentation before archival

## Package Registry Commands Reference

### npm (Node.js)

```bash
# Login
npm login

# Publish
npm publish

# Publish with specific tag
npm publish --tag beta

# Check published version
npm view <package-name> version
```

### PyPI (Python)

```bash
# Install publishing tools
pip install build twine

# Build distribution
python -m build

# Upload to PyPI
twine upload dist/*

# Upload to TestPyPI first
twine upload --repository testpypi dist/*
```

### RubyGems (Ruby)

```bash
# Build gem
gem build *.gemspec

# Push to RubyGems
gem push *.gem

# Check published version
gem list -r <gem-name>
```

### Cargo (Rust)

```bash
# Login with token
cargo login <token>

# Publish
cargo publish

# Dry run
cargo publish --dry-run
```

## Success Criteria

The publish release workflow is complete when:

- All version numbers are finalized and consistent
- Package is successfully published to appropriate registries
- Release documentation is archived in `dev-taskflow/done/`
- Git repository contains proper tags and commit history
- Stakeholders are notified of release completion
- Post-release monitoring is active
- Project status reflects published state

<documents>
    <template path="dev-handbook/templates/release-management/changelog.template.md"># Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD

### Added

- New features

### Changed

- Changes in existing functionality

### Deprecated

- Soon-to-be removed features

### Removed

- Removed features

### Fixed

- Bug fixes

### Security

- Vulnerability fixes
</template>

</documents>
