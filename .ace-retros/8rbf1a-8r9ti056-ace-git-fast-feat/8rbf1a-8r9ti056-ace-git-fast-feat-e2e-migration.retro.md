---
id: 8rbf1a
title: 8r9.t.i05.6 ace-git fast-feat-e2e migration
type: standard
tags: [assignment, 8r9.t.i05.6, ace-git, e2e]
created_at: "2026-04-12 10:01:26"
status: done
---

# 8r9.t.i05.6 ace-git fast-feat-e2e migration

## What Went Well
- Completed the `fast` / `feat` / `e2e` migration end-to-end for `ace-git`, including deterministic suite relocation to `test/fast` and promotion of legacy integration coverage to `test/feat`.
- Kept deterministic verification green throughout migration (`ace-test ace-git`, `ace-test ace-git feat`, `ace-test ace-git all` all passed).
- Preserved E2E scenario value while aligning metadata and adding explicit TC decision traceability (`e2e-decision-record.md`).
- Completed coordinated release updates for `ace-git v0.21.0` with package changelog, root changelog, and lockfile sync.

## What Could Be Improved
- Initial `ace-test-e2e ace-git` run failed due to ambiguous artifact placeholders (`*.stdout|stderr|exit`, `diff.*`) being interpreted as literal required files.
- Plan generation via `ace-task plan <ref>` path showed stall risk in this environment, requiring manual planning fallback in the assignment step.
- Pre-commit fallback lint surfaced 24 style warnings, creating review noise despite no blocking defects.

## Action Items
- Add E2E runner/verifier authoring guidance checks to prevent wildcard/pipe artifact placeholders in TC contracts.
- Add/extend assignment-time handling for `ace-task plan` stalls so fallback routing is automatic and faster.
- Consider optional `ace-lint --auto-fix` pass on migration-edited markdown artifacts before pre-commit review to reduce warning-only churn.
