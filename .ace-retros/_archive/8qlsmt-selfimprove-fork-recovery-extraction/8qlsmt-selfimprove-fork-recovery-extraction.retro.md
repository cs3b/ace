---
id: 8qlsmt
title: selfimprove-fork-recovery-extraction
type: self-improvement
tags: [process-fix, ace-assign, workflow]
created_at: "2026-03-22 19:05:22"
status: active
---

# selfimprove-fork-recovery-extraction

## Root Cause Analysis

**What happened**: During t.pm3 assignment drive, the fork crash recovery for step 020.04 succeeded but used imprecise instructions — vague report references and compressed step body. The recovery protocol was embedded inline in `drive.wf.md` (lines 335-450, ~120 lines) making it hard to reference, test, or improve independently.

**Why it happened**: Ambiguous instructions + assumed context. The drive.wf.md recovery example used semantic references ("read the plan-task report") instead of explicit file paths, and said "complete remaining implementation" instead of copying the original step's full instruction body. The driver agent followed the example literally.

**Root cause category**: Ambiguous instructions, missing example of correct behavior.

## Process Fix Applied

Extracted fork recovery into a standalone workflow and skill:

- **Created**: `ace-assign/handbook/workflow-instructions/assign/recover-fork.wf.md` — standalone recovery workflow with 3 scenarios and precise "Recovery Step Construction Rules"
- **Created**: `ace-assign/handbook/skills/as-assign-recover-fork/SKILL.md` — skill wiring
- **Updated**: `drive.wf.md` — replaced 120 lines of inline recovery with compact delegation to `wfi://assign/recover-fork`
- **Synced**: Projected new skill to all 5 providers

### Key improvements in the new workflow

1. **Recovery-onboard template**: Lists report files using `ls ${REPORT_DIR}/${FORK_ROOT}.*` and builds instructions with explicit paths
2. **Continue-work template**: Reads the original failed step file and extracts the instruction body verbatim via `sed`
3. **Step 4 (Reset downstream)**: New section — if prior incorrect recovery ran downstream steps, reset them to pending and delete their reports

## Expected Impact

- Recovery agents will receive explicit report paths instead of semantic guesses
- Continue-work steps will carry the full original execution guidance (principles, conventions, done criteria)
- The recovery workflow is independently referenceable via `wfi://assign/recover-fork` or `/as-assign-recover-fork`
- `drive.wf.md` is 120 lines shorter and delegates recovery cleanly

## Source Retro

Consumed retro: `8qlsgy` (t-pm3-drive-recovery-precision)

