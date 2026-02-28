---
status: done
completed_at: 2026-02-24 10:11:33.000000000 +00:00
id: 8pne61
title: 'Idea: Implement 6-Phase Goal-Mode Pipeline in ace-test-e2e'
tags: []
created_at: '2026-02-24 09:26:41'
---

# Idea: Implement 6-Phase Goal-Mode Pipeline in ace-test-e2e

**Origin**: Post-delivery validation of task 280 (E2E Test Levels, Grouping, Goal-Based Execution)
**Date**: 2026-02-24
**Tags**: e2e-runner, goal-mode, verifier, pipeline, architecture
**Priority**: high
**Package**: ace-test-runner-e2e

## Problem

Task 280's experiment validated a 6-phase dual-agent pipeline for goal-mode E2E tests. The pilot (experiment/phase-[a-f]) correctly identified 2 failures in ace-b36ts: TC-003 (test-spec-error) and TC-007 (tool-bug: roundtrip mismatch).

But `ace-test-e2e run` doesn't implement this pipeline. Running the same tests through the production code:

```
ace-test-e2e run ace-b36ts --progress --provider claude:haiku
Result: PASS 8/8 cases   ← FALSE POSITIVE
```

TC-007 artifacts clearly show failure:
- `roundtrip.exit`: `1` (non-zero)
- `roundtrip-values.txt`: encoded 2025-06-15, decoded 2025-06-14 23:00:00 UTC (date mismatch)
- `roundtrip.stderr`: `Error: Split path must resolve to 6 or 7 characters, got 8`

Meanwhile old procedural tests still run through the same code path:
```
ace-test-e2e run ace-lint --progress --provider claude:haiku
Result: 3/3 PASS (all procedural format, unchanged)
```

The "big-bang cutover" declared in 280.05/280.06 happened in naming and format conventions but NOT in the execution engine.

## Expected Architecture (from experiment)

The experiment defines 6 phases — 4 deterministic (Ruby) + 2 LLM:

| Phase | Type | What it does |
|-------|------|-------------|
| **A** | Ruby | Create sandbox with .git, mise.toml, .ace/llm/providers symlink, results/ dirs |
| **B** | Ruby | Bundle TC-*.runner.md files into runner-prompt.md + create runner-system.md |
| **C** | LLM  | Execute runner via `ace-llm` with prepared system+prompt files |
| **D** | Ruby | Collect artifacts from results/ + bundle TC-*.verify.md into verifier-prompt.md |
| **E** | LLM  | Execute verifier via `ace-llm` with prepared system+prompt files |
| **F** | Ruby | Parse verifier output into YAML-frontmatter report |

Key properties:
- Runner only executes goals — doesn't self-evaluate
- Verifier is ALWAYS run (not optional) — sole authority on pass/fail
- Prompts are deterministically prepared with embedded content
- Sandbox is a proper environment (.git, mise.toml, tool access)

## Current Implementation

`ace-test-e2e run` uses a completely different approach:

1. **SkillPromptBuilder** creates a one-line skill invocation: `/ace-e2e-run {package} {test-id}`
2. **TestExecutor** sends this to the LLM via QueryInterface
3. The agent handles EVERYTHING: discovers test files, creates sandbox, executes, self-evaluates, writes reports
4. **SkillResultParser** extracts pass/fail counts from agent's markdown response
5. Verifier only runs if `--verify` flag is explicitly passed

## Gap Analysis

| Phase | Experiment | Current ace-test-e2e | Gap |
|-------|-----------|---------------------|-----|
| **A** (Sandbox) | .git, mise.toml, .ace config, results dirs, ace-llm providers | Bare dir with just results/tc/ dirs | No .git, no mise.toml, no .ace config, no tool verification |
| **B** (Runner prep) | Bundled system prompt + concatenated runner.md files | One-line skill invocation string | No prepared prompts; agent discovers everything |
| **C** (Runner exec) | `ace-llm` with system + prompt files; agent only executes | Agent runs /ace-e2e-run skill (handles setup, execute, evaluate, report) | Agent does too much; self-evaluates instead of just producing artifacts |
| **D** (Verifier prep) | Collect artifacts + bundle verify.md; embed artifact content | Only if --verify: text prompt with sandbox path | No artifact collection; verifier must discover everything |
| **E** (Verifier exec) | Always runs; independent agent with embedded artifacts | Optional (--verify flag); verifier explores sandbox on its own | Not always run; when run, less effective without embedded artifacts |
| **F** (Report gen) | Deterministic parsing of verifier output | Regex parsing of agent's markdown response | Similar but parses runner response (not verifier) by default |

