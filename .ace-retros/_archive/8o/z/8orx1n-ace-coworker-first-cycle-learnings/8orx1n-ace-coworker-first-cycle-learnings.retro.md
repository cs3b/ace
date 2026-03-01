---
id: 8orx1n
title: "Retro: First Full ace-coworker Cycle — Session 8orv8f (Task 229)"
type: self-review
tags: []
created_at: "2026-01-28 22:01:49"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8orx1n-ace-coworker-first-cycle-learnings.md
---
# Retro: First Full ace-coworker Cycle — Session 8orv8f (Task 229)

**Date**: 2026-01-28
**Context**: Analysis of the first complete manual ace-coworker workflow run using the work-on-task-with-pr preset
**Author**: Development Agent
**Type**: Self-Review

## What Went Well

- **The implementation work was real and substantial**: 18 well-scoped commits migrating 14+ gems from return-based to exception-based exit codes, 97 files changed with net -42 lines (healthy for refactoring)
- **Time allocation was appropriate**: 35 of 44 minutes spent on actual implementation (step 2), not overhead — the system stayed out of the way
- **Session mechanics worked reliably**: All 10 steps completed, reports were appended, frontmatter tracked timing, auto-advance worked correctly
- **PR creation was functional**: PR #180 created with structured description (Summary/Changes/Test Plan), all 25 packages passing, 5633 tests
- **The approach was correct**: Agent identified the right pattern (create Ace::Core::CLI::Error, update exe wrappers with rescue blocks) matching the task spec and ADR-023

## What Could Be Improved

- **Review cycles were too shallow**: All 3 review cycles found zero actionable issues. Combined 5.5 minutes for a 162-file PR. Cycle 3 was 16 seconds. For mechanical refactoring this is plausible but the reports lack depth to prove thorough review occurred.
- **Reports mixed with instructions**: Current design appends report content inline to step .md files. This couples "what was asked" with "what was delivered" in a single file, making step files bloated and harder to diff/review.
- **Missing `prepare` CLI command**: User had to use Claude Code workflow (`/ace:coworker-prepare`) because there's no CLI equivalent for preparing job.yaml from presets
- **"Capture PR number" instruction not fulfilled**: Step 3 says "Update the next steps with the PR number" but step files were never modified — the agent just mentally tracked it
- **Manual orchestration overhead**: User had to manually run 6 commands (git-worktree create, cd, /onboard, /ace:coworker-prepare, /ace:coworker-create-session, /ace:coworker-start) instead of a single `ace-overseer run --task 229`
- **Onboard report was superficial**: Read as a task summary rather than evidence of codebase understanding — no mention of files read or architecture examined

## Key Learnings

- **Exit-code-only testing creates false confidence**: The original MT-COWORKER-001 E2E test passed all commands but never verified which step was actually being operated on — state machine could have been broken and tests wouldn't catch it
- **`report` is step-blind**: It always completes `state.current` regardless of what the report file is named. Test authors must track which step is current at each point — report filenames provide zero safety
- **Self-review anti-pattern**: The same agent that wrote the code reviewed it across 3 cycles, finding zero issues. While this is plausible for mechanical refactoring, the review quality metrics (16 seconds for cycle 3) suggest going through motions
- **Session metadata is minimal but sufficient**: `session.yaml` has what's needed (name, description, created_at, source_config reference). The `source_config` pointer enables traceability back to the original job.yaml
- **Step file format works well**: YAML frontmatter with name/status/skill/timestamps, instructions, `---` separator, then `# Report` with appended content. Clean and readable for inline reports.

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Report inline storage**: Reports appended to step files mix concerns (instructions vs output). Makes step files bloated, harder to diff, harder to review independently.
  - Impact: Every completed step file grows in size. For 10-step sessions, the instruction files become difficult to read.
  - Root Cause: Design decision to append report content directly to step file body in `StepWriter#mark_done`

- **Missing `prepare` CLI command**: Users cannot prepare job.yaml from CLI, must use Claude Code workflow.
  - Impact: Forces context switch between terminal and Claude Code. Breaks CLI-only workflow.
  - Root Cause: CLI only has create/status/report/fail/add/retry commands. No prepare command implemented.

#### Medium Impact Issues

- **Review cycle quality unverifiable**: All 3 review cycles found zero actionable issues in 5.5 minutes combined.
  - Impact: Unclear whether reviews were thorough or superficial. For 162-file PR, 16-second final review is suspiciously fast.
  - Root Cause: Same agent reviewing own code. No independent verification mechanism.

