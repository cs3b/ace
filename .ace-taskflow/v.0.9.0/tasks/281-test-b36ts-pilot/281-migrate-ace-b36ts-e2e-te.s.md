---
id: v.0.9.0+task.281
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Pilot: Migrate ace-b36ts E2E Tests to Tag/Goal Model

## Context

Task 280 defined a new E2E testing approach: tags, grouping, cost-tiers, and goal-based test cases. Before implementing the infrastructure (280.02–280.05), this pilot defines what the ideal E2E suite looks like for one package, validating that the 280 taxonomy works in practice.

**Why ace-b36ts?** Simple tool, strong unit coverage (276 tests, 1022 assertions), and existing E2E tests that expose the exact problem Task 280 aims to solve.

**The problem:** The current 4 scenarios / 11 TCs massively duplicate unit tests. They test format lengths, sortability, config display — all thoroughly covered by unit tests. Real E2E value (binary contract, shell pipe behavior, tool integration) is buried and diluted.

## Design Principles

This pilot adopts an **all-goal, runner/verifier split** approach:

1. **All goal-oriented** — No procedural steps, no hardcoded commands. Specs describe WHAT to achieve, not HOW.
2. **Runner/verifier split** — `.runner.md` gives the agent a goal and constraints; `.verify.md` inspects artifacts independently.
3. **Discovery-first** — The runner starts by exploring `--help` at every level. No flag names or subcommand syntax are prescribed.
4. **Artifact-based verification** — Runner writes outputs to `goal/{N}/` folders. Verifier reads those artifacts and renders a PASS/FAIL verdict.
5. **Loosely coupled** — If `--help` output changes and the tool still works, tests pass. If it changes and breaks behavior, tests fail naturally.

## Critical Analysis of Current E2E Tests

| Current Scenario | TCs | Verdict |
|-----------------|-----|---------|
| TS-B36TS-001 Core Roundtrip | 3 | **Replace** — format lengths + sortability + decode formats all unit-tested |
| TS-B36TS-002 Config & Defaults | 3 | **Replace** — config display + year-zero unit-tested. Error handling has E2E value → absorb |
| TS-B36TS-003 Split Format | 3 | **Replace** — split levels unit-tested. Output modes (JSON, path-only) → absorb |
| TS-B36TS-004 CLI Integration | 3 | **Replace** — help/version trivial. Pipeline → absorb into new roundtrip |

## New Design: 1 Scenario, 8 Goals

All goals live in a single scenario (`TS-B36TS-001-goal-pilot`) with the runner/verifier split.

### Goal 1 — Help Survey
- **Runner**: Explore `ace-b36ts --help` at every level. Summarize subcommands, flags, and note anything unclear.
- **Verifier**: File exists in `goal/1/`, contains substantive observations about the tool, mentions subcommands.

### Goal 2 — Encode Today's Date
- **Runner**: Encode today's date using the tool. Create a file whose filename IS the encoded token.
- **Verifier**: Exactly one file in `goal/2/`, filename is valid base36 (lowercase alphanumeric, 2–8 chars).

### Goal 3 — Decode Token
- **Runner**: Decode the token `70000`. Save a file named `70000` with the decoded result as content.
- **Verifier**: File `goal/3/70000` exists, content is a valid, plausible date/timestamp.

### Goal 4 — Error Behavior
- **Runner**: Feed the tool clearly invalid input (nonsense strings, wrong subcommands). For each, capture the exit code, stdout, and stderr into separate files in `goal/4/`.
- **Verifier**: At least 2 error-case files exist. Each shows: non-zero exit code, error message on stderr, stdout is empty or clean.
- **E2E value**: Tests the full exception→message→exit-code path through the binary wrapper — invisible to unit tests that call Ruby methods.

