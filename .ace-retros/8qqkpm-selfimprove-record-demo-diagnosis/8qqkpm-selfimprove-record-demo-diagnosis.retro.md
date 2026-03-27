---
id: 8qqkpm
title: selfimprove-record-demo-diagnosis
type: self-improvement
tags: [process-fix, demo, non-blocking]
created_at: "2026-03-27 13:48:28"
status: active
---

# selfimprove-record-demo-diagnosis

## Root Cause Analysis

**What happened**: Assignment 8qqgg2, step 145 (record-demo) failed with `agg` error: "no faces matching font families CaskaydiaMono Nerd Font." The driver agent reported the font mismatch in its step report but marked the step as complete without attempting repair.

**Why it happened**: Two root causes:
1. **Wrong default config** (Assumed context): `ace-demo/.ace-defaults/demo/config.yml` had `agg_font_family: CaskaydiaMono Nerd Font` but the spike task (r6b.0) validated `Hack Nerd Font Mono` as the working font. The config was never updated to match.
2. **Ambiguous instructions** (Ambiguous instructions): The step said "This step is non-blocking: if recording fails, report the failure but do not block subsequent steps." The agent read this as permission to skip on first failure instead of diagnosing the fixable config issue.

## Process Fix Applied

1. **Config fix** (`ace-demo/.ace-defaults/demo/config.yml`): Changed `agg_font_family` from `CaskaydiaMono Nerd Font` to `Hack Nerd Font Mono`
2. **Step instructions** (`ace-assign/.ace-defaults/assign/presets/work-on-task.yml`): Rewrote the non-blocking policy with a 5-step diagnosis checklist: read error, check config vs available fonts, check spike findings, fix and retry, only then skip
3. **Step catalog** (`ace-assign/.ace-defaults/assign/catalog/steps/record-demo.step.yml`): Added `decision_notes.non_blocking_policy` clarifying that non-blocking means diagnose-then-skip, not skip-on-first-failure

## Immediate Fix

- Fixed the config, re-recorded the demo, and attached GIF to PR #269
- Released ace-demo v0.22.4 (font fix) and ace-assign v0.38.3 (step instructions)

## Expected Impact

Future record-demo failures from config/environment issues will be diagnosed and fixed inline rather than silently skipped. The diagnosis checklist gives agents a concrete procedure to follow before declaring a step unfixable.

