---
id: 8r0omn
title: e2e-test-maintenance-learnings
type: standard
tags: [e2e, testing, maintenance]
created_at: "2026-04-01 16:25:11"
status: active
---

# E2E Test Maintenance Learnings

Session fixed 8 E2E failures across 3 suite runs (146/151 -> 148/151 -> 151/151), touching 7 packages. Patterns emerged in how E2E tests break and what makes them resilient.

## What Went Well

- **Analysis-first workflow works**: The wfi://e2e/fix hard gate (requiring categorized analysis before any fix) prevented wasted effort. Every fix was traceable to evidence.
- **Category taxonomy is accurate**: runner-error / test-spec-error / code-issue / tool-bug classifications correctly guided priority and fix target in every case.
- **Unit tests caught nothing broken**: All code fixes (queue_state nil guard, security auditor raw_value, worktree alias removal) passed existing unit tests immediately -- the bugs lived in integration seams that unit tests don't cover.
- **Incremental reruns are cost-effective**: Scenario-scoped reruns (`ace-test-e2e {pkg} {TS-ID}`) validated fixes without burning full suite runs.

## What Could Be Improved

### 1. LLM runner interpretation variance is the #1 E2E fragility source

Three of 8 failures were caused by the LLM runner interpreting underspecified runner.md instructions differently across runs:
- **BUNDLE TC-004**: Runner hallucinated a 5th test case not in the spec. Then on rerun, used `--file` flag instead of preset names, hitting a different code path that breaks auto-format.
- **Pattern**: Vague instructions like "Using what you learned from Goal 1, invoke ace-bundle" give the LLM too much freedom. Each run picks different commands.

### 2. Test specs drift from implementation changes

Two failures (SIM TC-002, TC-005) were caused by a feature commit (5e8a12a94: `synthesis_provider: role:sim-synthesis`) that didn't update the corresponding E2E verify expectations. The code change was intentional; the test staleness was an oversight.

### 3. Sandbox isolation gaps cause false negatives

RUNNER TC-003 failed because the sandbox didn't include `ace-demo/` -- the test expected dry-run discovery of a package that wasn't copied into the sandbox. The setup section was incomplete for the test's actual scope.

### 4. CLI option aliasing has hidden interaction bugs

WORKTREE TC-003 exposed that explicit `aliases: ["--task-associated"]` on boolean options conflicts with ace-support-cli's auto-generated `--[no-]` negation syntax. The positive flag worked; only the negative form broke. This class of bug is invisible in unit tests because they test the filter logic, not the CLI parsing layer.

### 5. Security defaults vs test expectations misalign

SECRETS TC-005 expected `raw_value` in JSON stdout, but `to_json` defaults to `include_raw: false` for security. The saved report file (used by TC-004) includes raw values. The asymmetry between stdout and file output is a design gap.

## Key Learnings

### Runner.md specifications must be deterministic

**Lesson**: Every E2E runner.md should specify exact commands, not indirect instructions. When the runner says "use what you learned" or "invoke the tool", different LLM models will choose different flags, paths, and argument combinations.

**Evidence**: BUNDLE TC-004 failed twice with different symptoms -- first a hallucinated test case, then the wrong loading flag. Both were eliminated by specifying the exact 4 commands to run.

### Feature commits need an E2E verify grep

**Lesson**: When changing defaults or config values that E2E tests assert on (preset fields, provider names, output schemas), the commit should include verify.md updates. A simple grep for the old value across `test/e2e/**/*.verify.md` would catch these.

### Sandbox setup must match runner scope

**Lesson**: If a runner.md references a package or resource, the scenario.yml setup must ensure it exists in the sandbox. The `copy-fixtures` step only copies the declared fixtures directory -- cross-package references need explicit setup steps.

### Boolean CLI options should never have aliases matching the flag name

**Lesson**: ace-support-cli generates `--[no-]flag-name` automatically from `type: :boolean`. Adding `aliases: ["--flag-name"]` creates a conflict in Ruby's OptionParser that silently breaks the `--no-` negation. All boolean options should omit aliases entirely (unless adding a short form like `-t`).

## Action Items

### Start

- **Specify exact commands in runner.md**: New and updated runner.md files should list literal commands with arguments, not indirect "use what you learned" instructions. Template: numbered list of `command` -> `artifact` mappings.
- **Add verify-grep to feature commit checklist**: When changing config defaults or output schemas, grep `test/e2e/**/*.verify.md` for the old value before pushing.
- **Lint boolean option aliases**: Add a check (in ace-lint or a test) that boolean CLI options don't have aliases matching their auto-generated `--flag-name` form.

### Stop

- **Relying on LLM runner creativity for command selection**: The runner is an executor, not a decision-maker. Ambiguity in runner.md is a test design bug, not a feature.
- **Assuming sandbox inherits monorepo state**: Each test's sandbox is isolated. Cross-package references need explicit setup.

### Continue

- **Category-first analysis before fixes**: The runner-error / test-spec-error / code-issue taxonomy works well and should remain the hard gate.
- **Scenario-scoped reruns during iteration**: Cost-effective and fast. Full suite runs only as final checkpoint.
- **Treating E2E verify.md as a contract**: When verify expectations diverge from implementation, the verify is the spec -- update the code or update the spec, but document which.