### Goal 5 — Output Routing
- **Runner**: Run the same encode operation in different verbosity modes (discover modes via `--help`). For each mode, capture stdout and stderr into separate files in `goal/5/`.
- **Verifier**: At least 2 mode pairs exist. Quiet mode: stdout contains only the token. Verbose/default: stderr has additional content. Stream separation is correct.
- **E2E value**: fd routing only breaks in real shell execution — unit tests don't exercise the binary's output stream wiring.

### Goal 6 — Structured Output Integration
- **Runner**: Discover the tool's structured output formats via `--help`. Use one format's output directly as input to a real downstream tool (e.g., `mkdir` from path output, `jq` on JSON). Save evidence in `goal/6/`.
- **Verifier**: At least one integration artifact exists proving a downstream tool consumed the output successfully. No manual string munging was required.
- **E2E value**: Proves output is machine-usable by real tools, not just correctly formatted strings.

### Goal 7 — Roundtrip Pipeline
- **Runner**: Encode a known date, then pipe/feed the result into decode — all through shell pipeline or command substitution. Save original date, encoded token, and decoded result in `goal/7/`.
- **Verifier**: File exists with all three values. Decoded result contains the original date. Token is valid base36. No trailing whitespace corruption.
- **E2E value**: Tests pipe behavior, trailing whitespace, and command substitution — things that only break in real shell execution.

### Goal 8 — Batch Sort Order
- **Runner**: Encode at least 4 timestamps from different dates (not in chronological order). Save two files in `goal/8/`: one with IDs in encode order, one lexicographically sorted.
- **Verifier**: Both files exist with at least 4 IDs. Sorted order matches chronological order of original dates.
- **E2E value**: Sortability is a key design property of b36ts tokens — this tests it through the actual binary output, not Ruby method return values.

### Tag/Tier Summary

- **smoke**: All 8 goals (single scenario, smoke cost-tier)
- **happy-path**: Goals 1–3, 7
- **error-path**: Goal 4
- **use-case:b36ts**: All 8 goals
- **pilot**: All 8 goals
- **mode**: goal (all goals are goal-mode, no procedural TCs)

## Acceptance Criteria

- [ ] 1 scenario directory with `scenario.yml` (tags, cost-tier, sandbox-layout, e2e-justification)
- [ ] 8 runner.md files with Goal + Workspace + Constraints (no Steps, no hardcoded commands)
- [ ] 8 verify.md files with Expectations + Verdict format (artifact-based, no access to runner reasoning)
- [ ] `scenario.yml` defines `sandbox-layout` showing `goal/` tree structure for all 8 goals
- [ ] No bash commands, flag names, or expected outputs hardcoded in any runner or verifier file
- [ ] All goals justify E2E value that unit tests cannot provide
- [ ] Goals 4–8 restore all lost E2E coverage from the original 7 procedural TCs

## Scope

**In scope:** Scenario and goal definitions (specs only) in the task's e2e/ subdirectory.

**Out of scope:** Code changes to the test runner, replacing the current live E2E tests, implementing tag filtering infrastructure.

## Deliverables

All files in `e2e/` subdirectory of this task folder:

```
e2e/
└── TS-B36TS-001-goal-pilot/
    ├── scenario.yml
    ├── goal-1-help-survey.runner.md
    ├── goal-1-help-survey.verify.md
    ├── goal-2-encode-today.runner.md
    ├── goal-2-encode-today.verify.md
    ├── goal-3-decode-token.runner.md
    ├── goal-3-decode-token.verify.md
    ├── goal-4-error-behavior.runner.md
    ├── goal-4-error-behavior.verify.md
    ├── goal-5-output-routing.runner.md
    ├── goal-5-output-routing.verify.md
    ├── goal-6-structured-output.runner.md
    ├── goal-6-structured-output.verify.md
    ├── goal-7-roundtrip-pipeline.runner.md
    ├── goal-7-roundtrip-pipeline.verify.md
    ├── goal-8-batch-sort.runner.md
    └── goal-8-batch-sort.verify.md
```
