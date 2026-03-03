---
id: 8p6ylo
title: E2E Test Module Timing Analysis (Round 2)
type: standard
tags: []
created_at: '2026-02-07 23:04:04'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8p6ylo-e2e-timing-analysis-round2.md"
---

# Reflection: E2E Test Module Timing Analysis (Round 2)

**Date**: 2026-02-07
**Context**: Empirical timing analysis of ace-lint E2E suite (8 tests) to refine the cost model from Round 1
**Author**: Claude
**Type**: Standard

## What Went Well

- All 8 ace-lint E2E tests pass reliably, providing solid empirical data
- The original ~28s/block model was a reasonable starting point that kept us safe
- Block consolidation guidance from Round 1 remains valid and important

## What Could Be Improved

- The original model (block_count × 28s) was too simplistic — it doesn't account for workflow overhead or agent block-merging behavior
- Block count alone is a poor predictor; block complexity matters more
- Need a two-component model: fixed overhead + variable test content

## Key Learnings

### Empirical Data: ace-lint E2E Suite (Full Run)

| Test | .mt.md Blocks | Time (s) | s/block | Cases |
|------|--------------|----------|---------|-------|
| MT-LINT-001 | 16 | 163.4 | 10.2 | 5 |
| MT-LINT-002 | 11 | 187.6 | 17.1 | 5 |
| MT-LINT-003 | 9 | 143.3 | 15.9 | 2 |
| MT-LINT-004 | 7 | 135.8 | 19.4 | 5 |
| MT-LINT-005 | 12 | 206.2 | 17.2 | 4 |
| MT-LINT-006 | 14 | 269.3 | 19.2 | 3 |
| MT-LINT-007 | 3 | 136.6 | 45.5 | 3 |
| MT-LINT-008 | 13 | 261.1 | 20.1 | 4 |

### Why block_count × 28s Fails

The s/block ratio ranges from 10s to 45s. Three factors explain the variance:

1. **Workflow overhead is constant (~90s)**: The runner performs ~4 mandatory workflow steps (find test, isolation check, sandbox verify, write reports) regardless of test size. This fixed cost dominates small tests.
2. **The agent merges blocks**: Sequential, related bash blocks are often executed in a single LLM round-trip. A test with 7 blocks might only take ~2 effective LLM turns.
3. **Block complexity varies**: A block running 3 `ace-lint` invocations takes longer wall-clock than a block doing `cat > file`.

### The Two-Component Model

```
total_time ≈ 90s (overhead) + (mt_md_blocks / 2.5) × 25s
```

Where:
- **90s** = fixed workflow overhead (find, isolate, sandbox, report)
- **blocks / 2.5** = effective LLM turns (agent groups ~2-3 blocks per turn)
- **25s** = cost per effective LLM round-trip

### Validation Against Actual Data

| Test | Actual (s) | Predicted (s) | Delta |
|------|-----------|---------------|-------|
| MT-LINT-001 (16 blocks) | 163 | 250 | +87 (agent heavily merged) |
| MT-LINT-002 (11 blocks) | 188 | 200 | +12 |
| MT-LINT-003 (9 blocks) | 143 | 180 | +37 |
| MT-LINT-004 (7 blocks) | 136 | 160 | +24 |
| MT-LINT-005 (12 blocks) | 206 | 210 | +4 |
| MT-LINT-006 (14 blocks) | 269 | 230 | -39 (complex blocks) |
| MT-LINT-007 (3 blocks) | 137 | 120 | -17 |
| MT-LINT-008 (13 blocks) | 261 | 220 | -41 (complex blocks) |

The model is approximate — complex tests with heavy tool invocations (ace-lint, ace-doctor) skew higher. Use it as a planning heuristic, not a guarantee.

### Practical Budget for 3-Minute (180s) Target

- **Overhead**: ~90s (unavoidable)
- **Available for test content**: 90s (target) to 150s (max at 240s)
- **Effective turns budget**: 3-4 turns (target), 6 turns (max)
- **Block budget**: 8-12 .mt.md blocks (target), ~14 blocks (max at 240s)
- **Danger zone**: 14+ blocks, or tests with many heavy tool invocations

### Key Caveats

- Block complexity matters more than block count — a block with 3 `ace-lint` calls adds more wall-clock time than 3 blocks with `echo` commands
- The agent's merging behavior is non-deterministic; simple sequential blocks merge more aggressively
- Tests near the boundary (12-14 blocks) should be validated with a test run

## Action Items

### Stop Doing

- Using the simple `block_count × 28s` model for time estimation
- Treating all bash blocks as equal cost

### Continue Doing

- Merging assertions into execution blocks (still reduces both block count AND effective turns)
- Pre-flight `grep -c '```bash'` check before finalizing .mt.md files
- Keeping tests under 14 .mt.md blocks

### Start Doing

- Using the two-component formula: `total ≈ 90s + (blocks / 2.5) × 25s`
- Weighting complex blocks (ace-lint, ace-doctor invocations) higher when estimating
- Targeting 8-12 blocks for comfortable 180s execution, hard max at ~14 blocks

## Technical Details

### Formula Summary

```
total_time ≈ 90 + (block_count / 2.5) × 25

Where:
  90      = workflow overhead (seconds)
  2.5     = average blocks per LLM turn (agent merging)
  25      = seconds per LLM round-trip
```

### Quick Reference Table

| .mt.md Blocks | Estimated Time | Assessment |
|--------------|---------------|------------|
| 3-6 | 120-150s | Comfortable |
| 7-10 | 160-190s | Target zone |
| 11-14 | 200-230s | Watch zone |
| 15+ | 240s+ | Likely exceeds timeout |

Note: Add 20-40s for tests with multiple heavy tool invocations per block.

## Additional Context

- Prior retro: `8p6xkk-e2e-test-module-sizing.md` (original ~28s/block model)
- Data source: Full ace-lint E2E suite run (8/8 tests passing)
- Timeout setting: 300s per test module