# Release Process Guide

## Goal
This guide details the standard process for preparing, validating, tagging, and publishing project releases, ensuring consistency and quality control. It covers versioning, Git workflow, checklists, and post-release activities.

# Release Process Guide

### 1. Version Control

1. **Semantic Versioning**:
   ```ruby
   # lib/aira/version.rb
   module Aira
     VERSION = "1.2.3"  # MAJOR.MINOR.PATCH
     # MAJOR: Breaking changes
     # MINOR: New features, backwards compatible
     # PATCH: Bug fixes, backwards compatible
   end
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
   ```

2. **Version Update**:
   ```ruby
   # Update version file (e.g., lib/aira/version.rb)
   VERSION = "1.2.0"

   # Update gemspec (if applicable)
   s.version = Aira::VERSION

   # Update CHANGELOG.md (root level)
   ## [1.2.0] - 2024-01-20

   ### Added
   - New browser tool implementation
   - Enhanced error handling

   ### Fixed
   - Thread safety in tool registry
   - Memory leak in long-running tasks
   ```

3. **Tagging and Publishing**:
   ```bash
   # Ensure all changes are committed, including version bump and CHANGELOG

   # Create annotated git tag
   git tag -a vX.Y.Z -m "Release version X.Y.Z"
   git push origin vX.Y.Z # Push the tag

   # Publish the gem using the helper script (located at root)
   # This script builds, verifies, and pushes to RubyGems.org
   bin/publish
   ```
   *Note: Ensure you have push access and RubyGems credentials configured (`~/.gem/credentials`) before running `bin/publish`.*

### 3. Post-Release

1. **Monitoring**:
   ```ruby
   # Example monitoring setup
   require 'appsignal'

   AppSignal.monitor_transaction(
     'gem.release',
     'v1.2.0',
     environment: ENV['RACK_ENV']
   )
   ```

2. **Communication**:
   ```markdown
   ## Release Announcement

   Aira v1.2.0 is now available!

   ### Highlights
   - New browser tool
   - Improved performance
   - Better error handling

   ### Installation
   ```bash
   gem install aidarb
   ```

## Related Documentation
- [Project Management Guide](docs-dev/guides/project-management.md) (Task flow, versioning)
- [Documentation Standards Guide](docs-dev/guides/documentation.md)
- [Version Control Guide](docs-dev/guides/version-control.md) (Tagging, Commit Messages)
- [Writing Guides Guide](docs-dev/guides/writing-guides-guide.md)
- Relevant Workflow Instructions: `docs-dev/workflow-instructions/lets-release.md`, `docs-dev/workflow-instructions/docs/generate-api-docs.md`, `docs-dev/workflow-instructions/review-kanban-board.md`

## Reference Templates
- Release checklist items are often included in the main release overview template (`docs-dev/guides/prepare-release/v.x.x.x/v.x.x.x-codename.md`).

## Helper Scripts
- `bin/publish` (Assumed script for building and publishing the artifact, located at project root)

3. **Issue Tracking**:
   ```markdown
   ## v1.2.0 Issue Template

   ### Environment
   - Ruby version:
   - Aira version:
   - OS:

   ### Expected Behavior

   ### Actual Behavior

   ### Steps to Reproduce
   ```
