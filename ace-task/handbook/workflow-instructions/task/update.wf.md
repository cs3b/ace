---
name: task-update
description: Update task metadata, status, position, or location
allowed-tools: Bash, Read
argument-hint: "<ref> [--set K=V] [--move-to FOLDER] [--move-as-child-of PARENT|none]
  [--position first|after:<ref>]"
doc-type: workflow
purpose: Update task fields, change status, move between folders, and manage hierarchy
ace-docs:
  last-updated: '2026-03-21'
  last-checked: '2026-03-21'
---

# Update Task

## Goal

Provide a single canonical workflow for task updates, including status changes, metadata edits, and hierarchy movement operations, including promote/demote flows.

## Prerequisites

- A valid task reference (`<ref>`) for the target task/subtask
- Target folder or parent references for moves (when provided)
- Permissions to modify task files in the active repository context

## Project Context Loading

Load and follow:

- `ace-bundle wfi://bundle`

## Process Steps

1. **Choose the update intent**

   - Metadata updates (status, priority, tags, dependencies, notes)
   - Lifecycle transitions (backlog/archive/done flows via `--set status=...`)
   - Reparenting / hierarchy movement
   - Sort order changes

2. **Apply metadata updates**

   Use focused `--set` operations:

   ```bash
   ace-task update <ref> --set status=in-progress
   ace-task update <ref> --set status=done
   ace-task update <ref> --set status=done,priority=high
   ace-task update <ref> --set status=pending,needs_review=false
   ace-task update <ref> --add tags=shipped
   ace-task update <ref> --remove tags=wip
   ```

   - When multiple scalar fields on the same task must change together, prefer one combined `--set a=x,b=y` command.
   - Do not run multiple `ace-task update` commands in parallel against the same task ref.

3. **Apply hierarchy updates via `--move-as-child-of`**

   - Promote a subtask to standalone

   ```bash
   ace-task update <ref> --move-as-child-of none
   ace-task update <ref> --move-as-child-of none --dry-run
   ```

   - Demote a task to be a child of a parent orchestrator

   ```bash
   ace-task update <ref> --move-as-child-of <parent-ref>
   ace-task update <ref> --move-as-child-of <parent-ref> --dry-run
   ```

   - Convert/restructure to parent-child shape when the command supports direct self-parenting in your CLI version

   ```bash
   ace-task update <ref> --move-as-child-of self
   ```

4. **Adjust sort position**

   ```bash
   ace-task update <ref> --position first
   ace-task update <ref> --position after:<other-ref>
   ```

5. **Handle folder/location moves**

   ```bash
   ace-task update <ref> --move-to archive
   ace-task update <ref> --move-to backlog
   ```

6. **Validate results immediately**

   - Re-open target task: `ace-task show <ref>`
   - Confirm metadata, location, parent/child relationship, and position
   - If you combined multiple field updates, confirm all fields persisted before issuing another same-task mutation
   - Verify dry-run output before executing non-idempotent moves

## Error Handling

### Missing or invalid target reference

- Symptom: command returns unresolved reference or file-not-found error
- Fix: verify ref format and current ref status with `ace-task show` or `ace-task finder`

### Invalid move target

- Symptom: reparent command fails for non-orchestrator parent or circular relationship
- Fix: confirm the target parent is the intended hierarchy node and re-run with valid `--move-as-child-of` value

### Command-level validation failures

- Symptom: argument parsing errors or rejected flags
- Fix: rerun with a narrower set of flags and add one change at a time

## Success Criteria

- Target task is updated with expected status/metadata changes
- Reparenting operations produce the intended hierarchy state
- Sort position changes place the task at the requested location
- Location moves place the task in the intended folder/release
- Final `ace-task show <ref>` output matches expected target state
