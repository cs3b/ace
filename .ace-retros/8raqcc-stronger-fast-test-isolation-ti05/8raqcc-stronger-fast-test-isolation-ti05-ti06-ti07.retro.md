---
id: 8raqcc
title: stronger-fast-test-isolation-t.i05-t.i06-t.i07
type: standard
tags: [testing, fast, isolation, 8r9.t.i05, 8r9.t.i06, 8r9.t.i07]
created_at: "2026-04-11 17:33:43"
status: active
---

# stronger-fast-test-isolation-t.i05-t.i06-t.i07

**Date**: 2026-04-11  
**Context**: Fast-test migration and cleanup for t.i05/t.i06/t.i07 should not depend on monorepo runtime config  
**Author**: ACE session context  
**Type**: Standard  

## What Went Well
- We reduced a broad regression wave from one failing e2e test back to a stable fast-path by tightening config control in fast/molecule tests.
- `ace-test-runner-e2e` fast tests now explicitly set `Ace::Support::Config.test_mode` and `default_mock`, which gives deterministic behavior across working trees.
- The e2e suite rerun after the fix stayed fast and stable (`516 tests, 1519 assertions, 0 failures` in the latest check).
- The concrete failures were isolated to `ConfigLoader` fast-path behavior, making this a low-risk isolation standard to propagate.

## What Could Be Improved
- A fast-molecule test (`config_loader_test`) was implicitly reading default config from `.ace/.../config.yml`, which made assertions brittle across environments.
- Migration sub-tasking (especially around t.i05/t.i06) lacks a shared checklist rule that fast tests must use pure in-memory stubs for configuration boundaries.
- Some package migration guidance still implies path-dependent behavior, which can encourage coupling tests to host environment.

## Key Learnings
- Fast tests must treat configuration as injected test data, never as live environment-driven state.
- `test_mode` + `default_mock` is the right seam for config-dependent components in test-mode execution.
- Any test asserting default values must pin those values in setup to avoid coupling to repo or machine-local config files.

## Action Items

### Stop Doing
- Do not write fast tests that read package/monorepo config from disk as part of execution path setup.
- Do not rely on implicit global `parallel` or provider defaults in fast assertions.

### Continue Doing
- Keep fast tests using in-process stubs for executors/reporters/discovery where possible.
- Keep deterministic setup/teardown for global config and environment state in fast/molecule tests.

### Start Doing
- Add a shared fast-test isolation checklist to package migration specs under [t.i05](/home/mc/ace/.ace-tasks/8r9.t.i05-migrate-remaining-packages-to-restarted/8r9.t.i05-migrate-remaining-packages-to-restarted-teste2e-and.s.md) and [t.i06](/home/mc/ace/.ace-tasks/8r9.t.i06-migrate-batch-2-tested-packages-to/8r9.t.i06-migrate-batch-2-tested-packages-to-fastfeat.s.md).
- Add migration task acceptance gates requiring no fast test reads `.ace`, `.ace-local`, or package config files directly.
- In [t.i07](/home/mc/ace/.ace-tasks/8r9.t.i07-remove-legacy-testing-names-and-bridge/8r9.t.i07-remove-legacy-testing-names-and-bridge-code.s.md), verify that final cleanups retain fast-test boundaries and do not reintroduce config I/O in fast paths.

## Technical Details
- Canonical regression example: `/home/mc/ace/ace-test-runner-e2e/test/molecules/config_loader_test.rb` now sets mocked config in `setup` and resets it in `teardown` (including `parallel: 3`) so tests remain stable even when monorepo config differs.

## Automation Insights

### Priority Automations
1. **Fast-Test Isolation Lint/Checklist**: add a lightweight review check that flags fast tests referencing config/loaders that hit real file paths.
2. **Migration Template Update**: include one explicit isolation acceptance criterion in all t.i05/t.i06 child specs.
