---
id: 8r9juj
title: t.hzr fix-tests followup
type: standard
tags: [assignment, 8r9itx, t.hzr, ace-test-runner-e2e]
created_at: "2026-04-10 13:13:56"
status: active
---

# t.hzr fix-tests followup

## What Went Well
- The failure report path from assignment step `010.01.08` pointed directly to the failing assertion and stderr context.
- Focused verification (`config_loader_test`, `affected_detector_test`) plus package profile run validated the fix quickly.
- Using `ace-git-commit` with scoped paths avoided unrelated working-tree changes.

## What Could Be Improved
- The provider-order assertion change and stderr-noise fix were split across separate steps; coupling surfaced only during retry.
- `AffectedDetector` previously used `Open3.capture2`, allowing git stderr noise to leak into test output for invalid refs.

## Action Items
- Keep `ConfigLoader.cli_providers` assertions order-insensitive unless order is explicitly part of contract.
- Prefer `Open3.capture3` (or explicit stderr handling) for git probes expected to fail in tests.
- Preserve focused rerun sequence in fix-tests reports: failing test -> related molecule -> package profile.
