---
id: 8rlkxk
title: Assignment 8rlkqs 010.01 - quick-start CLI provider guidance
type: standard
tags: [assignment, docs, quick-start, 8rl.t.k5a.0]
created_at: "2026-04-22 13:57:18"
status: active
---

# Assignment 8rlkqs 010.01 - quick-start CLI provider guidance

## What Went Well
- Updated both install entry points (`README.md` and `docs/quick-start.md`) in one pass, preventing drift.
- Added explicit `ace-llm-providers-cli` guidance and aligned provider verification wording around `ace-llm --list-providers`.
- Clarified first-run setup expectations (large tracked generated files) to reduce onboarding surprise.
- Validation stayed fast and deterministic (`ace-lint` plus targeted string checks), appropriate for docs-only scope.

## What Could Be Improved
- Pre-commit review fallback produced many existing em-dash warnings unrelated to this subtask, adding noise to quality signal.
- Release step guidance is package-centric; docs-only subtrees need an explicit no-op release path to avoid unnecessary analysis.

## Action Items
- Improve pre-commit review fallback to scope lint findings to newly changed lines/files only when `pre_commit_review_block=false`.
- Add a docs-only release skip heuristic to `release-minor` child workflow for task subtrees with no `ace-*` package changes.
- Consider adding a quick-start docs consistency check in CI to ensure install command parity between `README.md` and `docs/quick-start.md`.
