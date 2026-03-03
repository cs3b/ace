---
id: 8p5jzi
title: ace-e2e-test Command (Task 255.02)
type: self-review
tags: []
created_at: '2026-02-06 13:19:26'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8p5jzi-ace-e2e-test-command-255-02.md"
---

# Reflection: ace-e2e-test Command (Task 255.02)

**Date**: 2026-02-06
**Context**: Full coworker session implementing ace-e2e-test CLI command in ace-test-e2e-runner gem
**Author**: Claude Opus 4.6 (coworker-driven session)
**Type**: Self-Review

## What Went Well

- **Coworker workflow execution**: All 9 steps completed smoothly in a single session (onboard, implement, PR, 2x review cycles, release, finalize)
- **Review-driven quality**: Two code-deep review cycles (3 LLM models each) caught real bugs before merge - missing `require "date"`, missing `require "stringio"`, incorrect exit codes for partial results
- **ATOM compliance correction**: Reviews correctly identified that TestDiscoverer (Dir.glob) and ScenarioParser (File.read) violated atom purity rules; moved to molecules during review
- **Dependency injection pattern**: Adding injectable executor and timestamp generator made orchestrator fully testable with StubExecutor - no LLM calls needed in tests
- **Fast test suite**: 71 tests running in ~150ms, well within performance budget

## What Could Be Improved

- **Initial ATOM layer placement**: The original implementation placed I/O-performing classes (TestDiscoverer, ScenarioParser) in atoms/. This is a recurring pattern that should be caught at implementation time, not review time
- **Git lock file interference**: Hit stale `.git/worktrees/*/index.lock` files 4 times during the session, requiring manual `rm -f` each time
- **Bundle install gap**: `ace-git-commit` failed because `bundle install` was needed after Gemfile.lock changes - this should be detected automatically
- **Review feedback extraction**: `ace-review feedback list` returned empty results both times; had to read raw review reports via subagent instead. The feedback synthesis may not be generating feedback items for this session
- **Hardcoded default provider**: The default provider (`claude:sonnet`) is hardcoded in two places — `DEFAULT_PROVIDER` constant in `TestExecutor` and the CLI option default in `RunTest` — instead of using the existing ace config pattern (`.ace-defaults/e2e-runner/config.yml`). The config file already handles paths, patterns, cleanup, and test ID validation but provider settings were bypassed

## Root Cause Analysis: Smoke Test Failure (AC 6)

### The Problem

After the full implementation passed unit tests (71 tests, 0 failures) and two code-deep review cycles, the smoke test gate (AC 6) failed: real LLM execution produced hallucinated results. The e2e test runner asked providers to run test scenarios and return JSON, but providers fabricated pass/fail outcomes instead of actually executing anything.

### The Design Flaw

The original execution model treated e2e test execution as a **text completion task**: send a prompt describing the test scenario and ask the LLM to "execute it and return structured JSON results." This is fundamentally wrong for two reasons:

1. **API providers hallucinate results** — They have no filesystem access, no command execution, no ability to actually run tests. When asked to "execute this test and return results," they generate plausible-looking but fabricated JSON.
2. **CLI providers lack context** — Even CLI-based agents (Claude Code, Codex) couldn't succeed with a bare text prompt because they lacked the workflow context, permissions, sandbox setup, and skill definitions needed to actually run the test.

This is a **category distinction, not a quality distinction**: e2e test execution requires agent capabilities (filesystem access, command execution, tool use), not just text completion. No amount of prompt engineering fixes this for API providers.

### Why It Wasn't Caught Earlier

- **Unit tests passed** because they use `StubExecutor` — the injectable dependency pattern that made tests fast and deterministic also meant no test ever hit a real LLM
- **Two code-deep review cycles** (3 LLM models each, 11 findings addressed) focused on code quality, ATOM compliance, error handling, and edge cases — not on whether the fundamental execution model was valid
- **The execution model was an implicit assumption**, not an explicit design decision that would surface in code review

### The Fix (v0.6.1)

Split execution into two distinct paths based on provider type:

1. **CLI providers (agents)** → Skill-based execution:
   - **Skill-aware providers** (Claude Code): Invoke `/ace:run-e2e-test` skill directly — the agent has full filesystem, command, and workflow capabilities
   - **Other CLI providers** (Gemini CLI, Codex): Embed the complete workflow instructions in the prompt so the agent can follow the same execution steps
   - Agents write their own reports to disk; the orchestrator reads them instead of generating its own

