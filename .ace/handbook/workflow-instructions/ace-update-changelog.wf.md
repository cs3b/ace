---
update:
  update_frequency: on-change
  frequency: on-change
  last-updated: '2025-10-14'
---

# ACE Update Changelog Workflow

## Goal

Update the main project CHANGELOG.md with new entries, automatically determining version from the current release and incrementing the patch level.

## Prerequisites

* Main CHANGELOG.md exists at project root
* Active release in ace-taskflow
* Changes to document (new features, fixes, updates)

## Project Context Loading

* Read and follow: `dev-handbook/workflow-instructions/load-project-context.wf.md`
* Load: Keep a Changelog format specification

## Process Steps

### 1. Determine Version Number

Get current release:
```bash
ace-taskflow release | grep "Release:" | awk '{print $2}'
# Example output: v.0.9.0
```

Extract major.minor (remove 'v.' prefix and last '.0'):
```bash
# From v.0.9.0 → 0.9
VERSION_BASE=$(ace-taskflow release | grep "Release:" | awk '{print $2}' | sed 's/v\.//' | sed 's/\.[0-9]*$//')
echo "Version base: $VERSION_BASE"
```

Get last changelog version:
```bash
grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" CHANGELOG.md | head -1
# Example output: ## [0.12.0] - 2025-10-14
```

Calculate new version:
- Use `$VERSION_BASE` for MAJOR.MINOR
- Increment PATCH from last entry: `0.9.0` → `0.9.1`
- Or start at `0.9.1` if this is first entry for this release

### 2. Gather Changes

**Interactive mode:**
Ask user to describe changes in categories:
- **Added:** New features or capabilities
- **Changed:** Changes in existing functionality
- **Fixed:** Bug fixes
- **Technical:** Chores, docs, refactoring

**Argument mode:**
Parse provided description and categorize automatically.

### 3. Generate Changelog Entry

Create entry with format:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Change description

### Fixed
- Bug fix description

### Technical
- Maintenance changes
```

**Date format:** Use current date in ISO format (YYYY-MM-DD)

**Skip empty sections:** Only include sections with actual changes

### 4. Update CHANGELOG.md

Insert new entry after `## [Unreleased]` section:

```bash
# Find line number of [Unreleased]
LINE=$(grep -n "## \[Unreleased\]" CHANGELOG.md | cut -d: -f1)

# Insert new entry after that line (with blank line separator)
# Use Edit tool or sed
```

Verify format:
```bash
# Check entry was added correctly
grep -A 5 "## \[$NEW_VERSION\]" CHANGELOG.md
```

### 5. Commit Changes

Use ace-git-commit:
```bash
ace-git-commit CHANGELOG.md -m "docs: update CHANGELOG to version X.Y.Z"
```

Verify:
```bash
git log -1 --stat
```

## Versioning Rules

### Version Calculation

| Current Release | Last CHANGELOG | New Version | Rule |
|----------------|----------------|-------------|------|
| v.0.9.0 | 0.12.0 | 0.9.1 | Reset to release base, start at .1 |
| v.0.9.0 | 0.9.1 | 0.9.2 | Increment patch |
| v.0.9.0 | 0.9.5 | 0.9.6 | Increment patch |
| v.0.10.0 | 0.9.10 | 0.10.1 | New release, reset to .1 |

**Key principle:** Version always follows `{release_major}.{release_minor}.{auto_patch}`

### Change Categories

- **Added:** New features, new documentation sections, new tools
- **Changed:** Modifications to existing functionality, restructuring
- **Fixed:** Bug fixes, error corrections, broken link fixes
- **Technical:** Chores, dependency updates, refactoring, test improvements

## Troubleshooting

**One-liner solutions:**

- `cannot find current release` → ensure active release exists with `ace-taskflow release`
- `CHANGELOG.md not found` → check you're in project root directory
- `version extraction fails` → verify CHANGELOG follows Keep a Changelog format
- `duplicate version in changelog` → check if version was already added, adjust patch number
- `cannot parse version base` → ensure release follows v.X.Y.Z format
- `ace-git-commit fails` → check git hooks or commit manually: `git commit -m "..."`
- `wrong date format` → use ISO 8601 format: YYYY-MM-DD
- `entry in wrong position` → should be after [Unreleased], before previous version

## Embedded Templates

### Changelog Entry Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- Feature or capability that was added

### Changed
- Modification to existing functionality

### Fixed
- Bug fix or correction

### Technical
- Maintenance, refactoring, or infrastructure changes
```

### Unreleased Section Format

```markdown
## [Unreleased]

<!-- New entries will be added below this line -->

## [X.Y.Z] - YYYY-MM-DD
```

## Usage Examples

### Example 1: Interactive Update

```
> "/ace-update-changelog"

Current release: v.0.9.0
Last version: 0.12.0
New version: 0.9.1

What was added?
> ace-lint integration for markdown files

What was changed?
> workflow structure simplified

What was fixed?
> broken links in documentation

Technical changes?
> test coverage improvements

[Generates entry and commits]
```

### Example 2: Direct Description

```
> "/ace-update-changelog Added ace-lint integration for markdown linting"

Current release: v.0.9.0
Last version: 0.9.1
New version: 0.9.2

Category: Added
- ace-lint integration for markdown linting

[Generates entry and commits]
```

### Example 3: Multiple Categories

```
> "/ace-update-changelog"

[Provide multiple items across categories]

Result:
## [0.9.3] - 2025-10-14

### Added
- New workflow for changelog management
- Claude command integration

### Changed
- Simplified workflow structure

### Fixed
- Documentation links corrected

[Creates commit: "docs: update CHANGELOG to version 0.9.3"]
```

## Notes

* This workflow updates **main project CHANGELOG** only (not package CHANGELOGs)
* For package-specific changelogs, use `/ace-bump-version [package]`
* Version always follows current release: v.0.9.0 → 0.9.X
* When release changes (e.g., v.0.10.0), version resets to 0.10.1
* Patch level increments for **any** change (no semantic versioning rules)
* Changes are documented immediately, no batching required
* Follow Keep a Changelog format for consistency
* Commit does NOT auto-push - review before pushing
