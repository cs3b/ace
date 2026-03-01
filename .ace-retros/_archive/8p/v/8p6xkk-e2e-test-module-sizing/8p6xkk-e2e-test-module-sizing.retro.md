---
id: 8p6xkk
title: Writing Performant E2E Test Modules
type: conversation-analysis
tags: []
created_at: "2026-02-07 22:22:50"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8p6xkk-e2e-test-module-sizing.md
---
# Reflection: Writing Performant E2E Test Modules

**Date**: 2026-02-07
**Context**: Optimizing ace-lint E2E test timing — tests were timing out at 300s due to oversized modules
**Author**: claude-opus-4.6
**Type**: Conversation Analysis

## What Went Well

- Systematic diagnosis: counted bash blocks per file, correlated with observed durations, found clear ~28s/block pattern
- Two-phase approach worked: first split by test cases (structural), then consolidate blocks (density)
- Deduplication identified during splits — 5 redundant test cases removed across files
- The new 8-file layout provides better parallelism (2 waves instead of bottlenecked single tests)

## What Could Be Improved

- The original tests were written without awareness of the bash-block-to-time cost model
- Initial split (v0.15.9) only addressed case count, not block density — MT-LINT-002 still timed out with 5 cases but 21 blocks
- MT-LINT-007 (only 3 cases, 10 blocks) still timed out — showing that "fewer cases" isn't sufficient; block count is the real constraint
- Required 3 release iterations (v0.15.9, v0.15.10, v0.15.11) to get all tests passing

## Key Learnings

### The Fundamental Constraint: Bash Blocks, Not Test Cases

Each `\`\`\`bash` block in an `.mt.md` file costs one LLM round-trip: ~15-30s (thinking + execution). The total test duration is roughly `block_count x avg_block_time`. Test case count is a proxy but not the true driver.

### The Budget Rule

With a 300s timeout and ~28s average per block:
- **Safe limit: 10 bash blocks per module** (~280s, 7% margin)
- **Comfortable: 7-8 blocks** (~200-225s, 25-33% margin)
- **Ideal: 5-6 blocks** (~150-170s, 43-50% margin)

### Block Density Varies by Test Type

Not all test cases cost the same:
- **Simple check** (lint file, verify exit code): 1 block
- **Multi-step verification** (run tool, extract path, verify 3 things): 1-4 blocks depending on how written
- **Config + run** (create YAML, then lint): 2 blocks if separate, 1 if merged
- **Heavy tool calls** (ace-lint with Ruby startup ~3-5s each): higher wall-clock per block

### Consolidation Patterns That Work

| Pattern | Before | After | Savings |
|---------|--------|-------|---------|
| Multiple jq queries on same file | 4 blocks | 1 block | 3 blocks |
| Run command + verify exit code | 2 blocks | 1 block | 1 block |
| Create config + run tool | 2 blocks | 1 block | 1 block |
| Run tool + verify output + verify file | 3 blocks | 1 block | 2 blocks |
| No-op cleanup (commented out) | 1 block | 0 blocks | 1 block |

### Key Insight: Write Verification Inline

The biggest waste is separating "do thing" from "check thing". A verification step that just runs `grep` or `test -f` on a variable from the previous block should always be merged into that block. The LLM doesn't need a separate round-trip to run `echo "$OUTPUT" | grep -q "PASS"`.

## Action Items

### Stop Doing

- Writing one bash block per "step" — group related commands that share variables
- Counting test cases as a sizing proxy — count bash blocks instead
- Creating separate blocks for simple assertions (grep, test -f, exit code checks)
- Including commented-out cleanup blocks (they still cost a round-trip)

### Continue Doing

- Separate Environment Setup and Test Data blocks (they contain no tool calls, and clarity matters)
- Using `echo "=== Section ==="` markers to keep merged blocks readable
- Keeping test cases as separate conceptual units (headers, objectives, expected)

### Start Doing

- **Pre-flight block count**: Before finalizing any `.mt.md` file, count bash blocks with `grep -c '\`\`\`bash'` — target max 10
- **Merge verification into execution**: Always put assertions in the same block as the command they verify
- **Combine related tool calls**: If two `ace-lint` calls test variations of the same feature, put them in one block with echo separators
- **Document the budget**: Add a comment in `.mt.md` templates noting the 10-block guideline

## Technical Details

### Observed Timing Data (ace-lint E2E, claude:opus provider)

| Test | Blocks (before) | Blocks (after) | Duration (before) | Est. Duration (after) |
|------|-----------------|----------------|--------------------|-----------------------|
| MT-LINT-001 | 16 | 16 | 187s | 187s (no change needed) |
| MT-LINT-002 | 21 | 11 | 300s TIMEOUT | ~170s |
| MT-LINT-003 | 9 | 9 | 143s | 143s (no change needed) |
| MT-LINT-004 | 17 | 7 | 280s | ~196s |
| MT-LINT-005 | 12 | 12 | 128s | 128s (no change needed) |
| MT-LINT-006 | 14 | 14 | 133s | 133s (new file) |
| MT-LINT-007 | 10 | 7 | 300s TIMEOUT | ~196s |
| MT-LINT-008 | 13 | 13 | 108s | 108s (new file) |

### Sizing Guideline for New E2E Tests

```
Target: 3 minutes (180s) per module
Budget: 180s / 28s per block ≈ 6 blocks
Structure:
  1 block  - Environment Setup
  1 block  - Test Data
  3-4 blocks - Test Cases (merge assertions inline)
  ─────────
  5-6 blocks total = ~150-170s = safe
```

### Template for Block-Efficient Test Cases

```markdown
### TC-001: Feature Under Test

**Steps:**
1. Execute and verify
   \`\`\`bash
   # Setup specific to this case
   cp "$TEST_DIR/source.rb" "$TEST_DIR/copy.rb"
   # Execute
   OUTPUT=$(ace-lint lint --fix "$TEST_DIR/copy.rb" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   # Verify — all in same block
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: exit code" || echo "FAIL: exit code"
   echo "$OUTPUT" | grep -q "fixed" && echo "PASS: fixed" || echo "FAIL: not fixed"
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //')
   test -f "$REPORT_DIR/fixed.md" && echo "PASS: fixed.md" || echo "FAIL: no fixed.md"
   \`\`\`
```

## Additional Context

- Task 255: ace-e2e-test command implementation
- Releases: ace-lint v0.15.9 (splits), v0.15.10 (block consolidation), v0.15.11 (MT-LINT-004 further consolidation)
- The 300s timeout is set in ace-test-e2e-runner and applies per test module
