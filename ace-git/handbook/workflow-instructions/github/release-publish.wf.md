---
doc-type: workflow
title: GitHub Release Publish Workflow
purpose: GitHub release publishing workflow
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# GitHub Release Publish Workflow

## Purpose

Create GitHub releases from root `CHANGELOG.md` entries that have no corresponding GitHub release, supporting retroactive bulk publishing and ongoing single-version releases.

## Variables

- `$version`: explicit version like `v0.9.846`, or range like `v0.9.840..v0.9.846`
- `$since`: time filter like `"3 days"` or `"this week"`
- `$dry_run`: if set, print what would be created without creating anything
- `$group_by`: optional mode switch. `package` (default) enables package-first grouping inside each date bucket. `date` keeps the legacy daily grouping.
- `$category_order`: optional ordered category list, e.g. `fixed,added,changed,technical` (defaults to fixed → added → changed → technical)

## Instructions

### 1. Determine Published Baseline

Find the latest GitHub release with a `v*` tag, ignoring non-version releases:

```bash
gh release list --limit 50 --json tagName,name --jq '[.[] | select(.tagName | startswith("v"))] | first // empty'
```

If no `v*` release exists, treat all changelog versions as unpublished.

### 1.5. Finalize Unreleased Content

Check if the `## [Unreleased]` section in `CHANGELOG.md` has substantive content (any lines between
`## [Unreleased]` and the next `## [` heading that are not blank or HTML comments).

If `[Unreleased]` is empty, skip to step 2.

If `[Unreleased]` has content:

1. **Determine the next version number:**
   - Find the highest existing versioned entry (`## [X.Y.Z]`) in `CHANGELOG.md`.
   - Increment its patch number by 1 (e.g., `0.9.932` → `0.9.933`).

2. **Rewrite the unreleased section:**
   - Move all category headings and bullet items from the `[Unreleased]` block into a new versioned entry.
   - Leave the `[Unreleased]` section empty.
   - Use today's date in ISO format.

   Before:
   ```markdown
   ## [Unreleased]

   ### Fixed
   - item 1

   ### Added
   - item 2

   ## [0.9.932] - 2026-03-29
   ```

   After:
   ```markdown
   ## [Unreleased]

   ## [0.9.933] - 2026-03-30

   ### Fixed
   - item 1

   ### Added
   - item 2

   ## [0.9.932] - 2026-03-29
   ```

3. **Commit the finalization:**
   ```bash
   ace-git-commit CHANGELOG.md -i "finalize changelog v0.9.933 from unreleased"
   ```

4. **Push the finalization commit before creating releases:**
   ```bash
   git push
   ```
   The release target commit must exist on GitHub before `gh release create` can tag and publish it.

5. Proceed to step 2 with the newly created versioned entry available for publishing.

### 2. Parse Root CHANGELOG

Read `CHANGELOG.md` and extract all version entries matching `## [X.Y.Z] - YYYY-MM-DD`.

Build a list of `{version, date, body}` records where:
- `version`: the semver string (e.g., `0.9.846`)
- `date`: the release date
- `body`: the full markdown content between this heading and the next `## [` heading

### 3. Filter Versions

Apply filters based on arguments:

| Argument | Filter |
|---|---|
| No args | All versions newer than latest published `v*` release |
| Single version `v0.9.846` | Just that version |
| Range `v0.9.840..v0.9.846` | All versions where `840 <= patch <= 846` (comparing full semver) |
| `--since "3 days"` | Versions with changelog date within the time window |

If no versions remain after filtering, report and stop:

```text
No unpublished versions found matching the given criteria.
```

### 4. Grouping

Use `$group_by` to choose the release body layout. Release tags/titles still use date-bucket grouping (highest version per date).

- `package` (default): within each date bucket, group entries as package blocks and then categories.
- `date`: preserve legacy behavior, one release body per date in descending version order separated by `---`.

Mixed-release presentation rule:

- If a date bucket contains one or more clear primary changes plus follower packages that exist only because of
  dependency-constraint propagation, render the primary package sections first.