## Root Cause of False Positive

The runner agent (haiku) was asked to both execute goals AND verify results in a single pass. The `.verify.md` criteria for TC-007 explicitly require "roundtrip match" and FAIL on mismatch. But the agent:
1. Produced correct artifacts (the mismatch is visible in roundtrip-values.txt)
2. Incorrectly self-assessed as PASS despite the evidence
3. No independent verifier ran to catch the error

## Suggested Scope

Implement the 6-phase pipeline for standalone goal-mode scenarios (`mode: goal` with `TC-*.runner.md` + `TC-*.verify.md` pairs):

1. **Phase A**: Proper sandbox setup in Ruby (SetupExecutor or new SandboxBuilder)
   - `git init`, `mise.toml` with resolved bin path, `.ace/llm/providers` symlink
   - Reference: `experiment/phase-a-setup-sandbox.wf.md`

2. **Phases B+D**: Prompt preparation in Ruby (PromptBundler or similar)
   - Use `ace-bundle` to concatenate runner/verify files
   - Create system+prompt file pairs
   - For verifier: embed artifact contents (directory tree + file contents)
   - Reference: `experiment/phase-b-prepare-runner.wf.md`, `experiment/phase-d-prepare-verifier.wf.md`

3. **Phases C+E**: Direct `ace-llm` calls (not skill invocations)
   - Runner: `ace-llm {provider} --system runner-system.md --prompt runner-prompt.md`
   - Verifier: `ace-llm {provider} --system verifier-system.md --prompt verifier-prompt.md`
   - Verifier ALWAYS runs for standalone goal-mode (not optional)
   - Reference: `experiment/phase-c-execute-runner.wf.md`, `experiment/phase-e-execute-verifier.wf.md`

4. **Phase F**: Deterministic report generation from verifier output
   - Parse PASS/FAIL verdicts
   - Generate YAML frontmatter report
   - Reference: `experiment/phase-f-generate-report.wf.md`

5. **Procedural mode unchanged**: Old procedural tests keep working through existing code path

## Reference Files

### Experiment (validated architecture)
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/plan.md`
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/phase-a-setup-sandbox.wf.md`
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/phase-b-prepare-runner.wf.md`
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/phase-c-execute-runner.wf.md`
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/phase-d-prepare-verifier.wf.md`
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/phase-e-execute-verifier.wf.md`
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/phase-f-generate-report.wf.md`

### Task specs (what was promised)
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/280.05-based-case-format.s.md` (6-phase workflow, lines 126-131)
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/280.06-agent-pat.s.md` (verifier pattern, big-bang cutover)

### Current implementation (what exists)
- `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/molecules/test_executor.rb`
- `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/atoms/skill_prompt_builder.rb`
- `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/atoms/skill_result_parser.rb`
- `ace-test-runner-e2e/lib/ace/test/end_to_end_runner/organisms/test_orchestrator.rb`

### Evidence (false positive)
- `.cache/ace-test-e2e/8pne61a-b36ts-ts001/results/tc/07/roundtrip.exit` → `1`
- `.cache/ace-test-e2e/8pne61a-b36ts-ts001/results/tc/07/roundtrip-values.txt` → date mismatch
- `.cache/ace-test-e2e/8pne61a-b36ts-ts001/results/tc/07/roundtrip.stderr` → ArgumentError
- `.cache/ace-test-e2e/8pne61a-b36ts-ts001-reports/summary.r.md` → reports 8/8 PASS

### Pilot results (correct verdicts)
- `.ace-taskflow/v.0.9.0/tasks/280-test-test-define/experiment/sandbox/reports/report.md` → 6/8 (TC-003 FAIL, TC-007 FAIL)