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

### Round 1: Add record-demo step to assignment workflow
- New step catalog entry: `ace-assign/.ace-defaults/assign/catalog/steps/record-demo.step.yml`
- Positioned between `push-to-remote` (140) and `update-pr-desc` (150)
- Added to composition rules and `implement-with-pr` recipe
- Updated PR update workflow to reference attached demo recordings
- Non-blocking: skips gracefully when VHS/FFmpeg unavailable or no tapes exist

### Round 2: Fix step instructions and demo tape quality
- **Problem**: Step 145 said "record the getting-started tape" — irrelevant to the PR's feature
- **Problem**: Feature tape had broken sandbox paths, missing fixtures, unreadable 4x speed
- **Fix**: Rewrote step instructions to guide agents toward feature-relevant demos with proper tape design (show config → run feature → verify result)
- **Fix**: Created proper fixtures directory with sample tape.yml, rewrote demo tape with copy-fixtures, relative sandbox paths, and no playback_speed for readability

## What Went Well

- The `ace-demo record --pr` pipeline was already built and working
- Existing step catalog pattern (`verify-e2e.step.yml`) provided clear template
- Once fixtures were set up correctly, tape ran cleanly without path errors

## What Could Be Improved

- **First attempt was wrong**: Blindly recorded the package getting-started tape instead of designing a feature-relevant demo
- **Second attempt had errors**: Created a tape without fixtures, used `$PROJECT_ROOT_PATH` incorrectly in sandbox, and 4x speed made content unreadable
- **Lesson**: Demo tapes require deliberate design — the three-scene pattern (show input → run feature → verify output) with proper fixtures is the proven approach
- **Nested VHS risk**: Running `ace-demo record` inside a VHS session (nested recording) is untested — may need fallback to dry-run-only demos

### Round 3: Demo scenario belongs in the task spec, not improvised at recording time
- **Problem**: Agent improvised demo content 3 times — wrong tape, broken fixtures, bad timing. No pre-defined scenario.
- **Root cause**: Demo was treated as a recording problem. It's actually a design/review problem.
- **Fix 1**: Added "Demo Scenario" section to task draft template (`ace-task/handbook/templates/task/draft.template.md`) — defines scenes, commands, and fixtures upfront for user-facing features
- **Fix 2**: Updated step 145 instructions to read the task spec's Demo Scenario first, validate with dry-run before recording, and use proper fixture/sandbox patterns

## Action Items

- **Continue**: Including `record-demo` in future assignments
- **Start**: Define demo scenarios in task specs during draft/review for user-facing features
- **Start**: Always create `fixtures/` directory and dry-run before recording
- **Stop**: Improvising demo content at recording time — follow the pre-defined scenario
- **Stop**: Using `playback_speed` in demo tapes meant for PR review — record at normal speed
- **Monitor**: Whether nested VHS invocations work reliably

