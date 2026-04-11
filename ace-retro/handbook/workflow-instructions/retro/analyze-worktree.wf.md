---
doc-type: workflow
title: Analyze Worktree Outcome for Spec Improvements
purpose: Documentation for ace-retro/handbook/workflow-instructions/retro/analyze-worktree.wf.md
ace-docs:
  last-updated: 2026-04-11
  last-checked: 2026-04-11
---

# Analyze Worktree Outcome for Spec Improvements

## Goal

Create a high-signal retrospective that analyzes one or many completed assignments across one or many worktrees, then compare:

- initial assignment scope
- lockpoint completion outcomes
- residual work added after completion
- evidence in `.ace-local` (reviews, synthesis, tests, task rewrites)

and convert results into ranked spec and workflow improvements.

## Prerequisites

- Access to one completed worktree or a parent folder containing many `ace-t.*` worktrees
- `git` installed in the target worktree(s)
- `ace-retro create` available on `PATH`
- `ruby` (for YAML/JSON parsing)
- `jq` (optional for JSON summary extraction)
- `ace-task`, `ace-assign` for task lookups
- Sufficient local commit history to include assignment changes

## Suggested Inputs

Set these environment variables before running:

- `SCOPE=fleet|single` (default: `fleet` if parent looks like a worktree collection, else `single`)
- `WORKTREE_PATH` (default: current directory for single mode)
- `WORKTREE_ROOT` (default: parent of `WORKTREE_PATH`, used for fleet discovery)
- `ASSIGNMENT_FILTER` (optional assignment id regex)
- `ASSIGNMENT_STATUS_FILTER` (optional substring match on lockpoint step name; defaults include `155` and `160`)
- `INCLUDE_POST_COMPLETION=true|false` (default: `true`)
- `OUTPUT_FORMAT=md|json|both` (default: `both`)
- `MAX_ASSIGNMENTS` (optional numeric cap)
- `SINCE_DAYS` (optional recency cutoff)
- `TOP_PATTERNS=10` (default)

## Project Context Loading

- Load `handbook/templates/retro/retro.template.md`
- Load retro workflow artifacts from `.ace-retros/` and `.ace-local/assign/`
- Load review/test telemetry from `.ace-local/review/` and `.ace-local/test*` when present

## Process Steps

1. **Resolve target worktree set**
   - Determine execution mode:
     - `SCOPE=fleet`: scan sibling worktrees in `WORKTREE_ROOT` (`ace-t.*` and `.git/worktrees`)
     - `SCOPE=single`: analyze only `WORKTREE_PATH`
   - Validate each candidate has `.git` and `.ace-local/assign`; skip invalid ones.
   - If no candidate has completed assignments, stop with: `No completed assignments found`.

2. **Discover completed assignments**
   - For each assignment directory in `<worktree>/.ace-local/assign/*`:
     - Prefer `.../reports/160-create-retro.r.md`
     - Fallback to `.../reports/155-mark-tasks-done.r.md`
   - Parse `completed_at`, `step`, `name`, `assignment_id`, and any `commits:` bullets.
   - Apply `ASSIGNMENT_FILTER` and `SINCE_DAYS`.
   - Mark assignments without lockpoint as `incomplete` and continue.

3. **Extract initial scope**
   - Collect scope signals per assignment from:
     - `.ace-local/task/<task-id>/latest-plan.md`
     - `.ace-local/task/<task-id>/latest-plan.meta.yml`
     - assignment reports `*task-load*.r.md`
     - step files `steps/*task*.st.md` and `steps/*work-on-task.st.md`
   - Capture explicit deliverable targets: file names, package names, acceptance criteria, command targets.
   - If task text is sparse, use `ace-task show <task-id>` as fallback.
   - Build `planned_scope` with confidence tag (`high`, `medium`, `low`).

4. **Resolve completion lockpoint and change windows**
   - Convert `completed_at` to RFC3339.
   - Resolve lockpoint commit:
   ```bash
   LOCK_COMMIT="$(git rev-list -n 1 --before "${LOCK_TS}" HEAD || true)"
   if [ -z "$LOCK_COMMIT" ]; then
     LOCK_COMMIT="$(git rev-list -n 1 --max-count=1 HEAD)"
   fi
   ```
   - Pre-lock scope: `git diff --name-only "$LOCK_COMMIT"^ "$LOCK_COMMIT" -- .` when commit exists.
   - Residual scope: `git diff --name-only "$LOCK_COMMIT" HEAD -- .`
   - Always keep a recorded timestamp and boundary in retro output.

5. **Classify residual work and drift**
   - Compare planned scope vs pre-lockpoint file changes.
   - Mark missing planned work if no matching file change exists.
   - Classify residual paths into risk bands:
     - high: release/version/changelog, dependency/security/versioning, follow-up bugfixes, unplanned production fixes
     - medium: docs, observability, tooling, refactors
     - low: cleanup/formatting/housekeeping
   - Track `post_completion_without_scope_ref` for file families not seen in planned scope.

