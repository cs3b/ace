# ADR-020: Semantic Versioning and CHANGELOG Requirements

## Status
Accepted
Date: October 14, 2025

## Context

With 15+ gems in the mono-repo, version management and change tracking became critical. Early gems had inconsistent practices:
- Some lacked CHANGELOG.md
- Version bumps were arbitrary
- Change history was unclear
- Users couldn't track what changed between versions
- No standard format for release notes

This created confusion for users and made maintenance difficult.

## Decision

All ace-* gems **must**:
1. Follow Semantic Versioning (semver)
2. Maintain CHANGELOG.md in Keep a Changelog format
3. Include VERSION constant in lib/ace/gem/version.rb
4. Update both files with every release

### Semantic Versioning Rules

**MAJOR.MINOR.PATCH** format:

**MAJOR** (Breaking changes):
- Configuration format changes
- API changes incompatible with previous versions
- Removed features or commands
- Changed command-line interface

**MINOR** (New features):
- New commands or features (backward compatible)
- New configuration options (with defaults)
- Enhanced functionality
- New dependencies

**PATCH** (Bug fixes):
- Bug fixes only
- Documentation updates
- Internal refactoring (no API changes)
- Performance improvements

### CHANGELOG.md Format

**Required** in every gem root:

```markdown
# Changelog

All notable changes to ace-gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-10-14

### Added
- New feature X for improved workflow
- Configuration option Y

### Changed
- Updated behavior of command Z

### Fixed
- Bug in parser that caused crashes
- Incorrect exit codes

### Deprecated
- Old config format (use new format instead)

## [0.1.0] - 2025-10-01

### Added
- Initial release
- Core functionality
- Basic CLI commands
```

### Section Order

1. **[Unreleased]**: Upcoming changes not yet released
2. **[Version] - Date**: Released versions (newest first)
3. **Subsections** (in order):
   - Added (new features)
   - Changed (changes to existing features)
   - Deprecated (soon-to-be removed features)
   - Removed (removed features)
   - Fixed (bug fixes)
   - Security (security fixes)

### Version File

```ruby
# lib/ace/gem/version.rb
# frozen_string_literal: true

module Ace
  module Gem
    VERSION = "0.1.0"
  end
end
```

### Gemspec Integration

```ruby
# ace-gem.gemspec
require_relative "lib/ace/gem/version"

Gem::Specification.new do |spec|
  spec.name = "ace-gem"
  spec.version = Ace::Gem::VERSION
  # ...
end
```

### Requirements

**DO:**
- ✅ Maintain CHANGELOG.md in gem root
- ✅ Use Keep a Changelog format
- ✅ Follow semantic versioning strictly
- ✅ Update CHANGELOG with every change
- ✅ Include version.rb file
- ✅ Link to semver and Keep a Changelog docs
- ✅ Date releases as YYYY-MM-DD

**DON'T:**
- ❌ Skip CHANGELOG updates
- ❌ Make breaking changes in MINOR versions
- ❌ Use arbitrary version numbers
- ❌ Leave [Unreleased] section empty
- ❌ Forget to move [Unreleased] to version on release

## Consequences

### Positive

- **Clear History**: Users understand what changed
- **Predictable Upgrades**: semver signals breaking changes
- **Better Planning**: Deprecations announced in advance
- **Documentation**: CHANGELOG serves as release notes
- **Consistency**: All gems follow same pattern
- **Automation Friendly**: Standard format enables tooling

### Negative

- **Maintenance Overhead**: Must update CHANGELOG with every change
- **Discipline Required**: Must follow semver rules strictly
- **Migration**: Requires backfilling CHANGELOGs for existing gems

### Neutral

- **Version Coordination**: Related gems may need synchronized versions
- **Deprecation Cycle**: Need to plan removals across versions

## Examples from Production

### ace-lint (Well-Maintained)

```markdown
# Changelog

## [0.3.0] - 2025-10-13

### Changed
- **BREAKING**: Configuration moved to .ace/lint/kramdown.yml
- Now uses ace-core config cascade

### Added
- Kramdown configuration support
- Multi-tool config pattern

### Fixed
- Config loading with proper cascade

## [0.2.0] - 2025-10-13
...
```

### ace-task (Comprehensive)

```markdown
# Changelog

## [0.11.4] - 2025-10-14

### Added
- Support for pending release directory
- Markdown style checks

### Fixed
- 17 atom test failures
- Directory names now configurable

### Changed
- Consolidated retro directory
- Standardized directory names
```

## Version Bump Process

1. **Decide version type**: MAJOR, MINOR, or PATCH
2. **Update CHANGELOG.md**:
   - Move [Unreleased] items to new [X.Y.Z] section
   - Add release date
   - Create empty [Unreleased] section
3. **Update version.rb**: Change VERSION constant
4. **Commit**: `git commit -m "chore: Bump version to X.Y.Z"`
5. **Tag**: `git tag vX.Y.Z`
6. **Push**: `git push && git push --tags`

## Automated Tools Support

Standard format enables automation:

```bash
# Extract version
ruby -r ./lib/ace/gem/version -e "puts Ace::Gem::VERSION"

# Parse CHANGELOG
# Tools can extract release notes for specific version

# Version bump tools
# Can automate version.rb and CHANGELOG updates
```

## Deprecation Policy

**When deprecating features:**

1. **MINOR version**: Add deprecation warning
   ```ruby
   warn "[DEPRECATED] Feature X is deprecated, use Y instead"
   ```
2. **CHANGELOG**: Document in "Deprecated" section
3. **Next MAJOR**: Remove feature, document in "Removed" section

**Minimum deprecation cycle**: 1 MINOR version before removal

## Breaking Change Communication

For MAJOR versions:

1. **CHANGELOG**: Clear "Changed" section explaining breaks
2. **README**: Update with migration guide
3. **Deprecation warnings**: Added in previous MINOR if possible
4. **Documentation**: Update all examples

## Testing

```ruby
# test/version_test.rb
class VersionTest < AceTestCase
  def test_version_format
    assert_match /\A\d+\.\d+\.\d+\z/, Ace::Gem::VERSION
  end

  def test_version_constant_exists
    assert defined?(Ace::Gem::VERSION)
  end
end
```

## Related Decisions

- **ADR-015**: Mono-Repo Migration - provides context for versioning
- **ADR-021**: Standardized Rakefile - release tasks

## References

- **Semantic Versioning**: https://semver.org/
- **Keep a Changelog**: https://keepachangelog.com/
- **ace-lint CHANGELOG**: Example of well-maintained changelog
- **ace-task CHANGELOG**: Example of detailed changelog

---

This ADR establishes semantic versioning and Keep a Changelog format as mandatory practices for all ACE gems, ensuring clear communication of changes and predictable version upgrades.
