---
update:
  update_frequency: on-change
  frequency: on-change
  last-updated: '2026-01-28'
---

# ACE Update Changelog Workflow

## Goal

Update the main project CHANGELOG.md with new entries, automatically determining version from the current release and incrementing the patch level.

## Prerequisites

* Main CHANGELOG.md exists at project root
* Active release in ace-taskflow
* Changes to document (new features, fixes, updates)

## Project Context Loading

* Read and follow: `ace-bundle project`
* Load: Keep a Changelog format specification

## Process Steps

### 1. Determine Version Number

Get current release:
```bash
ace-release | grep "Release:" | awk '{print $2}'
# Example output: v.0.9.0
```

Extract major.minor (remove 'v.' prefix and last '.0'):
```bash
# From v.0.9.0 → 0.9
VERSION_BASE=$(ace-release | grep "Release:" | awk '{print $2}' | sed 's/v\.//' | sed 's/\.[0-9]*$//')
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

### 2. Audit Commits Since Last Entry

Get the commit hash of the last changelog entry:
```bash
# Find the commit that added the last changelog version
LAST_VERSION=$(grep -E "^## \[[0-9]+\.[0-9]+\.[0-9]+\]" CHANGELOG.md | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
git log --all --oneline --grep="$LAST_VERSION" -- CHANGELOG.md | head -1
```

List all commits since then:
```bash
git log <last-changelog-commit>..HEAD --pretty=format:"%h %s" --no-merges
```

Identify all scopes touched:
```bash
git diff --stat <last-changelog-commit>..HEAD | grep -oE '^[^/]+/' | sort -u
```

### 2a. Classify Each Commit

Review every commit and assign exactly one category using this decision tree:

| Question | If Yes → Category |
|----------|-------------------|
| Did it fix something that was broken/crashing? | **Fixed** |
| Did it add net-new capability that didn't exist before? | **Added** |
| Did it remove a feature or capability? | **Removed** |
| Did it change how existing functionality works? | **Changed** |
| Is it non-functional (docs, tests, chores, refactoring)? | **Technical** |

**Classification rules:**
- A rename that fixes a crash is **Fixed**, not Changed
- A new method that supports a new input format is **Added**
- Updating docs/examples to match code changes is **Changed** (or omit if trivial)
- Config registrations that fix broken discovery are **Fixed**
- New skill files are **Added**

### 2b. Verify Scope Coverage

Before drafting the entry, confirm:
- [ ] Every commit from the audit is represented in at least one entry
- [ ] All scopes from `git diff --stat` are accounted for
- [ ] No bug fixes are listed under Added
- [ ] No new features are listed under Fixed
- [ ] Entries include package version references where applicable (e.g., `**ace-foo v1.2.3**:`)

### 3. Generate Changelog Entry

Create entry with format:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Fixed
- Bug fix or crash correction

### Added
- New feature description

### Removed
- Removed feature or capability

### Changed
- Change description

### Technical
- Maintenance changes
```

**Date format:** Use current date in ISO format (YYYY-MM-DD)

**Skip empty sections:** Only include sections with actual changes

### 3a. Verify Entry Completeness

Before inserting, cross-check the draft:

1. **Commit coverage**: Re-read the commit list from step 2. Confirm each commit maps to an entry.
2. **Category accuracy**: For each entry, re-ask: "Is this really [Fixed/Added/Changed]?"
3. **Scope coverage**: Check the scope list from step 2b. Is every scope mentioned?
4. **Version references**: Each package-level change should include `**package vX.Y.Z**:` prefix.
5. **No empty categories**: Only include sections that have entries.

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

- **Fixed:** Bug fixes, crash fixes, broken behavior corrections
- **Added:** New features, new files, new capabilities, new tools
- **Removed:** Removed features, deleted capabilities, deprecated items
- **Changed:** Modifications to existing functionality, renames, restructuring
- **Technical:** Chores, dependency updates, refactoring, test improvements, doc-only changes

## Troubleshooting

**One-liner solutions:**

- `cannot find current release` → ensure active release exists with `ace-release`
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

### Fixed
- Bug fix or crash correction

### Added
- Feature or capability that was added

### Removed
- Feature or capability that was removed

### Changed
- Modification to existing functionality

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
> "/as-release-update-changelog"

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
> "/as-release-update-changelog Added ace-lint integration for markdown linting"

Current release: v.0.9.0
Last version: 0.9.1
New version: 0.9.2

Category: Added
- ace-lint integration for markdown linting

[Generates entry and commits]
```

### Example 3: Multiple Categories

```
> "/as-release-update-changelog"

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
* For package-specific changelogs, use `/as-release-bump-version [package]`
* Version always follows current release: v.0.9.0 → 0.9.X
* When release changes (e.g., v.0.10.0), version resets to 0.10.1
* Patch level increments for **any** change (no semantic versioning rules)
* Changes are documented immediately, no batching required
* Follow Keep a Changelog format for consistency
* **This workflow does NOT commit changes** - use `/as-release` for complete release with commit
