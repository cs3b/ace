---
id: 8pknmg
title: E2E Report Directory Mismatch Fix
type: standard
tags: []
created_at: '2026-02-21 15:44:56'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8pknmg-e2e-report-dir-mismatch-fix.md"
---

# Reflection: E2E Report Directory Mismatch Fix

**Date**: 2026-02-21
**Context**: Fixing suite↔agent report directory name mismatch causing false ERROR results in ace-test-e2e-suite
**Author**: claude-opus
**Type**: Standard

## What Went Well

- Root cause analysis was thorough — the plan correctly identified that two independent actors (Ruby `short_id` and LLM agent) computing the same directory name was the fundamental design flaw
- Bottom-up implementation approach worked cleanly: SkillPromptBuilder → TestExecutor → TestOrchestrator → CLI → SuiteOrchestrator, each change building on the previous
- All 472 existing tests passed after changes, confirming no regressions
- The fix is minimal and targeted — adds a single parameter threaded through the existing chain rather than changing the naming convention itself

## What Could Be Improved

- The initial test run revealed 21 errors in `test_orchestrator_test.rb` because 11 stub executor signatures (1 class + 10 inline `define_singleton_method`) didn't accept the new `report_dir:` keyword parameter
- Could have anticipated the stub signature issue by searching for all executor stubs before running tests, rather than discovering it reactively
- The `run_single_test` sandbox derivation logic (stripping `-reports` suffix from `report_dir`) is somewhat fragile — it assumes a naming convention rather than making sandbox path independently configurable

## Key Learnings

- **Independent computation by multiple actors is a design smell**: When two systems (Ruby code and LLM agent) independently compute the same value from different inputs/logic, disagreement is inevitable. The fix pattern is: compute once, pass explicitly
- **Regex-based ID extraction is fragile with alphanumeric test areas**: `TS-B36TS-002` broke `short_id` because `B36TS` contains digits that the regex handles differently than the LLM's prose interpretation. The regex extracts `002` → `ts002`, while the LLM sees `B36TS-002` → `tsb36ts002`
- **Ruby keyword argument strictness**: Unlike positional args, Ruby raises `ArgumentError: unknown keyword` when a keyword is passed to a method that doesn't accept it. All stubs/mocks must be updated when adding keyword params — `replace_all` on `define_singleton_method` patterns is an efficient fix strategy
- **Test transience**: The molecule tests showed 12 errors on first run but passed on second run, indicating environmental flakiness unrelated to the changes

## Action Items

### Stop Doing

- Relying on independent computation of the same value by different actors in the system

### Continue Doing

- Threading explicit parameters through the full call chain rather than having each layer compute its own version
- Running the full test suite before and after changes to catch stub signature mismatches
- Using `replace_all` for systematic updates across test files when adding keyword parameters

### Start Doing

- When adding a keyword parameter to a method, immediately search for all stubs/mocks of that method (`define_singleton_method`, test doubles) before running tests
- Consider making both sandbox path and report directory independently passable rather than deriving one from the other

## Technical Details

**The mismatch chain:**
1. `TestScenario#short_id` uses regex `/TS-[A-Z0-9]+-(\d+[a-z]*)/` → captures only the trailing number
2. For `TS-B36TS-002`: regex captures `002` → `short_id` = `ts002`
3. LLM agent reads prose instructions about "lowercase prefix + number only" → interprets `B36TS-002` → `tsb36ts002`
4. Suite expects dir `8pkm41v-b36ts-ts002-reports`, agent creates `8pkm41v-b36ts-tsb36ts002-reports`
5. `Dir.exist?(expected_dir)` → false → `missing_agent_report_result()` → ERROR despite 3/3 pass

**The fix chain (7 files):**
- `SuiteOrchestrator#build_test_command` computes `report_dir` using Ruby's `scenario.dir_name(run_id)` and passes `--report-dir`
- CLI option `--report-dir` passes through to `TestOrchestrator#run`
- `TestOrchestrator#run_single_test` uses explicit `report_dir` for expected dir check
- `TestExecutor#execute` passes `report_dir` to `SkillPromptBuilder#build_skill_prompt`
- `build_skill_prompt` appends `--report-dir PATH` to the slash command
- `run.wf.md` documents `REPORT_DIR` parameter and conditional logic

## Additional Context

- Branch: `273-namespace-workflows-with-domain-prefixes`
- Release: ace-test-runner-e2e v0.16.12
- Related issue: TS-B36TS-002 and TS-B36TS-003 showing ERROR despite all test cases passing