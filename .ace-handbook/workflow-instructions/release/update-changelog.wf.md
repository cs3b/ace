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

### 1. Confirm Target Section

This workflow appends items to the `## [Unreleased]` section in root `CHANGELOG.md`.

Version numbers are assigned later at publish time by `wfi://github/release-publish`.

Verify the `[Unreleased]` section exists:
```bash
grep -n "## \[Unreleased\]" CHANGELOG.md
```

If missing, add it after the file header.

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

### 3. Generate Changelog Items

Prepare items grouped by category (no version header — items will be merged into `[Unreleased]`):

```markdown
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

**Skip empty categories:** Only include categories with actual changes.

### 3a. Verify Entry Completeness

Before inserting, cross-check the draft:

1. **Commit coverage**: Re-read the commit list from step 2. Confirm each commit maps to an entry.
2. **Category accuracy**: For each entry, re-ask: "Is this really [Fixed/Added/Changed]?"
3. **Scope coverage**: Check the scope list from step 2b. Is every scope mentioned?
4. **Version references**: Each package-level change should include `**package vX.Y.Z**:` prefix.
5. **No empty categories**: Only include categories that have entries.

### 4. Merge Into `[Unreleased]` Section

Append the generated items into the existing `## [Unreleased]` section in `CHANGELOG.md`:

* If `[Unreleased]` already has a matching category heading (e.g., `### Fixed`), append bullets to that category.
* If a needed category does not yet exist under `[Unreleased]`, create it in canonical order: Fixed, Added,
  Removed, Changed, Technical.
* Do not duplicate items that already appear from a prior run.

Verify:
```bash
# Confirm items are under [Unreleased]
grep -A 20 "## \[Unreleased\]" CHANGELOG.md
```

## Versioning Rules

Root changelog entries accumulate under `## [Unreleased]` — no version number is assigned here.

Version numbers are minted at publish time by `wfi://github/release-publish`, which assigns the next root patch
version (highest existing `## [X.Y.Z]` patch + 1) when finalizing unreleased content.

### Change Categories

- **Fixed:** Bug fixes, crash fixes, broken behavior corrections
- **Added:** New features, new files, new capabilities, new tools
- **Removed:** Removed features, deleted capabilities, deprecated items
- **Changed:** Modifications to existing functionality, renames, restructuring
- **Technical:** Chores, dependency updates, refactoring, test improvements, doc-only changes

## Troubleshooting

**One-liner solutions:**

- `CHANGELOG.md not found` → check you're in project root directory
- `[Unreleased] section missing` → add `## [Unreleased]` after the file header
- `duplicate items in [Unreleased]` → dedup before appending; check prior `/as-release` runs
- `ace-git-commit fails` → check git hooks or commit manually: `git commit -m "..."`
- `entry in wrong position` → items should be under `[Unreleased]`, before the first versioned entry

## Embedded Templates

### Unreleased Category Template

Items are appended into the `[Unreleased]` section by category:

```markdown
## [Unreleased]

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

## [X.Y.Z] - YYYY-MM-DD
```

## Usage Examples

### Example 1: Interactive Update

```
> "/as-release-update-changelog"

[Audits commits, classifies changes, appends to [Unreleased]]

Result in CHANGELOG.md:
## [Unreleased]

### Fixed
- **ace-docs v0.5.1**: Broken links in documentation

### Added
- **ace-lint v0.3.0**: ace-lint integration for markdown files

### Changed
- **ace-handbook v0.21.0**: Workflow structure simplified

### Technical
- **ace-test v0.8.2**: Test coverage improvements
```

### Example 2: Accumulation Across Multiple Runs

```
> "/as-release-update-changelog"

[Existing [Unreleased] already has items from a prior run]
[New items are appended to matching categories or new categories are created]

Result:
## [Unreleased]

### Fixed
- **ace-docs v0.5.1**: Broken links in documentation
- **ace-review v0.50.3**: Fixed non-runnable examples    ← new

### Added
- **ace-lint v0.3.0**: ace-lint integration for markdown files
```

## Notes

* This workflow updates **main project CHANGELOG** only (not package CHANGELOGs)
* For package-specific changelogs, use `/as-release-bump-version [package]`
* Items accumulate under `[Unreleased]` — version numbers are assigned at publish time by
  `wfi://github/release-publish`
* Changes are documented immediately, no batching required
* Follow Keep a Changelog format for consistency
* **This workflow does NOT commit changes** - use `/as-release` for complete release with commit
