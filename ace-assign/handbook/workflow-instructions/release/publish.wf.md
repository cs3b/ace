---
doc-type: workflow
title: Publish Release Workflow
purpose: fallback release workflow for assignment-driven release steps in ACE-style monorepos
ace-docs:
  last-updated: 2026-03-29
---

# Publish Release Workflow

## Goal

Provide a shipped default workflow for `wfi://release/publish` so assignment presets such as
`work-on-task` are usable in ACE-style monorepos without hidden workflow files.

## Scope

This workflow is intentionally ACE-oriented and safe-by-default:

- Detect releasable `ace-*` package changes in this repository layout
- Bump package versions using semver (`patch|minor|major`)
- Update package `CHANGELOG.md` entries
- Update root `CHANGELOG.md` `[Unreleased]` once
- Commit coordinated release changes

## Inputs

- Optional package names (`ace-assign`, `ace-task`, ...)
- Optional bump level (`patch`, `minor`, `major`)

If no packages are provided, auto-detect from the current working tree and branch diff
using `ace-*` path conventions.

## Process

1. Load project context: `ace-bundle project`.
2. Detect target packages from changed `ace-*` paths (or use explicit package args).
3. Validate package structure (`lib/**/version.rb` + package `CHANGELOG.md`).
4. Determine bump level per package.
5. Update package version and changelog entries.
6. Refresh lockfile if dependency versions changed.
7. Update root `CHANGELOG.md` in `[Unreleased]`.
8. Commit with `ace-git-commit` scoped to changed release files.

## Verification

```bash
git status --short
ace-test <resolved-package-1> [<resolved-package-2> ...]
```

Run `ace-test` against the same package set resolved in Process step 2.
If package auto-detection resolved `ace-assign ace-task`, run `ace-test ace-assign ace-task`.

## Notes

- For coordinated multi-package release orchestration, operators may still use `/as-release`.
- This workflow exists so `wfi://release/publish` is always resolvable in ACE-style installs.
