---
id: 8pbiz3
title: /opt/homebrew Destroyed During E2E Test Suite
type: conversation-analysis
tags: []
created_at: "2026-02-12 12:38:58"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8pbiz3-homebrew-incident-e2e-safety.md
---
# Reflection: /opt/homebrew Destroyed During E2E Test Suite

**Date**: 2026-02-12
**Context**: Incident analysis and remediation after /opt/homebrew was cleaned during E2E test execution
**Author**: Claude Opus 4.6
**Type**: Conversation Analysis

## What Went Well

- E2E test suite architecture caught the damage quickly — later tests reported dyld errors, providing a clear timeline
- JSONL session logs provided comprehensive forensic data for incident reconstruction
- Existing hook infrastructure (enforce-wrapper-tools.rb) was well-designed and extensible, making remediation straightforward
- 92% of tests (124/135) still passed despite the incident, showing good sandbox isolation for most tests

## What Could Be Improved

- No system path protection existed before this incident — `--dangerously-skip-permissions` gave agents unrestricted filesystem access
- The E2E testing guide actively recommended binary renaming (`mv "$TOOL_PATH" "${TOOL_PATH}.disabled"`) which operates on system-wide paths
- Test case TC-002 (timestamp) used `rm -rf "$(echo "$PATH_ONLY" | cut -d/ -f1)"` — dynamic path deletion is inherently unsafe
- No pre-suite health check verifies system dependencies before spawning 10+ parallel agents
- The exact destructive command could not be identified in logs — better forensic logging needed

## Key Learnings

- `--dangerously-skip-permissions` + weak model (Haiku) + high parallelism (10) is a dangerous combination without guardrails
- Sandbox isolation must be enforced at the OS/hook level, not just by agent instructions — Haiku agents can and do improvise
- System path protection should be a default safety layer, not an afterthought
- The damage window was only 4 minutes (01:33-01:37 UTC) — destruction of system paths can happen very fast
- Agents reactively trying to `brew install` after the damage showed they were victims, not causes — the actual culprit left no clear trace

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Unrestricted Agent Access**: `--dangerously-skip-permissions` hardcoded as default for all E2E Claude tests
  - Occurrences: Every E2E test run (31 tests in incident suite)
  - Impact: Complete destruction of /opt/homebrew, breaking all Ruby-based CLI tools
  - Root Cause: No defense-in-depth — reliance on agent behavior alone for safety

- **No System Path Protection**: Zero deny-list for destructive operations on system directories
  - Occurrences: 1 (this incident, but latent risk in every prior run)
  - Impact: System-wide tool breakage requiring Homebrew reinstall
  - Root Cause: Hook infrastructure existed but only enforced git wrapper usage, not system safety

#### Medium Impact Issues

- **Unsafe Documentation Patterns**: Binary renaming guide in e2e-testing.g.md
  - Occurrences: Documented as recommended practice, confirmed used in at least 1 prior test
  - Impact: Normalizes operating on system-wide binaries during parallel test execution
  - Root Cause: Pattern developed for single-agent use, not validated for parallel safety

- **Dynamic Path Deletion**: `rm -rf "$(cmd | cut)"` pattern in timestamp TC-002
  - Occurrences: 1 test case
  - Impact: Low (sandbox-relative), but normalizes dangerous `rm -rf` on computed paths
  - Root Cause: Insufficient code review of E2E test case safety patterns

#### Low Impact Issues

- **Missing Forensic Trail**: Exact destructive command not found in JSONL logs
  - Occurrences: 1 (this investigation)
  - Impact: Cannot definitively identify root cause; can only address risk factors
  - Root Cause: Possible heredoc-embedded commands, agent crash, or concurrent process

### Improvement Proposals

#### Process Improvements

- Add system path protection as a mandatory hook for any project using `--dangerously-skip-permissions`
- Review all E2E test cases for `rm -rf` patterns; ensure all deletions target explicit sandbox paths
- Remove binary renaming from any documentation or guide

#### Tool Enhancements

- Add pre-suite health check to ace-test-e2e-runner (verify ruby, brew, ace tools before spawning agents)
- Consider adding agent-level command logging that captures full heredoc content
- Add `--protected-paths` flag to ace-test-e2e CLI for runtime path protection configuration

## Action Items

### Stop Doing

- Recommending binary renaming (`mv "$TOOL_PATH" "${TOOL_PATH}.disabled"`) in guides
- Using dynamic path computation in `rm -rf` commands in test cases

### Continue Doing

- Using `--dangerously-skip-permissions` for E2E speed (with deny-list hook protection)
- Running 10 parallel Haiku agents (speed is valuable, hooks provide safety)
- Comprehensive JSONL session logging (essential for forensics)

### Start Doing

- System path protection hooks as standard safety layer (implemented in this session)
- Auditing all E2E test cases for unsafe `rm` patterns before adding new tests
- Logging all blocked commands to `/tmp/system-path-protection.log` for forensic analysis
- Pre-suite environment health checks before large parallel test runs

## Technical Details

### Files Modified

| File | Change |
|---|---|
| `.claude/hooks/enforce-wrapper-tools.rb` | Added `check_system_path_protection()` as first-priority check |
| `.claude/hooks/wrapper-tools-config.json` | Added `system_path_protection` config section with blocked patterns |
| `ace-support-timestamp/.../TC-002-split-output-modes.tc.md` | Replaced dynamic `rm -rf` with explicit path cleanup |
| `ace-test-e2e-runner/handbook/guides/e2e-testing.g.md` | Removed binary renaming pattern, added safety warning |

### Hook Protection Patterns

Blocks: `rm`/`mv`/`chmod`/`chown` on `/opt/`, `/usr/local/`, `/Library/`; `brew uninstall/remove/cleanup/autoremove`; `sudo`

Tested with 15 scenarios (8 correctly blocked, 7 correctly allowed), including multiline heredoc content.

### Incident Timeline

| Time (UTC) | Event |
|---|---|
| 00:47-00:49 | Earlier E2E suite passes (16/16) — Homebrew intact |
| 01:33 | Suite 8pb2i7n begins (31 tests, 10 parallel, haiku) |
| 01:33-01:36 | ~40 sessions execute in parallel |
| ~01:36-01:37 | First dyld error (libgmp.10.dylib not found) |
| 01:38-01:39 | Agents reactively try `brew install gmp` |
| 01:40 | Suite report: 124/135 passed (92%) |

## Additional Context

- Suite report: `.cache/ace-test-e2e/8pb2i7n-final-report.md`
- E2E runner config: `.ace/e2e-runner/config.yml`
- Hook config: `.claude/hooks/wrapper-tools-config.json`
- Investigation plan: `.claude/plans/sorted-shimmying-marshmallow.md`
