---
doc-type: workflow
title: Squash Changelog Entries Workflow
purpose: changelog management workflow instruction
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Squash Changelog Entries Workflow

Consolidate multiple CHANGELOG.md version entries added on a feature branch into a single entry before merging to the target branch.

## When to Use

On feature branches with multiple `ace-release` cycles that each added a version entry to root `CHANGELOG.md`. Before merging the PR, squash these into one entry using the **lowest** version number.

## Prerequisites

- On a feature branch (not main/master)
- Root `CHANGELOG.md` exists with entries added during this branch's lifecycle
- Entries follow [Keep a Changelog](https://keepachangelog.com/) format

## Steps

### 1. Safety Check

Verify you are NOT on main/master:

```bash
BRANCH=$(git branch --show-current)
```

If on `main` or `master`, **STOP** unless `--force` was passed. Squashing on main would alter published history.

### 2. Determine Target Branch

Use this priority order to find the branch this PR targets:

1. **Embedded context** — check `<current_repository_status>` for "Current PR → Target: X"
2. **Explicit argument** — if user passed a branch name, use it
3. **GitHub CLI** — `gh pr view --json baseRefName --jq '.baseRefName'`
4. **Fallback** — `main`

```bash
TARGET=$(gh pr view --json baseRefName --jq '.baseRefName' 2>/dev/null || echo main)
```

### 3. Detect New Entries

Use the embedded `<changelog_diff>` section if available. Otherwise:

```bash
git diff "$TARGET" -- CHANGELOG.md
```

Extract all new `## [X.Y.Z]` version headers that were **added** (lines starting with `+## [`).

```bash
git diff "$TARGET" -- CHANGELOG.md | grep -E '^\+## \[[0-9]+\.[0-9]+\.[0-9]+\]' | sed 's/^\+//'
```

### 4. Validate Entry Count

| Count | Action |
|-------|--------|
| 0 | Report "No new changelog entries found — nothing to squash." **STOP.** |
| 1 | Report "Only one entry found — already consolidated, nothing to squash." **STOP.** |
| 2+ | Proceed to squash. |

### 5. Parse Entries

Read `CHANGELOG.md` and extract each new entry's content:

- For each detected version header, capture everything from `## [X.Y.Z]` down to (but not including) the next `## [` header
- Parse into categories: Fixed, Added, Removed, Changed, Technical
- Preserve individual line items with their package version prefixes (e.g., `**ace-foo v1.2.3**:`)

### 6. Select Version

Use the **LOWEST** version number from the detected entries (numeric comparison, not lexicographic).

**Numeric comparison**: Compare major, then minor, then patch as integers.
- `0.9.496` < `0.9.497` < `0.9.498` → select `0.9.496`

Keep the **date** from the lowest version entry (it was the first release on this branch).

### 7. Merge Categories

Combine all items across entries by category, following this canonical order:

1. **Fixed**
2. **Added**
3. **Removed**
4. **Changed**
5. **Technical**

Rules:
- **Dedup similar items**: If two entries describe the same fix/feature with slightly different wording, keep the more descriptive one
- **Preserve package prefixes**: Keep `**ace-foo vX.Y.Z**:` prefixes for traceability
- **Skip empty categories**: Only include categories that have items after merging
- **Within each category**: Order items by package name, then by version (ascending)

### 8. Preview

Show the squashed entry to the user. Format:

```
--- Squashed changelog entry ---
Merging N entries ([highest]...[lowest]) into single [lowest] entry:

## [X.Y.Z] - YYYY-MM-DD

### Fixed
- item 1
- item 2

### Added
- item 3

...
--- End preview ---

Confirm: Replace N entries with this single entry? (Y/n)
```

Wait for user confirmation before proceeding.

### 9. Replace

Use the **Edit** tool to replace the multi-entry block in `CHANGELOG.md`:

- `old_string`: The entire block from the first (highest version) `## [X.Y.Z]` header through the last line of the last (lowest version) entry, up to but not including the next pre-existing `## [` header
- `new_string`: The single squashed entry from step 8

### 10. Verify

After replacement, confirm correctness:

```bash
# Old versions should be gone
grep -E "## \[OLD_VERSION\]" CHANGELOG.md
# Should return no results for removed versions

# New version should be present
grep -E "## \[LOWEST_VERSION\]" CHANGELOG.md
# Should return exactly one match

# Unreleased section should be intact
grep "## \[Unreleased\]" CHANGELOG.md
# Should return one match
```

### 11. Report

Print a summary:

```
Squashed N changelog entries into one:
  Removed: [0.9.498], [0.9.497]
  Kept:    [0.9.496] (with all 13 items merged)

Changes are NOT committed. Review and commit when ready.
```

## Edge Cases

### Different Dates Across Entries

Use the date from the **lowest** version (earliest release on this branch). The squashed entry represents the cumulative work starting from that point.

### Multiple Packages in Same Category

Keep all items — each has its own package prefix for disambiguation:

```markdown
### Fixed
- **ace-assign v0.7.3**: Fix A
- **ace-assign v0.7.5**: Fix B
```

### Dirty Working Tree

If there are uncommitted changes to `CHANGELOG.md`, warn the user:

```
Warning: CHANGELOG.md has uncommitted changes. These will be included in the squash result.
Proceed anyway? (y/N)
```

### Version Comparison

Always compare versions **numerically**, not as strings:
- `0.9.10` > `0.9.9` (numeric: 10 > 9)
- String comparison would incorrectly say `0.9.9` > `0.9.10`

Split on `.`, compare each segment as integers.

## Examples

### Example 1: Three Entries on Feature Branch

Before:
```markdown
## [Unreleased]

## [0.9.498] - 2026-02-13
### Fixed
- **ace-assign v0.7.5**: Fix A
### Changed
- **ace-assign v0.7.5**: Change B

## [0.9.497] - 2026-02-13
### Fixed
- **ace-assign v0.7.4**: Fix C
### Added
- **ace-assign v0.7.4**: Feature D

## [0.9.496] - 2026-02-13
### Added
- **ace-assign v0.7.3**: Feature E
### Fixed
- **ace-assign v0.7.3**: Fix F
```

After squash:
```markdown
## [Unreleased]

## [0.9.496] - 2026-02-13
### Fixed
- **ace-assign v0.7.3**: Fix F
- **ace-assign v0.7.4**: Fix C
- **ace-assign v0.7.5**: Fix A
### Added
- **ace-assign v0.7.3**: Feature E
- **ace-assign v0.7.4**: Feature D
### Changed
- **ace-assign v0.7.5**: Change B
```

### Example 2: Already Squashed

```
Only one entry found ([0.9.496]) — already consolidated, nothing to squash.
```