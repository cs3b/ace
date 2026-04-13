---
id: 8rbpps
title: 8r9.t.i05.m fast-feat-e2e migration retro
type: standard
tags: [assignment, task, 8r9.t.i05.m]
created_at: "2026-04-12 17:08:40"
status: active
---

# 8r9.t.i05.m fast-feat-e2e migration retro

## What Went Well
- Completed the package migration to `test/fast` + `test/feat` with clean directory moves and no remaining deterministic `test/integration` files.
- Restored all deterministic verification gates after migration:
  - `ace-test ace-test-runner`
  - `ace-test ace-test-runner feat`
  - `ace-test ace-test-runner all`
- Stabilized package E2E execution and reached a clean `ace-test-e2e ace-test-runner` run (`13/13` test cases passed).
- Kept release flow scoped and clean: `ace-test-runner` released to `v0.24.0` with synchronized package + root changelog updates and lockfile refresh.

## What Could Be Improved
- E2E scenario setup/runner contracts were brittle around sandbox root assumptions (`$PROJECT_ROOT_PATH`, config copy locations, and package paths), causing repeated reruns.
- TS-TEST-002 verifier contract over-relied on `.exit` artifacts even when stdout/stderr carried sufficient failure evidence; this created false negatives.
- Pre-commit review fallback (`ace-lint`) on a directory reported limited coverage context; file-scoped lint targeting would provide clearer signal.

## Action Items
- Add an E2E scenario authoring checklist for sandbox-root assumptions:
  - config source path fallbacks
  - fixture copy guarantees
  - package path resolution in runner goals
- Standardize verifier rules to treat `.exit` as preferred, with explicit stdout/stderr fallback criteria.
- Consider a helper macro/template for suite-runner scenarios that always captures `command.txt`, `stdout.txt`, `stderr.txt`, and `.exit` consistently.
- Add a lightweight assignment preflight check that flags E2E scenario setup drift before `ace-test-e2e` execution.
