# Reflection: E2E Runner CLI Consolidation Issues

**Date**: 2026-02-05
**Context**: Consolidating E2E runner CLI into `ace-test-e2e-runner`, fixing report layout, provider defaults, and execution failures.
**Author**: Codex
**Type**: Conversation Analysis

## What Went Well

- Identified concrete failure modes from user runs (FrozenError, malformed reports, wrong provider flags).
- Implemented report layout and run-id generation aligned with existing workflow (ace-timestamp + `-reports` sibling).
- Added formatter hooks and CLI options to surface per-test progress and summaries.

## What Could Be Improved

- Final validation against real `ace-e2e-test` runs was not completed before claiming done.
- Packaging decisions drifted (split CLI gem) despite user preference for single package.
- Provider flag handling (`--temperature`) was not removed early enough from E2E path.

## Key Learnings

- E2E tooling must be validated via actual CLI runs, not only unit tests.
- Aligning with existing workflow structure is critical (report paths and layout are part of the contract).
- Packaging choices should match project patterns (single gem like `ace-test-runner`).

## Conversation Analysis (For conversation-based reflections)

### Challenge Patterns Identified

#### High Impact Issues

- **Premature completion claim**: Marked task as done while `ace-e2e-test` still failed.
  - Occurrences: multiple user corrections
  - Impact: rework, loss of trust, repeated reruns
  - Root Cause: incomplete end-to-end verification and assumption-based validation

- **Packaging divergence**: Introduced `ace-test-e2e-runner-cli` despite requirement to keep one package.
  - Occurrences: 1 major decision
  - Impact: migration rework, deletion and reorganization needed
  - Root Cause: interpreting “external runner” as a separate gem instead of in-package CLI

#### Medium Impact Issues

- **Provider flag mismatch**: `--temperature` sent to Claude CLI caused errors.
  - Occurrences: repeated failures in user runs
  - Impact: E2E execution blocked

#### Low Impact Issues

- **Config drift**: Defaults included options not needed (`max_tokens`, temperature).
  - Occurrences: 1
  - Impact: confusion and cleanup work

### Improvement Proposals

#### Process Improvements

- Add a required “real CLI smoke run” checklist step before marking tasks complete.
- Explicitly confirm packaging decisions against existing repo patterns early.

#### Tool Enhancements

- Add a validator to detect unsupported provider options for `ace-llm` drivers.
- Add a formatter regression test that validates report layout and frontmatter files.

#### Communication Protocols

- Confirm “single package” requirements upfront when repository has established patterns.

### Token Limit & Truncation Issues

- **Large Output Instances**: none
- **Truncation Impact**: none
- **Mitigation Applied**: none
- **Prevention Strategy**: none

## Action Items

### Stop Doing

- Marking tasks complete without an end-to-end CLI validation.
- Introducing new packages without confirming project conventions.

### Continue Doing

- Using workflow specs to drive report layout and run ID behavior.
- Adding focused unit tests for atoms/molecules.

### Start Doing

- Add a checklist gate: “run `ace-e2e-test` on a real package” for E2E changes.
- Verify provider compatibility flags before wiring options into CLI.

## Technical Details

- E2E report structure requires `.cache/ace-test-e2e/<run_id>-<pkg>-<test>` and `-reports` sibling.
- Default provider should be `claude:sonnet` (alias via `ace-llm`).

## Additional Context

- PR: 190 (E2E runner changes)
