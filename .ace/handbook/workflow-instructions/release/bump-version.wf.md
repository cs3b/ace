---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-12-16'
---

# ACE Bump Version Workflow

## Goal

Perform automated semantic version bumping for a single ACE gem package by analyzing committed changes (or using explicit bump level), updating version files and changelog.

## Prerequisites

* Clean git working directory (all changes committed)
* Target package with `lib/ace/[name]/version.rb` and `CHANGELOG.md`
* Understanding of conventional commits and semantic versioning

## Project Context Loading

* Read and follow: `ace-bundle project`
* Load: Keep a Changelog and Semantic Versioning 2.0.0 specifications

## Process Steps

### 1. Identify Package

List available packages:
```bash
ls -d ace-*/ | sed 's#/##'
```

Validate structure:
```bash
# Check required files exist
[ -f "ace-[package]/lib/ace/[package]/version.rb" ] && echo "✓ version.rb"
[ -f "ace-[package]/CHANGELOG.md" ] && echo "✓ CHANGELOG.md"
```

### 2. Gather Committed Changes

Extract current version:
```bash
grep VERSION ace-[package]/lib/ace/[package]/version.rb
# Example output: VERSION = "0.11.3"
```

Get last changelog date:
```bash
grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" ace-[package]/CHANGELOG.md | head -1
# Example output: ## [0.11.3] - 2025-10-14
```

Collect commits since last release:
```bash
# Using date from changelog
git log --since="YYYY-MM-DD" --pretty=format:"%h %s" -- ace-[package]/

# Or using git tag
git log $(git tag -l "ace-[package]-v*" --sort=-version:refname | head -1)..HEAD \
  --pretty=format:"%h %s" -- ace-[package]/
```

### 3. Determine Version Bump

**If explicit bump level provided (patch|minor|major):**
- Skip automatic analysis
- Use the provided bump level directly
- Still show commits for context in changelog

**Otherwise, analyze commit types:**
- `BREAKING CHANGE:` in body → **MAJOR** bump
- `feat:` or `feat(scope):` → **MINOR** bump
- `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `perf:` → **PATCH** bump

**Bump priority:** BREAKING > feat > everything else

**Calculate new version:**
- MAJOR bump: `1.2.3` → `2.0.0` (reset MINOR and PATCH)
- MINOR bump: `1.2.3` → `1.3.0` (reset PATCH)
- PATCH bump: `1.2.3` → `1.2.4`

**Present to user:**
```
Package: ace-[package]
Current: X.Y.Z
Commits: N changes
Type: [MAJOR|MINOR|PATCH] (explicit|auto-detected)
New Version: X.Y.Z
```

### 4. Update Version File

Replace version string:
```bash
# Update lib/ace/[package]/version.rb
sed -i '' 's/VERSION = "OLD_VERSION"/VERSION = "NEW_VERSION"/' \
  ace-[package]/lib/ace/[package]/version.rb

# Verify syntax
ruby -c ace-[package]/lib/ace/[package]/version.rb
```

### 5. Update Gemfile.lock

After updating version.rb, run bundle to update the lockfile:
```bash
bundle install
```

This ensures Gemfile.lock reflects the new version for mono-repo workspace dependencies.

### 5.1 Check Dependent Gemspec Constraints (MINOR/MAJOR bumps only)

When the bump is MINOR or MAJOR, the new version may exceed `~>` constraints in other packages.

**Skip this step for PATCH bumps** — `~>` constraints allow patch-level variation by design.

```bash
# Find all gemspecs that depend on this package
grep -rl "\"ace-[package]\"" ace-*/as-*.gemspec
```

For each match, check if the constraint still covers the new version:
- `~> 0.10` allows `0.10.x` but rejects `0.11.0`
- After a MINOR bump: `"~> 0.10"` → `"~> 0.11"` (bump the minor, drop the patch)
- After a MAJOR bump: `"~> 0.x"` → `"~> 1.0"` (bump the major)

For each stale constraint:
1. Update the gemspec constraint to match the new MINOR (or MAJOR)
2. Run `bundle install` in that dependent package directory
3. Include the updated gemspecs and lockfiles in the same release commit

### 6. Update Changelog

**Categorize commits by type:**
- `feat:` → **Added**
- `fix:` → **Fixed**
- `refactor:` → **Changed**
- `docs:`, `chore:`, `test:`, `perf:` → **Technical**

**Generate entry:**
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Feature description (from feat: commits)

### Fixed
- Bug fix description (from fix: commits)

### Changed
- Refactoring description (from refactor: commits)

### Technical
- Maintenance changes (from chore:, docs:, test: commits)
```

