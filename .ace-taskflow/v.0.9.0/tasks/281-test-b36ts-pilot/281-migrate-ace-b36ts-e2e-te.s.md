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

## Critical Analysis of Current E2E Tests

| Current Scenario | TCs | Verdict |
|-----------------|-----|---------|
| TS-B36TS-001 Core Roundtrip | 3 | **Replace** — format lengths + sortability + decode formats all unit-tested |
| TS-B36TS-002 Config & Defaults | 3 | **Replace** — config display + year-zero unit-tested. Error handling has E2E value → absorb |
| TS-B36TS-003 Split Format | 3 | **Replace** — split levels unit-tested. Output modes (JSON, path-only) → absorb |
| TS-B36TS-004 CLI Integration | 3 | **Replace** — help/version trivial. Pipeline → absorb into new roundtrip |

**Kept E2E concerns** (reframed into new scenarios):
- Binary execution through real shell (not Ruby method invocation)
- stdout/stderr fd routing (quiet/verbose/default modes)
- Error UX (exception → stderr message → exit code path)
- Machine-parseable output consumed by real tools (jq, mkdir)
- Shell pipe behavior (xargs, command substitution, no trailing whitespace)

## New Design: 3 Scenarios, 7 TCs

### TS-B36TS-001 — CLI Binary Contract (smoke)

**E2E justification:** Unit tests call Ruby methods. This tests the actual binary through a shell — shebang, gem loading, exit codes, fd routing.

| TC | Title | Mode | Tags |
|----|-------|------|------|
| TC-001 | Binary smoke: encode, decode, version | procedural | smoke |
| TC-002 | Output routing: quiet vs verbose vs default | procedural | happy-path |
| TC-003 | Error UX: exit codes and stderr messages | procedural | happy-path |

### TS-B36TS-002 — Machine-Parseable Output Integration (smoke)

**E2E justification:** Tests that output is actually usable by downstream tools (jq, mkdir) in a real shell — not just that Ruby returns a string.

| TC | Title | Mode | Tags |
|----|-------|------|------|
| TC-001 | Split path usable for filesystem operations | **goal** | happy-path |
| TC-002 | JSON output consumable by jq | procedural | happy-path |

### TS-B36TS-003 — Real Workflow Pipelines (standard)

**E2E justification:** Multi-command pipelines, xargs piping, batch processing — things that only break in real shell execution.

| TC | Title | Mode | Tags |
|----|-------|------|------|
| TC-001 | Encode-decode roundtrip pipeline through shell | procedural | smoke, happy-path |
| TC-002 | Batch timestamp processing with sort verification | **goal** | happy-path |

### Tag/Tier Summary

- **smoke**: TC-001×3 scenarios + TS-003/TC-001 = 4 TCs reachable via `--tags smoke`
- **happy-path**: All 7 TCs
- **use-case:b36ts**: All 7 (inherited from scenarios)
- **cost-tier smoke**: TS-001, TS-002 (5 TCs)
- **cost-tier standard**: TS-003 (2 TCs)
- **Goal-mode**: 2 TCs (TS-002/TC-001 filesystem, TS-003/TC-002 batch sort)

## Acceptance Criteria

- [ ] 3 new scenario directories with scenario.yml files (tags, cost-tier, e2e-justification)
- [ ] 5 procedural TCs with Steps/Expected sections
- [ ] 2 goal-mode TCs with Objective/Success Criteria (no Steps section)
- [ ] All TCs justify E2E value that unit tests cannot provide
- [ ] Tag coverage: `smoke` selects 4 TCs, `happy-path` selects all 7
- [ ] Task spec references Task 280 as the framework being validated

## Scope

**In scope:** Scenario and TC definitions (specs only) in the task's e2e/ subdirectory.

**Out of scope:** Code changes to the test runner, replacing the current live E2E tests, implementing tag filtering infrastructure.

## Deliverables

All files in `e2e/` subdirectory of this task folder:

```
e2e/
├── TS-B36TS-001-cli-binary-contract/
│   ├── scenario.yml
│   ├── TC-001-binary-smoke.tc.md
│   ├── TC-002-output-routing.tc.md
│   └── TC-003-error-ux.tc.md
├── TS-B36TS-002-machine-parseable-output/
│   ├── scenario.yml
│   ├── TC-001-split-path-filesystem.tc.md      (goal-mode)
│   └── TC-002-json-output-jq.tc.md
└── TS-B36TS-003-real-workflow-pipelines/
    ├── scenario.yml
    ├── TC-001-roundtrip-pipeline.tc.md
    └── TC-002-batch-sort-verification.tc.md    (goal-mode)
```
