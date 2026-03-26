---
id: 8qphrf
title: selfimprove-auto-demo-recording
type: self-improvement
tags: [process-fix]
created_at: "2026-03-26 11:50:28"
status: active
---

# selfimprove-auto-demo-recording

## Root Cause

**What happened**: PR #265 (t.10g batch) included a `## 🎮 Demo` section with text-only runnable commands. Reviewers had to manually run demo commands instead of seeing a recorded GIF.

**Why**: The `ace-demo record --pr` pipeline was fully built, but no `record-demo` step existed in the assignment step catalog or `work-on-task` preset.

**Category**: Missing automation — capability existed but wasn't wired into the workflow.

## Process Fix Applied

Added `record-demo` as step 145 in the assignment workflow:
- New step catalog entry: `ace-assign/.ace-defaults/assign/catalog/steps/record-demo.step.yml`
- Positioned between `push-to-remote` (140) and `update-pr-desc` (150)
- Added to composition rules and `implement-with-pr` recipe
- Updated PR update workflow to reference attached demo recordings
- Non-blocking: skips gracefully when VHS/FFmpeg unavailable or no tapes exist

## What Went Well

- The entire `ace-demo record --pr` pipeline was already built and working — only workflow wiring was missing
- Existing step catalog pattern (`verify-e2e.step.yml`) provided a clear template to follow
- Dogfooding worked: recorded a real demo and attached it to PR #265 as proof

## What Could Be Improved

- The tape resolution requires running from the package directory — `ace-demo record` doesn't accept absolute paths from a different working directory. The step instructions work around this by `cd`-ing to the package.

## Action Items

- **Continue**: Including `record-demo` in future `work-on-task` assignments for packages with tapes
- **Monitor**: Whether fork agents can handle demo recording (VHS availability in fork environments)