**Insert after [Unreleased] section** in `CHANGELOG.md`

**Format commit messages:**
- Remove type prefix: `feat(api): add auth` → `add auth`
- Capitalize first letter
- Add bullet point

## Semantic Versioning Rules

### Bump Decision Matrix

| Commit Type | Changelog Category | Bump Type |
|-------------|-------------------|-----------|
| `BREAKING CHANGE:` | Any | **MAJOR** |
| `feat:` | Added | **MINOR** |
| `fix:` | Fixed | **PATCH** |
| `refactor:` | Changed | **PATCH** |
| `docs:` | Technical | **PATCH** |
| `chore:` | Technical | **PATCH** |
| `test:` | Technical | **PATCH** |
| `perf:` | Changed/Technical | **PATCH** |

### Version Format

`MAJOR.MINOR.PATCH` where:
- **MAJOR**: Breaking API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes and minor changes, backward compatible

## Troubleshooting

**One-liner solutions:**

- `git status shows uncommitted changes` → commit or stash changes before version bump
- `version.rb not found` → check package name and standard ACE structure
- `CHANGELOG.md missing` → create new changelog including all package changes from git history
- `cannot parse version from version.rb` → ensure format matches `VERSION = "X.Y.Z"`
- `no commits since last release` → wait for commits or skip bump
- `cannot determine bump type` → ambiguous commits, manually specify patch/minor
- `changelog format invalid` → restructure to Keep a Changelog format (see template)
- `ace-git-commit fails` → check git hooks or commit manually: `git commit -m "..."`
- `wrong files staged` → `git reset`, then explicitly add version.rb, CHANGELOG.md, and Gemfile.lock
- `Gemfile.lock shows uncommitted changes after bump` → expected in mono-repos; workflow now includes Gemfile.lock in commit (see Step 6)

## Embedded Templates

### Version File Format

```ruby
# frozen_string_literal: true

module Ace
  module PackageName
    VERSION = "X.Y.Z"
  end
end
```

### Changelog Entry Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Fixed
- Bug fix description

### Changed
- Change in existing functionality

### Technical
- Chore, docs, test, or performance changes
```

### Initial Changelog Template

```markdown
# Changelog

All notable changes to ace-[package] will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD

### Added
- Initial release
```

## Usage Examples

### Example 1: Auto-detected Patch Bump

```
> "Bump version for ace-taskflow"
> or: /as-release-bump-version ace-taskflow

Package: ace-taskflow
Current: 0.11.3
Commits: 3 (fix, docs, chore)
Type: PATCH (auto-detected)
New Version: 0.11.4

[Updates files and commits]
```

### Example 2: Explicit Minor Bump

```
> "/as-release-bump-version ace-core minor"

Package: ace-core
Current: 0.9.3
Commits: 5 (2 feat, 2 fix, 1 test)
Type: MINOR (explicit)
New Version: 0.10.0

[Updates files and commits]
```

### Example 3: Explicit Major Bump

```
> "/as-release-bump-version ace-lint major"

Package: ace-lint
Current: 0.2.0
Commits: 2 (breaking changes)
Type: MAJOR (explicit)
New Version: 1.0.0

[Updates files and commits]
```

### Example 4: New Changelog

```
> "Bump ace-search version"

Package: ace-search
Error: CHANGELOG.md missing

[Creates new CHANGELOG.md with all git history]
[Proceeds with version bump to 0.9.1]
```

## Notes

* This workflow handles **single package** version bumping only
* For multi-package coordinated releases, use `publish-release` workflow
* Only committed changes are analyzed - uncommitted work is ignored
* BREAKING CHANGE must appear in commit body for MAJOR bump detection
* **Explicit bump level** (patch|minor|major) overrides automatic detection
* Use explicit bump when you want to force a specific version change regardless of commits
* **Mono-repo lockfile management**: In workspace setups, `Gemfile.lock` at project root is updated when package versions change
* **This workflow does NOT commit changes** - use `/as-release` for complete release with commit
