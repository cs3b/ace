---
test-id: TS-B36TS-001
title: "ace-b36ts Goal-Based E2E Pilot"
package: ace-b36ts
runner-provider: claude:opus
verifier-provider: claude:opus
timestamp: 2026-02-24T00:04:24Z
tcs-passed: 6
tcs-failed: 2
tcs-total: 8
score: 0.75
verdict: partial
passed:
  - "Goal 1 — Help Survey"
  - "Goal 2 — Encode Today"
  - "Goal 4 — Error Behavior"
  - "Goal 5 — Output Routing"
  - "Goal 6 — Structured Output Integration"
  - "Goal 8 — Batch Sort Order"
failed:
  - tc: "TC-003 — Decode Token"
    reason: "Token 70000 is invalid for ace-b36ts (unsupported length/format)"
    category: test-spec-error
  - tc: "TC-007 — Roundtrip Pipeline"
    reason: "Decode returns UTC instead of local timezone (14:30 → 13:30 UTC)"
    category: tool-bug
---

# E2E Report: ace-b36ts Goal-Based Pilot

**Score: 6/8 (75%)**  |  Runner: claude:opus  |  Verifier: claude:opus  |  Date: 2026-02-24

## Goal Results

### Goal 1 — Help Survey
- **Verdict**: PASS
- **Evidence**: Five files exist in `results/tc/01/`: `help.txt`, `encode-help.txt`, `decode-help.txt`, `config-help.txt`, and `OBSERVATIONS.md`. The `OBSERVATIONS.md` file contains 80+ lines of substantive content referencing all three subcommands (encode, decode, config), their flags, and includes original observations such as "Format Auto-Detection: Decode auto-detects ID format based on length/content" and "Potential Areas for Clarification" — clearly beyond raw `--help` copy-paste.

### Goal 2 — Encode Today
- **Verdict**: PASS
- **Evidence**: Exactly one file exists in `results/tc/02/`: `8pmz62`. The filename is 6 characters long, all lowercase alphanumeric (`[0-9a-z]`), consistent with a valid base36 token in the 2–8 character range.

### Goal 3 — Decode Token
- **Verdict**: FAIL
- **Evidence**: No file named `70000` with decoded date content exists. `results/tc/03/70000.stdout` is empty. `results/tc/03/70000.exit` contains `1` (non-zero). `results/tc/03/70000.stderr` contains: `"Error: Cannot detect format for compact ID: 70000 (unsupported length or invalid characters)"`. The decode failed — the token `70000` is invalid for this tool, and no valid date/timestamp was produced.

### Goal 4 — Error Behavior
- **Verdict**: PASS
- **Evidence**: Three distinct error cases captured in `results/tc/04/`:
  - `invalid-subcommand`: exit=`1`, stderr lists valid commands, stdout empty.
  - `decode-no-arg`: exit=`1`, stderr=`ERROR: "ace-b36ts decode" was called with no arguments`, stdout empty.
  - `invalid-format`: exit=`1`, stderr=`Error: Invalid format: invalid_format. Must be one of 2sec, month, week, day, 40min, 50ms, ms`, stdout empty.
  All three show non-zero exit codes, error messages on stderr only, and clean stdout.

### Goal 5 — Output Routing
- **Verdict**: PASS
- **Evidence**: Four mode pairs exist in `results/tc/05/` (default, quiet, verbose, debug). Quiet mode: stdout=`8pmz6b` (clean token), stderr=empty. Verbose mode: stdout=`8pmz6b`, stderr=`Config: args=now b36ts.alphabet=... verbose=true` (additional metadata). Streams are correctly separated — stdout contains only the token in all modes; stderr contains logging only in verbose/debug modes. All exit codes are `0`.

### Goal 6 — Structured Output Integration
- **Verdict**: PASS
- **Evidence**: Two integration artifacts exist:
  1. Directory structure `results/tc/06/test-structure/8d/4/m/i00/` was created from split output path `8d/4/m/i00` (visible in `split-output.stdout`).
  2. `results/tc/06/jq-integration-result.json` contains `["8dmi0000","8dmi0001","8dmi0002"]` — valid JSON parsed by jq from `json-array.stdout` which contains the same array. Both downstream tools (mkdir, jq) succeeded with non-empty, valid output.

### Goal 7 — Roundtrip Pipeline
- **Verdict**: FAIL
- **Evidence**: `results/tc/07/roundtrip-result.txt` contains all three values: Original=`2024-06-15 14:30:00`, Encoded=`85ek90` (valid base36), Decoded=`2024-06-15 13:30:00 UTC`. However, the roundtrip does **not** match: the original time is `14:30:00` but the decoded result is `13:30:00 UTC` — a 1-hour discrepancy. The decoded result does not preserve the original input time. The runner's own notes acknowledge "timezone conversion noted" but the criterion requires "The decoded result contains the original date (the roundtrip preserved the input)," which is not satisfied (`14:30` ≠ `13:30`).

### Goal 8 — Batch Sort Order
- **Verdict**: PASS
- **Evidence**: Two files exist in `results/tc/08/`. `encode-order.txt` lists 5 date/token pairs. `sorted-order.txt` lists the same 5 pairs in lexicographic token order:
  - `6tjk90` (2020-06-20) < `7mbp4i` (2022-11-12) < `8cef00` (2025-01-15) < `8vogi0` (2026-08-25) < `a24dvi` (2030-03-05)
  
  Lexicographic order matches chronological order perfectly. All tokens are valid base36 (`[0-9a-z]`), 6 characters each.

---



## Summary

| Metric | Value |
|--------|-------|
| Passed | 6 |
| Failed | 2 |
| Total  | 8 |
| Score  | 75% |

## Failed Goals

| Goal | Issue | Category |
|------|-------|----------|
| Goal 3 — Decode Token | Token `70000` is invalid for ace-b36ts (unsupported length/format) | Test spec error |
| Goal 7 — Roundtrip Pipeline | Decode returns UTC instead of local timezone (14:30 → 13:30 UTC) | Tool bug |
