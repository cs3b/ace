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

## Instructions

### 1. Determine Published Baseline

Find the latest GitHub release with a `v*` tag, ignoring non-version releases:

```bash
gh release list --limit 50 --json tagName,name --jq '[.[] | select(.tagName | startswith("v"))] | first // empty'
```

If no `v*` release exists, treat all changelog versions as unpublished.

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

### 4. Group by Date

Multiple changelog versions on the same date are consolidated into one GitHub release per day:

- **Tag/title**: uses the highest version of that day (e.g., `v0.9.846` if versions 840–846 all share 2026-03-18)
- **Release body**: combines all changelog entries for that day, ordered from highest to lowest version, separated by `---` dividers with version headers

Single-version days produce a release with just that version's changelog body (no divider needed).

Format for multi-version daily release body:

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
  --notes "${COMBINED_BODY}" \
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
- Multi-version days are consolidated with combined bodies
- `--dry-run` produces accurate output without side effects
- Oldest releases are created first to maintain chronological order

## Response Template

**Releases Created:** [count]
**Versions Covered:** [range or list]
**Skipped:** [count and reasons, if any]
**Mode:** [live|dry-run]