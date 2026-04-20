---
id: 8rds3v
title: 8rd.t.bzp.8 ace-git-secrets public-surface e2e
type: standard
tags: [ace-git-secrets, e2e, migration]
created_at: "2026-04-14 18:44:19"
status: active
---

# 8rd.t.bzp.8 ace-git-secrets public-surface e2e

## What Went Well
- Successfully migrated `TS-SECRETS-001` to a clearer public-surface contract while preserving core value paths (`TC-002`, `TC-003`, `TC-008`).
- Added `TS-SECRETS-002-remediation-path` and iterated to green with concrete report-driven debugging.
- Kept release flow disciplined: task status updated, package tests (`ace-test all --profile 6`) and E2E tests passed, then minor release completed in a clean tree.

## What Could Be Improved
- Task-bundled migration references under `.ace-local/e2e-migration/ace-git-secrets/` were missing, which forced fallback planning and extra reconciliation.
- Initial TS002 revoke expectations were too strict for non-revocable token types (`github-pat` naming mismatch with revocation mapping), causing avoidable reruns.
- Artifact declarations in goal docs need tighter alignment with what runners reliably emit to avoid missing-artifact false negatives.

## Action Items
- Add a preflight check in future package migration tasks to fail early when referenced `.ace-local/e2e-migration/*` inputs are missing.
- Add/track a follow-up issue to normalize revocability mapping for gitleaks token names (e.g., `github-pat`) or document expected no-op revoke behavior explicitly.
- Reuse the final TS001/TS002 artifact-contract pattern as a template for remaining package migrations in this assignment batch.
