---
name: release-bump-version
description: Bump project version surfaces following semver (local only)
allowed-tools: Bash, Read, Edit
argument-hint: "[target] [patch|minor|major]"
doc-type: workflow
purpose: generic version-bump baseline
update:
  frequency: on-change
  last-updated: "2026-08-12"
---

# Bump Version Workflow

## Goal

Increment one or more project version surfaces according to Semantic Versioning and keep
changelog metadata consistent. This workflow is **local preparation only** — it does not publish,
tag remotely, or mutate external registries.

## Prep vs publication

- **In scope:** edit version files, align changelog headers/entries, refresh lockfiles when
  required by the bump.
- **Out of scope:** `gem push`, `npm publish`, deploy scripts, GitHub Release creation, or
  any other externally mutating publication step.

## Prerequisites

- Target(s) identified (package/module/app) or detectable from the working tree
- Readable current version and a known bump policy (explicit level or conventional commits)
- Clean enough git state to attribute the bump (prefer committed feature work first)

## Project Context Loading

- `ace-bundle project` (or project equivalent)
- `git status --short` and recent commits affecting the target

## Process Steps

### 1. Identify target and current version

```bash
# Discover version surfaces (adapt to the project)
# Examples:
#   package.json → "version"
#   lib/**/version.rb → VERSION =
#   Cargo.toml → [package].version
#   pyproject.toml → project.version
```

Confirm the current version string before editing.

### 2. Decide bump level

Priority:

1. Explicit argument: `patch`, `minor`, or `major`
2. Otherwise infer from commits since the last release tag/changelog section
3. If ambiguous, stop and ask — do not guess major bumps

### 3. Apply the bump

1. Write the new version to every authoritative version surface for the target.
2. Update changelog to match (new section or Unreleased notes — follow project convention).
3. Update dependency pins/lockfiles only when the version bump requires it.

```bash
# TODO: project-specific bump commands
```

### 4. Verify and commit

- Run targeted tests/build for the bumped target when available.
- Commit version + changelog (+ required lockfile) as a focused release-prep commit.
- Do not publish.

## Override

Replace or overlay this file via project WFI sources (for example
`.ace-handbook/workflow-instructions/release/bump-version.wf.md`). Lower source priority
numbers win. Keep the URI `wfi://release/bump-version` stable for skills.

## Success Criteria

- [ ] New version written to all authoritative surfaces for the target
- [ ] Changelog aligned with the bump
- [ ] No external publish/deploy performed

## Common Issues

- Multiple version files disagree — reconcile before committing.
- Pre-1.0 projects may treat minor bumps as breaking; follow project policy, not assumptions.