6. **Extract deep `.ace-local` signals**
   - Review sessions:
     - enumerate `.ace-local/review/sessions/*/*/*.{yml,yaml,md}` and normalize both modern (`models: [...]`) and legacy (`model`) schemas
     - capture count, provider/model mix, run status, run duration, pass/fail outcome
   - Feedback artifacts:
     - scan `.ace-local/review/feedback/**/*.md` and `feedback/_archived/**/*.md`
     - summarize by `status`, `priority`, `reviewer`
   - Synthesis artifacts:
     - parse `.ace-local/review/feedback-synthesis/feedback-synthesis.cleaned.json`
     - capture `total_findings`, `consensus_findings`, recurrence hints
   - Test artifacts:
     - parse `.ace-local/test/reports/*/*/summary.json`
     - parse `.ace-local/test-e2e/*/metadata.yml`
   - Task/admin artifacts:
     - detect `.ace-local/task/*` and `latest-plan*` updates after lockpoint
     - flag repeated plan rewrites after lockpoint

7. **Fleet-level aggregation**
   - Aggregate counts and ratios across assignments and worktrees:
     - completion_ratio
     - planned_scope_coverage
     - post_completion_count
     - review_session_count
     - total review feedback + consensus findings
     - test pass/fail trend
   - Identify top repeated drift themes across the full fleet.

8. **Create ranked recommendations**
   - Score by:
     - recurrence across assignments
     - residual risk
     - review iteration count
     - test pain points
     - low confidence in original scope capture
   - Produce top `TOP_PATTERNS` recommendations with assignment-level evidence and concrete spec change suggestions.

9. **Create retro with findings**
   - Create retro:
   ```bash
   ace-retro create "analyze-worktree-$(basename "$WORKTREE_PATH")-$(date +%Y%m%d)" --type standard --tags worktree-analysis,fleet-retro,spec-quality
   ```
   - Populate minimum sections:
     - `What Went Well`
     - `What Could Be Improved`
     - `Key Learnings`
     - `Action Items`
     - `Assignment Scope vs Outcome`
     - `Post-Completion Residual Work`
     - `Review Cycle Telemetry`
     - `Test & Verification Telemetry`
     - `Ranked Spec Recommendations`
   - Include lockpoint evidence, assignment IDs, file families, and commit IDs.
   - If `OUTPUT_FORMAT` is `json` or `both`, write:
     - `.ace-local/retros/fleet-analytics-<timestamp>.json`

10. **Complete and validate**
   - Open the created retro path.
   - Confirm no placeholder text remains.
   - Confirm JSON artifact (when requested) includes:
     - `worktree_count`
     - `assignments_analyzed`
     - `completion_ratio`
     - `post_completion_count`
     - `review_sessions`
     - `test_summary`
   - Do not fail on missing optional telemetry; mark coverage gaps explicitly.
   - Suggested JSON envelope:
   ```json
   {
     "meta": {"scope":"fleet","generated_at":"2026-04-11T00:00:00Z","worktree_root":"/home/mc"},
     "summary": {
       "worktree_count": 4,
       "assignments_discovered": 9,
       "assignments_analyzed": 8,
       "completion_ratio": 0.89,
       "post_completion_events": 17
     },
     "post_completion": {},
     "review": {},
     "test": {}
   }
   ```

## Success Criteria

- One or more completed assignments were found and analyzed (single or fleet)
- Each analyzed assignment includes:
  - lockpoint evidence and boundary timestamp
  - planned scope evidence
  - residual classification and risk labels
  - review/test telemetry when available
- Retro contains explicit sections and ranked recommendations with concrete evidence
- Fleet output is deterministic across runs for same inputs (ordering by worktree then assignment)
- Missing telemetry produces explicit gap notes, not hard failure

## Error Handling

**No completion marker found**
- Mark assignment `incomplete` and continue with remaining assignments.

**Cannot derive lockpoint commit**
- Skip file-level residual checks and still include lockpoint metadata and fallback recommendations.

**No review/test artifacts**
- Add `missing_*` markers and continue.

**Heterogeneous session schema**
- Accept both legacy and modern review session shapes and keep both parsed or flagged as unparsed.

## Usage Example

Fleet mode:
```bash
WORKTREE_ROOT=/home/mc
SCOPE=fleet
ASSIGNMENT_FILTER='8r'
TOP_PATTERNS=12
OUTPUT_FORMAT=both
ace-bundle wfi://retro/analyze-worktree
```

Single mode:
```bash
SCOPE=single
WORKTREE_PATH=/home/mc/ace-t.h3e
ASSIGNMENT_FILTER=8r4i7n
OUTPUT_FORMAT=md
ace-bundle wfi://retro/analyze-worktree
```