2. **API providers** → Retained for simple assertion-only tests where text completion is sufficient (no filesystem needed)

New atoms: `SkillPromptBuilder` (builds skill invocations vs embedded workflows), `SkillResultParser` (parses agent markdown output). Test suite expanded from 71 → 109 tests.

### Lesson

E2E test execution is an **agent task**, not a completion task. The distinction matters: when a test requires interacting with a real system (filesystem, CLI, APIs), you need an agent with tool-use capabilities, not a text model that can only predict what results might look like. This insight should inform any future feature that delegates real-world actions to LLMs.

## Key Learnings

- **Always check ATOM purity at coding time**: If a class calls `File.read`, `Dir.glob`, `IO.read`, or any shell command, it's a molecule, not an atom. This is the #1 recurring review finding
- **`require "date"` with YAML.safe_load**: When using `permitted_classes: [Date]`, Ruby needs `require "date"` explicitly. This won't surface in monorepo tests where another gem already required it
- **`failed? = !success?` is cleaner than enumeration**: Rather than listing all failure statuses (`fail`, `error`, `partial`), defining `failed?` as `!success?` ensures any non-pass status triggers failure exit codes
- **StubExecutor pattern**: Creating a simple stub class with the same interface as the real executor is cleaner than complex mocking for organism-level tests

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **ace-review feedback items empty**: Review synthesis didn't generate feedback/ directory items
  - Occurrences: 2 (both review cycles)
  - Impact: Required subagent to manually read and consolidate 3 review reports each time (~60s extra per cycle)
  - Root Cause: Possibly the feedback synthesis model didn't extract structured items from the review reports

#### Medium Impact Issues

- **Git index.lock stale files**: Worktree git operations fail intermittently
  - Occurrences: 4
  - Impact: Each occurrence required an extra `rm -f` command before retrying
  - Root Cause: Previous git operations in the worktree leaving lock files behind

- **Bundle install not auto-triggered**: CLI tools fail when gems need installing
  - Occurrences: 1 (ace-git-commit failed)
  - Impact: ~30s delay to diagnose and run bundle install
  - Root Cause: Gemfile.lock updated by `bundle lock` but gems not installed

### Improvement Proposals

#### Process Improvements

- Add "ATOM purity checklist" to task spec template: "Does this class perform I/O? If yes, it's a molecule"
- Consider auto-running `bundle install` after `bundle lock --update` in release workflows

#### Tool Enhancements

- **ace-review feedback synthesis**: Investigate why feedback items weren't generated; ensure synthesis always produces structured feedback when reviews contain findings
- **ace-git-commit**: Auto-detect missing gems and run `bundle install` before failing
- **Git lock cleanup**: Add `rm -f` lock file cleanup to ace-git-worktree operations or as a pre-flight check

## Action Items

### Stop Doing

- Placing classes that do File I/O in atoms/ directory
- Assuming `bundle lock` also installs the gems
- Hardcoding defaults in constants/CLI options when the project has a config pattern (`.ace-defaults/`) for exactly this purpose

### Continue Doing

- Two-cycle code-deep reviews for feature PRs
- Applying review fixes inline during review step (saves a round-trip)
- Using subagent to consolidate multi-model review reports
- Injectable dependencies in organisms for testability

### Start Doing

- Pre-flight ATOM purity check before committing new classes
- Recording `require` obligations when using `permitted_classes` in YAML.safe_load
- Cleaning git lock files proactively before multi-step git operations
- Validating execution model assumptions with a real smoke test before declaring implementation complete
- Distinguishing agent tasks (requires tool use) from completion tasks (text-only) when designing LLM-delegated features
- Using `.ace-defaults/` config for provider defaults instead of hardcoding — follow the existing project config pattern

## Technical Details

- **Package**: ace-test-e2e-runner v0.6.0 → v0.6.1 (post-fix)
- **Architecture**: 2→4 atoms, 4 molecules, 1 organism, 2 models, 1 CLI command
- **Tests**: 71→109 tests (149ms → expanded after fix)
- **Review models**: claude:opus, codex:max, gemini:pro-latest (2 cycles)
- **Total review findings addressed**: 11 (2 High, 8 Medium, 1 Low quick-win)

## Additional Context

- PR: https://github.com/cs3b/ace-meta/pull/193
- Task: .ace-taskflow/v.0.9.0/tasks/255-test-add/255.02-ace-e2e-test-command.s.md
- Coworker session: 8p5iyd (9 steps, all completed)
- Parent task: 255 (E2E Test Runner CLI Orchestrator)