- Collapse follower-only dependency fallout into one compact trailing `### Technical side effects` section instead
  of expanding every follower into a full package block.
- Keep follower packages explicit by name/version, but prefer a short list over repeated full prose when the
  release value is driven elsewhere.

Date mode example:

```markdown
## [0.9.846] - 2026-03-18

[changelog body for 0.9.846]

---

## [0.9.845] - 2026-03-18

[changelog body for 0.9.845]

---

## [0.9.844] - 2026-03-18

[changelog body for 0.9.844]
```

Package mode example:

```markdown
## [0.9.846] - 2026-03-18

### 📦 ace-review v0.50.3

#### Fixed
- **ace-review v0.50.3**: Corrected non-runnable package flag examples.

#### Added
- **ace-review v0.50.2**: Added package-specific examples.

### 📦 ace-handbook v0.21.0

#### Changed
- **ace-handbook v0.21.0**: Migrated publish workflow wiring.
```

Package-mode parse rules:
- Parse each version body by `### Fixed`, `### Added`, `### Changed`, `### Technical` (case-insensitive).
- Parse package from lines like `- **<package> vX.Y.Z**: ...` and map item into that package.
- Track the most recent package version seen for each package in the date bucket for package headers.
- Render categories in `fixed,added,changed,technical` unless `$category_order` overrides.
- If a bullet does not match the package pattern, place it under a fallback package section `### 📦 other`.
- If `### Technical` contains a compact follower summary list, preserve it as a single trailing `### Technical side effects`
  section rather than exploding it back into per-package blocks.

### 5. Resolve Target Commits

For each daily release group, find the commit that introduced the highest version's changelog entry:

```bash
git log --all -1 --format=%H -S "[${HIGHEST_VERSION}]" -- CHANGELOG.md
```

If the commit cannot be found, try alternative approaches:

```bash
git log --all -1 --format=%H --grep="\\[${HIGHEST_VERSION}\\]" -- CHANGELOG.md
git log --all -1 --format=%H --after="${DATE}T00:00:00" --before="${DATE}T23:59:59" -- CHANGELOG.md
```

If no commit is found for a version group, skip it and report:

```text
⚠ Could not find commit for v${VERSION} (${DATE}) — skipping
```

### 6. Create Releases

Process each daily group from oldest date to newest:

Before each live release creation:

- Verify the chosen `${SHA}` exists on the remote branch you intend to tag.
- If the workflow created or committed the changelog entry locally during step 1.5, ensure that commit has already been pushed before continuing.
- If `gh release create` reports `tag_name is not a valid tag` or `target_commitish is invalid`, stop and push the missing commit instead of retrying the same release command unchanged.

**Dry-run mode** (`--dry-run`):

```text
[DRY RUN] Would create release:
  Tag:    v${VERSION}
  Title:  v${VERSION}
  Target: ${SHA}
  Body:   ${LINE_COUNT} lines (${VERSION_COUNT} version(s) from ${DATE})
```

**Live mode**:

```bash
gh release create "v${VERSION}" \
  --title "v${VERSION}" \
  --notes-file ".ace-local/github-release/v${VERSION}-notes.md" \
  --target "${SHA}"
```

Verify each creation:

```bash
gh release view "v${VERSION}" --json tagName,targetCommitish --jq '{tag: .tagName, target: .targetCommitish}'
```

### 7. Report Results

Summarize all created releases:

```text
✓ Created v0.9.846 targeting abc1234 (2026-03-18, 7 versions)
✓ Created v0.9.839 targeting def5678 (2026-03-17, 3 versions)
⚠ Skipped v0.9.835 — commit not found
```

## Success Criteria

- Every unpublished changelog version is covered by a GitHub release
- Releases are tagged at the correct commits
- Multi-version days are consolidated with combined bodies in the selected grouping mode
- `--dry-run` produces accurate output without side effects
- Oldest releases are created first to maintain chronological order

## Response Template

**Releases Created:** [count]
**Versions Covered:** [range or list]
**Skipped:** [count and reasons, if any]
**Mode:** [live|dry-run]
**Grouping:** [date|package]
