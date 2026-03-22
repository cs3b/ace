---
id: 8qlk2n
title: selfimprove-parent-task-closure
type: self-improvement
tags: [process-fix, task-management]
created_at: "2026-03-22 13:22:56"
status: active
---

# Self-Improvement: Parent Task Closure

Source: Assignments `8ql46r` (8q4.t.uno) and prior (8q4.t.umv)

## Root Cause

The `mark-task-done` step only marked leaf subtasks as done. It had no guidance to check whether marking a child done completes the parent. Two parent tasks (`8q4.t.uno`, `8q4.t.umv`) were left `in-progress` despite all children being `done`.

Category: **Scope narrowing** — the step followed its instructions literally (mark the listed taskrefs) without considering the parent hierarchy.

## Process Change

Updated `ace-assign/.ace-defaults/assign/catalog/steps/mark-task-done.step.yml` to add step 3: after marking a task done, check if all siblings are done and close the parent. Repeat upward.

## Immediate Fix

- Marked `8q4.t.uno` as done (all 4 children were already done)
- Marked `8q4.t.umv` as done (all 4 children were already done)

