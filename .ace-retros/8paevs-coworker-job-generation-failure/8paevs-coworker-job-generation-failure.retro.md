---
id: 8paevs
title: Coworker Job Generation Failure — Missing Skill Invocations
type: conversation-analysis
tags: []
created_at: "2026-02-11 09:55:18"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8paevs-coworker-job-generation-failure.md
---
# Reflection: Coworker Job Generation Failure — Missing Skill Invocations

**Date**: 2026-02-11
**Context**: Coworker session 8p9y1j generated jobs without `/ace:work-on-task` skill invocations, leading to incomplete implementations reported as "done"
**Author**: Development Team
**Type**: Conversation Analysis

## What Went Well

- The coworker infrastructure (session creation, job dispatch, fork contexts) worked mechanically
- The issue was caught during E2E analysis when reviewing test results — the analysis session identified that agent output didn't follow expected patterns
- Quick root cause identification: comparing job instructions against expected skill-based format

## What Could Be Improved

- **Job generation produced freeform instructions instead of skill invocations**: Jobs at `.cache/ace-coworker/8p9y1j/jobs/010.0{1-4}*.j.md` all have "Implement task X, follow conventions" instead of `/ace:work-on-task X`
- **No validation that generated jobs reference defined skills**: The coworker-prepare workflow doesn't verify that work steps invoke actual skills
- **Agent improvisation without guardrails**: When given freeform instructions, the agent built isolated components without loading task context, running acceptance criteria, or verifying integration — then reported "done"

## Key Learnings

- **Skill invocations are load-bearing**: `/ace:work-on-task` doesn't just provide instructions — it loads task specs, acceptance criteria, dependency context, and verification steps. Without it, the agent only sees the one-line instruction and improvises everything else
- **Freeform instructions create a false sense of completion**: The agent followed the freeform instructions literally (implement, commit, report) but missed the structured workflow that ensures quality (load context, verify tests, check acceptance criteria)
- **Job templates need structural enforcement**: The difference between a working job and a broken one is the instruction format, not the surrounding boilerplate (onboard/report sections were fine)

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Missing skill invocations in job instructions**: All 4 jobs in session 8p9y1j used freeform "Implement task X" instructions instead of `/ace:work-on-task X`
  - Occurrences: 4 jobs (010.01 through 010.04)
  - Impact: Agent built components without proper context loading, skipped acceptance criteria verification, reported incomplete work as "done"
  - Root Cause: `ace-coworker-prepare` generated instructions from task titles rather than enforcing skill-based invocation patterns

- **False "done" status on incomplete work**: Agent marked all jobs as `status: done` despite implementations missing integration points
  - Occurrences: 4 jobs
  - Impact: Required manual review to discover the work was incomplete, wasting the review cycle
  - Root Cause: Without `/ace:work-on-task` workflow, there's no automated verification step — the agent self-assessed completion

### Improvement Proposals

#### Process Improvements

- Job generation should default to `/ace:work-on-task {subtask-id}` for implementation tasks
- Add a validation step in `ace-coworker-prepare` that checks work instructions reference defined skills
- Job templates should include a verification step that runs acceptance criteria checks

#### Tool Enhancements

- `ace-coworker-prepare`: Add `--validate-skills` flag (or make it default) that rejects jobs with freeform work instructions
- `ace-coworker-prepare`: For subtask-based jobs, auto-generate `/ace:work-on-task {id}` as the work instruction
- Consider a job linter that warns when work steps don't match known skill patterns

## Action Items

### Stop Doing

- Generating coworker jobs with freeform "Implement task X" instructions
- Trusting agent self-reported "done" status without skill-enforced verification

### Continue Doing

- Using coworker sessions for parallelizable subtask execution
- Post-session review to catch integration issues

### Start Doing

- Default to `/ace:work-on-task {subtask-id}` in job.yaml work steps for implementation tasks
- Validate generated jobs against skill invocation patterns before creating sessions
- Include acceptance criteria verification as a required step in job completion

## Technical Details

**Evidence — Job instructions from session 8p9y1j:**

Job 010.01 (`work-on-261.01`):
```
## Work
Implement task 261.01 (SetupExecutor + ScenarioLoader Infrastructure).
Follow ATOM architecture and project conventions.
```

**Expected format:**
```yaml
- name: work-on-261.01
  instruction: "/ace:work-on-task 261.01"
  context: fork
```

The critical difference: `/ace:work-on-task` loads the full task spec (including acceptance criteria, dependencies, and verification steps), while freeform instructions leave the agent to improvise.

## Additional Context

- Coworker session: `8p9y1j`
- Job files: `.cache/ace-coworker/8p9y1j/jobs/010.0{1-4}*.j.md`
- Branch: `261-e2e-per-tc-infrastructure-implementation`
- PR: #197
- Related task: 261 (E2E per-TC infrastructure implementation)
