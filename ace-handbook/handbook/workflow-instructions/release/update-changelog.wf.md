---
name: release-update-changelog
description: Update CHANGELOG entries for recent changes (local only)
allowed-tools: Bash, Read, Edit
argument-hint: "[change-description]"
doc-type: workflow
purpose: generic changelog-update baseline
update:
  frequency: on-change
  last-updated: "2026-08-12"
---

# Update Changelog Workflow

## Goal

Capture recent work in the project's changelog using the repository's established format
(prefer [Keep a Changelog](https://keepachangelog.com/) when the file already follows it).
This is **documentation/prep only** — it does not bump versions for publication or publish
artifacts.

## Prep vs publication

- **In scope:** audit commits/diffs, classify entries, edit changelog file(s), commit docs.
- **Out of scope:** cutting a GitHub Release, publishing packages, or deploying.

## Prerequisites

- A changelog file exists or the project agrees to create one (usually `CHANGELOG.md`)
- Enough git history to attribute changes since the last recorded entry

## Project Context Loading

- `ace-bundle project` (or project equivalent)
- Inspect `CHANGELOG.md` (root and/or package-level) and recent `git log`

## Process Steps

### 1. Locate changelog target

Prefer the changelog the project already uses. Common layouts:

- Single root `CHANGELOG.md`
- Per-package changelogs in a monorepo
- `## [Unreleased]` section that later becomes a versioned section at release time

### 2. Audit changes since the last entry

```bash
git log --pretty=format:"%h %s" --no-merges
# Narrow with paths or --since once the last changelog boundary is known
git diff --stat <last-boundary>..HEAD
```

### 3. Classify entries

Use Keep a Changelog categories when applicable:

| Category | Use when |
|----------|----------|
| Added | Net-new capability |
| Changed | Behavior change to existing capability |
| Fixed | Bug/crash correction |
| Removed | Capability removed |
| Deprecated | Still present but discouraged |
| Security | Vulnerability fixes |
| Technical | Non-functional chore/docs/test/refactor (if the project uses this bucket) |

### 4. Write entries

- Append under `## [Unreleased]` when that section exists; otherwise follow project layout.
- Keep bullets user-facing and scoped; mention package/module names in monorepos.
- Incorporate any explicit change-description argument from the skill invocation.

### 5. Commit locally

Commit changelog-only edits when that matches project practice. Do not publish.

## Override

Project overlays under registered WFI sources replace this baseline while keeping
`wfi://release/update-changelog` stable. Lower priority numbers win.

## Success Criteria

- [ ] Changelog reflects audited changes for the intended scope
- [ ] Categories match project convention
- [ ] No publish/deploy side effects

## Common Issues

- Missing `[Unreleased]` section — add it after the header when using Keep a Changelog.
- Duplicate bullets — dedupe against existing Unreleased items before committing.
