---
id: 8po3x0
title: E2E Failure Analysis and Runner Hardening
type: conversation-analysis
tags: []
created_at: '2026-02-25 02:36:40'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8po3x0-e2e-failure-analysis-runner-hardening.md"
---

# Reflection: E2E Failure Analysis and Runner Hardening

**Date**: 2026-02-25
**Context**: Fixing 7 failing E2E scenarios across docs/git/llm/secrets/lint/taskflow/test-runner packages
**Author**: Codex
**Type**: Conversation Analysis

## What Went Well

- Failure analysis stayed evidence-first by reading per-scenario report artifacts (`metadata.yml`, `summary.r.md`, `report.md`) before edits.
- Most failures were resolved through focused scenario runner/spec improvements instead of risky package-code changes.
- One true product bug was isolated and fixed (`ace-git-secrets rewrite-history` returned success on invalid scan-file input), with a regression test added.

## What Could Be Improved

- Several E2E runners relied on implicit sandbox assumptions (existing docs corpus, branch baseline, package discovery) that were not encoded in runner instructions.
- Some verifier expectations mixed success-path and failure-path assertions (for example requiring JSON output even when provider auth fails before inference).
- Scenario instructions were occasionally too generic, leading to nondeterministic setup choices by the runner.

## Key Learnings

- E2E instability in this session was primarily specification drift, not implementation regressions.
- Runner prompts should explicitly define prerequisite state transitions (seed docs, initialize branch, create draft task) when outcomes depend on them.
- For CLI workflows using optional input files, input validation should fail fast with non-zero exits to avoid false-positive scenario passes.

## Conversation Analysis (For conversation-based reflections)

### Challenge Patterns Identified

#### High Impact Issues

- **Under-specified E2E setup constraints**: Multiple scenarios assumed preconditions not guaranteed in sandbox.
  - Occurrences: 5 scenarios (docs, git, lint, taskflow, test-runner)
  - Impact: 10+ TC failures from setup mismatch rather than tool behavior
  - Root Cause: Runner instructions emphasized capture artifacts but omitted deterministic environment preparation

- **Exit code semantics mismatch**: Rewrite command emitted helpful error text but still exited success.
  - Occurrences: 1 scenario (git-secrets TC-006)
  - Impact: verifier failure despite expected error condition being detected
  - Root Cause: command path returned nil tokens without converting to failure when `--scan-file` was explicitly supplied

#### Medium Impact Issues

- **Verifier expectation coupling**: Success-only output checks applied to early-failure flows.
  - Occurrences: 1 scenario (llm TC-002)
  - Impact: false fail classification under credential errors

#### Low Impact Issues

- **Large report parsing overhead**: Suite and scenario reports required multi-file/manual correlation.
  - Occurrences: all investigated scenarios
  - Impact: moderate analysis time, no incorrect fixes

### Improvement Proposals

#### Process Improvements

- Require each E2E runner goal to encode required preconditions explicitly when state-dependent commands are tested.
- Add a pre-merge checklist item: “Does each TC specify deterministic setup state?”
- Keep verifier expectations path-aware: success-path assertions separated from early-failure-path assertions.

#### Tool Enhancements

- Add a lightweight `ace-test-e2e doctor` check that flags runner goals lacking explicit setup for stateful commands.
- Add structured scenario metadata for “required preconditions” to reduce prompt ambiguity.

#### Communication Protocols

- During failure triage, explicitly classify each failed TC as `code-issue`, `test-issue`, or `runner-infrastructure-issue` before editing.
- Preserve no-touch boundaries in analysis to prevent speculative cross-layer edits.

### Token Limit & Truncation Issues

- **Large Output Instances**: 1 suite-level final report plus 7 scenario reports with detailed goal evidence
- **Truncation Impact**: Low; mitigated by reading scenario artifacts directly instead of relying only on final summary
- **Mitigation Applied**: Split reads by scenario and file type (`metadata`, `summary`, `report`), then cross-checked runner/verifier definitions
- **Prevention Strategy**: Keep analysis workflow artifact-targeted and avoid depending on one large aggregate report

## Action Items

### Stop Doing

- Assuming sandbox state from scenario title alone.
- Keeping verifier expectations success-only when failure-path behavior is valid and expected.

### Continue Doing

- Evidence-first TC classification before applying fixes.
- Adding regression tests for every command-level behavior bug fixed.

### Start Doing

- Encode deterministic setup commands in every stateful E2E runner goal.
- Add explicit rerun-scope rationale (scenario/package/suite) into analysis output by default.

## Technical Details

- Updated E2E runner/verify specs in:
  - `ace-docs` TS-DOCS-001 (seed/reuse docs corpus)
  - `ace-git` TS-GIT-001 (repo bootstrap, unstaged diff setup, branch baseline)
  - `ace-llm` TS-LLM-001 verifier (conditional format expectation on success)
  - `ace-lint` TS-LINT-001 (doctor target set to `.ace/lint/.rubocop.yml`)
  - `ace-taskflow` TS-TASK-002 (explicit draft/done task creation)
  - `ace-test-runner` TS-TEST-001 (explicit `$PROJECT_ROOT_PATH/ace-search` package path)
- Fixed product bug in `ace-git-secrets/lib/ace/git/secrets/commands/rewrite_command.rb` to return exit code `1` when `--scan-file` is invalid.
- Added unit regression test in `ace-git-secrets/test/commands/rewrite_command_test.rb`.

## Additional Context

- Related task: v.0.9.0+task.280
- Related report: `.cache/ace-test-e2e/8po3olw-final-report.md`