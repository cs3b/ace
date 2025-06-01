# Changelog Writing Guide

## Goal

This guide provides standards and best practices for writing and maintaining changelogs that effectively communicate project changes to users, contributors, and stakeholders. It ensures consistency, clarity, and usefulness of release documentation.

## Changelog Format

We follow the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format with project-specific adaptations. All changelogs should be written in Markdown and stored in `CHANGELOG.md` at the project root.

### Standard Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features that have been added

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Now removed features

### Fixed
- Any bug fixes

### Security
- In case of vulnerabilities

## [1.0.0] - 2024-01-15

### Added
- Initial release with core functionality
- Basic API endpoints
- User authentication system

[Unreleased]: https://github.com/user/repo/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

## Change Categories

Use the following categories to organize changes:

### Added

- New features
- New API endpoints
- New configuration options
- New documentation sections
- New dependencies

**Example:**

```markdown
### Added
- Dark mode toggle in user preferences
- Support for bulk operations in API
- Integration with external authentication providers
```

### Changed

- Changes in existing functionality
- Updated dependencies
- Modified default behaviors
- Improved performance
- Enhanced user interface

**Example:**

```markdown
### Changed
- Improved loading performance by 40%
- Updated user interface for better accessibility
- Changed default timeout from 30s to 60s
```

### Deprecated

- Features that are still available but will be removed
- API endpoints marked for removal
- Configuration options being phased out

**Example:**

```markdown
### Deprecated
- Legacy authentication API (use v2 endpoints instead)
- Configuration option `old_setting` (replaced by `new_setting`)
```

### Removed

- Features that have been completely removed
- Deleted API endpoints
- Removed configuration options
- Dropped support for versions/platforms

**Example:**

```markdown
### Removed
- Support for Node.js v14 (minimum version is now v16)
- Deprecated `/api/v1/legacy` endpoints
```

### Fixed

- Bug fixes
- Security patches
- Performance improvements that fix issues
- Documentation corrections

**Example:**

```markdown
### Fixed
- Memory leak in background processing
- Incorrect validation error messages
- Race condition in concurrent requests
```

### Security

- Security vulnerability fixes
- Security enhancements
- Important security-related changes

**Example:**

```markdown
### Security
- Fixed XSS vulnerability in user input handling
- Enhanced password encryption algorithm
- Updated dependencies to address security advisories
```

## Writing Guidelines

### 1. Use Clear, Action-Oriented Language

**Good:**

- "Added user authentication system"
- "Fixed memory leak in data processing"
- "Improved API response time by 25%"

**Avoid:**

- "Some changes to auth"
- "Fixed stuff"
- "Performance improvements"

### 2. Include Context and Impact

**Good:**

```markdown
### Changed
- Updated password requirements to include special characters for enhanced security
- Increased default session timeout from 30 minutes to 2 hours based on user feedback
```

**Avoid:**

```markdown
### Changed
- Password validation
- Session timeout
```

### 3. Reference Issues and Pull Requests

When applicable, link to relevant issues, pull requests, or task documentation:

```markdown
### Fixed
- Resolved database connection timeout issue ([#123](https://github.com/user/repo/issues/123))
- Fixed user profile update validation ([PR #145](https://github.com/user/repo/pull/145))
- Corrected task workflow documentation inconsistencies (Task v.0.3.0+task.14)
```

### 4. Group Related Changes

```markdown
### Added
- User management dashboard with the following features:
  - Create and edit user accounts
  - Assign roles and permissions
  - View user activity logs
  - Export user data
```

### 5. Use Consistent Formatting

- Start each item with a capital letter
- Use present tense ("Add" not "Added")
- End with a period for complete sentences
- Use bullet points for lists
- Maintain consistent indentation

## Process Guidelines

### When to Update the Changelog

1. **During Development:**
   - Add entries to the `[Unreleased]` section as features are completed
   - Update immediately after merging significant changes
   - Include changelog updates in the same commit/PR as the feature

2. **Before Release:**
   - Review all `[Unreleased]` entries for accuracy and completeness
   - Move entries from `[Unreleased]` to the new version section
   - Add release date and version links
   - Ensure all significant changes are documented

3. **After Release:**
   - Verify the changelog accurately reflects the released version
   - Start a new `[Unreleased]` section for future changes

### Who Is Responsible

- **Developers:** Add changelog entries for their own changes
- **Release Manager:** Review and finalize changelog before release
- **Project Lead:** Ensure changelog standards are followed

### Integration with Release Process

The changelog should be updated as part of the standard release workflow:

1. **During Development:** Maintain `[Unreleased]` section
2. **Pre-Release:** Review and organize entries
3. **Version Bump:** Move entries to versioned section
4. **Release:** Publish changelog with release notes
5. **Post-Release:** Verify accuracy and completeness

## Version Linking

Include comparison links at the bottom of the changelog:

```markdown
[Unreleased]: https://github.com/user/repo/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/user/repo/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/user/repo/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/user/repo/releases/tag/v1.0.0
```

For projects without public repositories, use internal tracking systems or omit links if not applicable.

## Common Mistakes to Avoid

1. **Overly Technical Language:** Write for users, not just developers
2. **Missing Context:** Explain why changes were made when relevant
3. **Inconsistent Categories:** Use the standard categories consistently
4. **Burying Important Changes:** Put breaking changes and security fixes prominently
5. **Incomplete Information:** Include all user-facing changes
6. **Late Updates:** Don't wait until release to update the changelog

## Examples

### Good Changelog Entry

```markdown
## [2.1.0] - 2024-03-15

### Added
- Real-time notifications for task updates with configurable preferences
- Bulk task operations (mark complete, assign, delete) in project dashboard
- Export functionality for project reports in CSV and PDF formats
- Integration with external calendar systems (Google Calendar, Outlook)

### Changed
- Improved task loading performance by implementing pagination (loads 50% faster)
- Enhanced user interface with improved accessibility features and keyboard navigation
- Updated email templates for better mobile responsiveness

### Fixed
- Resolved issue where task assignments were not triggering notifications ([#234](link))
- Fixed memory leak in real-time update system that occurred during long sessions
- Corrected timezone handling in deadline calculations for international teams

### Security
- Updated authentication library to address potential session fixation vulnerability
- Enhanced input validation to prevent XSS attacks in task descriptions
```

### Poor Changelog Entry

```markdown
## [2.1.0] - 2024-03-15

### Added
- Notifications
- Bulk operations
- Export stuff

### Changed
- Performance improvements
- UI updates

### Fixed
- Various bugs
- Memory issues
```

## Related Documentation

- [Version Control Guide](./version-control.md) (Commit message standards)
- [Project Management Guide](./project-management.md) (Release workflow integration)
- [Publish Release Guide](./publish-release.md) (Release process overview)
- [Publish Release Workflow](../workflow-instructions/publish-release.md) (Step-by-step release actions)
- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) (External reference)
- [Semantic Versioning](https://semver.org/) (Versioning standards)
