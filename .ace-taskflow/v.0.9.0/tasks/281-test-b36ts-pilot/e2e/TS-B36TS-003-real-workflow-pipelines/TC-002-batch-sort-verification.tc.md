---
tc-id: TC-002
title: Batch Timestamp Processing with Sort Verification
mode: goal
tags: [happy-path]
---

## Objective

Demonstrate that ace-b36ts IDs maintain chronological sort order when processed in batch — encoding multiple timestamps and verifying that lexicographic sorting of the IDs matches the original chronological order.

## Available Tools

- `ace-b36ts` — the CLI binary under test
- Standard shell utilities: `sort`, `echo`, `diff`, `printf`
- Shell features: loops, arrays, command substitution, pipes

## Success Criteria

1. Encode at least 4 timestamps spanning different dates/times into ace-b36ts IDs
2. The timestamps must not be provided in chronological order (shuffle them)
3. Sort the resulting IDs lexicographically (standard `sort`)
4. Verify that the sorted ID order matches chronological order of the original timestamps
5. All operations must use the ace-b36ts binary (not Ruby method calls)
6. The verification must be automated (not visual inspection) — use diff, comparison, or exit codes

## Hints

- Use the same format precision for all timestamps (e.g., default 2sec or day format)
- IDs in the same format are designed to be lexicographically sortable
- Consider encoding timestamps from different days to make sort differences obvious
- `sort` on the IDs should produce the same order as sorting the original timestamps chronologically
