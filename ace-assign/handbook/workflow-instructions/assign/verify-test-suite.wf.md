---
doc-type: workflow
title: Assign Verify Test Suite Workflow
purpose: Narrow deterministic verification contract for ace-assign orchestration
ace-docs:
  last-updated: 2026-10-19
  last-checked: 2026-10-19
---

# Verify Test Suite Workflow

## Purpose

Run the deterministic verification contract used by `ace-assign`:
- package-scoped `ace-test <package> all --profile 6` for modified packages
- monorepo verification with `ace-test-suite --target all`

Do not run `ace-test-e2e` or `ace-test-e2e-suite` from this workflow.

## Steps

1. Detect whether modified files affect runnable code.
2. If changes are docs-only or otherwise non-runnable, skip with a clear reason.
3. Detect modified packages from the current diff or working tree.
4. Run `ace-test <package> all --profile 6` for each modified package.
5. Run `ace-test-suite --target all`.

## Hermetic Environment Rule (Forked Drive Sessions)

Package verification frequently runs inside forked assignment drive sessions, where the launcher exports fork-runtime variables (`ACE_ASSIGN_DEFAULT_TARGET`, `ACE_ASSIGN_CURRENT_ASSIGNMENT_ID`, `ACE_ASSIGN_CURRENT_FORK_ROOT`, `ACE_RUNTIME`, `ACE_ASSIGN_LAUNCH_MODE`, `ACE_ASSIGN_FORK_WINDOW`, `ACE_ASSIGN_CALLBACK_PANE`, `PROJECT_ROOT_PATH`) and ambient tmux session variables (`TMUX`, `TMUX_PANE`) may also be present. Do not scrub these by hand and never bypass the runner with raw `bundle exec rake`/`ruby` inside a forked subtree.

Always verify through `ace-test` / `ace-test-suite`: the deterministic test runner applies a hermetic environment policy that drops all ambient `ACE_*` and `LAB_*` runtime configuration (including every `ACE_ASSIGN_*` fork-runtime variable) before any test executes, in-process and for spawned subprocesses. Verification results are therefore identical whether the command runs from a clean shell or from inside a forked drive session; any other invocation forfeits that guarantee.

## Skip Guidance

Skip only when all modified files are documentation, retrospectives, task specs, or similarly non-runnable metadata.

## Success Criteria

- All modified packages pass `ace-test <package> all --profile 6`
- `ace-test-suite --target all` passes
- No E2E commands are used as part of this step
