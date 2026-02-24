# Goal 8 — Batch Sort Order

## Goal

Encode at least 4 timestamps from different dates (chosen deliberately out of chronological order). Save two files: one listing the encoded IDs in the order they were encoded, and one listing them in lexicographic (sorted) order.

## Workspace

Save output to `results/tc/08/`. Create two files:
- One file with the IDs in encode order (alongside their original dates for reference).
- One file with the IDs in lexicographic sort order (alongside their original dates).

## Constraints

- Using the encode operation you've already exercised in earlier goals, encode each date.
- Choose at least 4 dates that are NOT in chronological order when encoded (e.g., encode 2025, then 2020, then 2030, then 2022).
- Do not fabricate tokens — all encoded values must come from actual tool execution.
- The lexicographic sort must use a standard sort tool (e.g., `sort`) — do not manually arrange the output.
