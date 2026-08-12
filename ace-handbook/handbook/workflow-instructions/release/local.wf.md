---
name: release-local
description: Prepare a local release (version, changelog, verification) without publishing
allowed-tools: Bash, Read, Edit
argument-hint: "[target...] [patch|minor|major]"
doc-type: workflow
purpose: generic local release-preparation baseline
update:
  frequency: on-change
  last-updated: "2026-08-12"
---

# Local Release Preparation Workflow

## Goal

Prepare a release **locally**: decide what is being released, bump version surfaces, update
changelogs, run verification, and create release commits. This baseline does **not** publish
to any external registry, deploy target, or package host.

## Prep vs publication

| Mode | This workflow | External mutation |
|------|---------------|-------------------|
| **Local preparation (default)** | Version bumps, changelog edits, builds/tests, git commits | None |
| **Publication** | Out of scope here | Registries, deploys, GitHub Releases, etc. |

Do not run publish/deploy commands unless the project has replaced this baseline with an
explicit publication contract (see Override below, and `wfi://release/publish` /
`wfi://release/rubygems-publish` when customized).

## Prerequisites

- Working tree reflects the changes to release (committed or intentionally staged)
- Project has an identifiable version surface (examples below)
- You understand Semantic Versioning and the project's changelog convention

## Project Context Loading

- Load project conventions: `ace-bundle project` (or the project's equivalent context bundle)
- Inspect git state: `git status --short`, recent commits for the release set

## Process Steps

### 1. Resolve release targets

Treat workflow arguments as zero or more release targets plus an optional bump level
(`patch`, `minor`, or `major`).

- If targets are named, release only those.
- If none are named, detect candidates from the working tree and recent commits
  (`git status --short`, `git diff --name-only`, `git diff origin/main...HEAD --name-only`
  when `origin/main` exists).
- Prefer the project's existing package/module layout over inventing a new one.

### 2. Locate version and changelog surfaces

Discover (do not invent paths blindly):

| Concern | Common examples |
|---------|-----------------|
| Version | `package.json`, `lib/**/version.rb`, `*.gemspec`, `Cargo.toml`, `pyproject.toml`, `VERSION` |
| Changelog | root `CHANGELOG.md`, package `CHANGELOG.md`, Keep a Changelog sections |
| Lockfiles | `Gemfile.lock`, `package-lock.json`, `Cargo.lock`, etc. |

If the project has no clear version surface, stop and report what is missing rather than
guessing.

### 3. Choose bump level

- Use an explicit `patch|minor|major` argument when provided.
- Otherwise infer from conventional commits / user intent: fix→patch, feature→minor,
  breaking→major.
- Record the chosen level before editing files.

### 4. Update version and changelog (local only)

For each target:

1. Bump the version surface to the new version.
2. Add or extend changelog entries for this release (Keep a Changelog categories when used).
3. Refresh lockfiles only when the project's dependency tooling requires it for the bump.
4. Do **not** push tags, create GitHub Releases, or publish packages in this workflow.

Placeholder checklist (fill with project-specific commands):

```bash
# TODO: project version bump command(s)
# TODO: project changelog update approach
# TODO: project lockfile refresh (if required)
```

### 5. Verify before commit

Run the project's standard verification for the release set:

```bash
# TODO: replace with project test/lint/build gates
# Examples: ace-test <package>, npm test, cargo test, pytest
```

Fix failures before committing release metadata.

### 6. Commit release preparation

Create one or more commits that contain only release preparation (version, changelog,
required lockfile). Prefer the project's commit skill/tooling when available
(for example `ace-git-commit`).

Do not push or publish as part of this baseline.

## Override

Higher-priority project sources win over this gem baseline. To customize:

1. Add project workflows under `.ace-handbook/workflow-instructions/release/` (or another
   registered WFI directory source), **or** package `handbook/workflow-instructions/release/`.
2. Keep URI names stable (`wfi://release/local`) so skills and assign steps keep working.
3. WFI source priority: lower number wins; project overlays typically beat gem defaults.

## Success Criteria

- [ ] Version and changelog surfaces updated for every selected target
- [ ] Verification gates for the release set passed
- [ ] Release preparation committed locally
- [ ] No registry publish, deploy, or remote release mutation performed

## Common Issues

- **Unresolved custom publish path:** this baseline stops at local prep; add a project
  publication contract before publishing.
- **Missing version surface:** stop and ask rather than inventing version files.
- **Monorepo vs single package:** detect layout from the repo; do not assume `ace-*` gems.