- **PR number instruction ambiguity**: "Capture the PR number for subsequent review steps" instruction not fulfilled literally.
  - Impact: Step files not updated with PR number. Agent carried context mentally instead.
  - Root Cause: Instruction expects dynamic file modification but no mechanism exists for it.

#### Low Impact Issues

- **Manual orchestration overhead**: 6 separate commands required to start a coworker session.
  - Impact: UX friction, but functional.
  - Root Cause: ace-overseer not yet implemented (future work).

### Improvement Proposals

#### Process Improvements

- **Separate report files**: Store reports in `reports/` directory, referenced from step frontmatter via `report: reports/010-onboard.md`. Keeps instructions clean, allows independent review of reports.
- **Review cycle configuration**: Allow presets to configure review cycle count. Mechanical refactoring may only need 1 cycle. Complex features may need 3+.
- **Review quality requirements**: Add minimum review duration or file-sampling requirements to review step instructions to prevent rubber-stamping.

#### Tool Enhancements

- **Add `ace-coworker prepare` CLI command**: Enable CLI-only workflow. `ace-coworker prepare --preset work-on-task-with-pr --param taskref=229`
- **Session variables/metadata system**: Implement `ace-coworker set key value` to store session variables (like `pr_number`) that can be referenced in subsequent steps via `{{pr_number}}`

#### Communication Protocols

- **Clarify "capture PR number" instruction**: Either remove it (agent carries context naturally) or implement session variable system for explicit tracking.

## Action Items

### Stop Doing

- Appending report content inline to step files (mixed concerns, bloated files)
- Writing E2E tests that only check exit codes without verifying state machine transitions

### Continue Doing

- Using YAML frontmatter for step metadata (clean, readable)
- Auto-advance after report completion (works reliably)
- Session mechanics — timing, status tracking, file naming all worked well

### Start Doing

- Storing reports as separate files in `reports/` directory, referenced from step frontmatter
- Verifying state transitions in E2E tests (which step is current, not just exit codes)
- Adding queue state diagrams at test case boundaries where state carries over

## Technical Details

### Report Separation Implementation Plan

The proposed change affects multiple files:

| File | Change |
|------|--------|
| `ace-coworker/lib/ace/coworker/molecules/step_writer.rb` | `mark_done`: write report to `reports/<number>-<name>.md` instead of appending inline. Add `report` key to frontmatter. |
| `ace-coworker/lib/ace/coworker/models/session.rb` | Add `reports_dir` method returning `File.join(dir, "reports")` |
| `ace-coworker/lib/ace/coworker/models/step.rb` | Add `report_path` attribute; lazy-load report content from file |
| `ace-coworker/lib/ace/coworker/atoms/step_file_parser.rb` | `extract_report`: read from separate file via frontmatter `report` key; keep backward compat for inline `---` split |
| `ace-coworker/lib/ace/coworker/organisms/workflow_executor.rb` | `advance` (line 105): pass session to `mark_done` so it can access `reports_dir` |
| `ace-coworker/lib/ace/coworker/cli/commands/report.rb` | Update output message: "Report saved to: reports/010-onboard.md" |
| `ace-coworker/test/molecules/step_writer_test.rb` | Update tests for new report storage |
| `ace-coworker/test/organisms/workflow_executor_test.rb` | Update advance tests |
| `ace-coworker/test/e2e/MT-COWORKER-001-workflow-lifecycle.mt.md` | TC-006: add `reports/` positive assertion; TC-008: verify report in separate file |

New session directory structure:
```
.cache/ace-coworker/<id>/
  session.yaml
  jobs/
    010-onboard.md        ← instructions only
    020-work-on-task.md
    ...
  reports/
    010-onboard.md        ← report only
    020-work-on-task.md
    ...
```

### Key Status Output Patterns for Assertions

| Scenario | Grep pattern | Present? |
|----------|-------------|----------|
| Step is current | `Current Step:.*<name>` | Yes |
| Queue stalled | `Current Step:` | No (absence) |
| Session complete | `Session completed!` | Yes |
| Report rejected (stalled) | `No step currently in progress` | Yes (exit 1) |

## Additional Context

- Session analyzed: 8orv8f (work-on-task-with-pr-229)
- Duration: ~44 minutes (20:49:22 to 21:33:41)
- PR created: #180 (OPEN, +7781/-706 lines, 162 files — includes branch history)
- Commits during session: 18 (ce64569c9 through f2f1580ce)
- Task specification: 229 (Migrate ACE CLI gems to exception-based exit code pattern)
- Related plan: `/Users/mc/.claude/plans/tranquil-moseying-toast.md` (full analysis with implementation details)
