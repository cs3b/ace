---
id: 8raryd
title: 8r9.t.i06.7 fast-only migration retrospective
type: standard
tags: [testing, migration, ace-support-cli]
created_at: "2026-04-11 18:38:11"
status: active
---

# 8r9.t.i06.7 fast-only migration retrospective

## What Went Well
- The package migration stayed scoped to `ace-support-cli` with no cross-package side effects.
- Deterministic tests were moved to `test/fast/` and all required verification commands passed:
  - `ace-test ace-support-cli`
  - `ace-test ace-support-cli all`
  - `cd ace-support-cli && ace-test all --profile 6`
- Release artifacts were completed cleanly:
  - package version bumped to `0.6.4`
  - package and root changelogs updated
  - `Gemfile.lock` refreshed via `bundle install`

## What Could Be Improved
- The initial test move broke relative `require_relative "../test_helper"` paths in relocated tests and required a second pass.
- The `release-minor` label can imply a minor semver bump, but support-package dependency constraints (`~> 0.6`) made a patch bump the safer choice for isolated subtree release.
- Fork session metadata for `010.08` was missing, so review-provider detection required fallback handling.

## Action Items
- Add a migration checklist item to validate `require_relative` depth immediately after moving tests into `test/fast/`.
- Document release-step guidance for choosing `patch` in support-package technical migrations where a minor bump would trigger broad follower releases.
- Add/verify fork-session metadata emission for current subtree roots so `pre-commit-review` can resolve provider routing deterministically.
