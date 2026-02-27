# Reflection: Task 296 — ace-sim Rebuild

**Date**: 2026-02-27
**Context**: Full session retrospective for task 296 (ace-sim rebuild from task 285 postmortem). A complex multi-phase assignment (`8pqm43`) that delivered a new `ace-sim` package through a usage-first, proof-before-code approach. The session spanned 15+ assignment phases, 2 fork subtrees, 3 review cycles, commit reorganization, PR creation, and post-delivery workflow enhancements.
**Author**: Claude (Opus 4.6)
**Type**: Conversation Analysis

## What Went Well

- **Two-phase proof-then-implement approach**: Phase 1 proof contracts (6 artifacts) directly informed Phase 2 implementation — no wasted design effort, contracts were accurate
- **Fork subtree delegation**: `ace-assign fork-run` effectively isolated complex subtask execution (5 phases each for 296.01 and 296.02)
- **Three-tier review cycle**: code-valid → code-fit → code-shine caught real issues at each tier:
  - Valid: 4/9 applied (output file validation, variable ordering, redundant accessor, scenario validation)
  - Fit: 4/11 applied (YAML alias security fix, ADR-022 alignment, flag cleanup, gemspec constraint)
  - Shine: 1/12 applied (docs/tools.md entry)
- **Commit reorganization**: 9 messy intermediate commits cleanly reorganized into 2 logical groups via soft reset + `ace-git-commit`
- **Full test suite green**: 17 ace-sim tests, 7591 monorepo tests — zero failures throughout

## What Could Be Improved

- **Uncommitted fork artifacts**: Phase 1 fork completed but left proof files uncommitted — user had to remind to check `git status` before starting Phase 2 fork
- **Task subagent overhead for forks**: Initially used `Task` subagent to run fork-run — user corrected to use direct `Bash` invocation which is simpler and avoids unnecessary indirection
- **PR description workflow gap**: Phase 150 ("Update PR description") used manual `gh pr edit` instead of `/ace-git-update-pr-desc` skill — produced freestyle description that didn't match project conventions. Root cause: phase instruction was generic without referencing the proper skill
- **Provider alias instability**: `google:gflash` alias resolved to unavailable model — required manual fallback to explicit `google --model gemini-2.5-flash` twice in proof phase

## Key Learnings

- **Phase instructions need skill references**: When a phase expects a specific workflow (e.g., PR description), the phase instruction must name the skill — generic instructions like "update PR description" lead to ad-hoc execution
- **Fork subtrees leave uncommitted work**: After fork-run completes, always run `git status` to commit artifacts before proceeding to the next fork
- **Expected failures are valid outcomes**: Release phase correctly failed for proof-only Phase 1 (no package code) — the right response is evidence + continue, not retry
- **`ace-assign start` vs `ace-assign finish`**: When a parent phase's child completes, use `ace-assign start` to advance the queue, not `ace-assign finish` (which expects an active phase)

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **PR description method gap** (1 occurrence)
  - Impact: PR #222 had to be completely rewritten with proper format after initial manual approach
  - Root Cause: Phase 150 lacked skill reference in instruction text
  - Fix applied: Used `/ace-git-update-pr-desc` to regenerate; also added Demo section to PR workflows

#### Medium Impact Issues

- **Uncommitted fork artifacts** (1 occurrence)
  - Impact: Phase 2 could have started on dirty working tree
  - Root Cause: Fork agent created files but no commit step in fork-run lifecycle
  - Fix: User reminded; committed with `ace-git-commit`

- **Task subagent for fork delegation** (1 occurrence)
  - Impact: Unnecessary complexity — Task subagent wrapping a simple Bash command
  - Root Cause: Default pattern was to use Task for anything complex
  - Fix: User directed to use `ace-assign fork-run` directly via Bash

- **Provider alias resolution** (2 occurrences)
  - Impact: Each fallback added ~30s delay per proof stage execution
  - Root Cause: `google:gflash` shorthand not configured in environment
  - Mitigation: Used explicit `google --model gemini-2.5-flash`

#### Low Impact Issues

- **Context compaction mid-session** (1 occurrence)
  - Impact: Required careful continuation from compacted state
  - Mitigation: Session summary preserved all critical context

### Improvement Proposals

#### Tool Proposals

- **`ace-assign fork-run --commit-on-complete`**: Auto-commit fork artifacts when fork subtree finishes, preventing forgotten uncommitted files
- **Phase instruction skill binding**: Allow phase definitions to declare required skills (e.g., `skill: ace-git-update-pr-desc`) so the driver knows which workflow to invoke

#### Workflow Proposals

- **Post-fork checkpoint**: Add explicit "commit fork artifacts" step to the fork-run lifecycle or the parent batch-tasks phase
- **Phase 150 template**: Change update-pr-desc phase instructions from generic "update PR description" to explicit "run `/ace-git-update-pr-desc`"

#### Communication Protocols

- Phase instructions should explicitly name required skills/commands rather than describing intent generically
- Fork boundaries should include mandatory git status checkpoints

### Token Limit & Truncation Issues

- **Large Output Instances**: 1 — context compaction triggered mid-session (~939 events)
- **Truncation Impact**: Minimal — session summary preserved all critical assignment state and phase context
- **Mitigation Applied**: Careful continuation from compacted state, referencing preserved summary
- **Prevention Strategy**: For long multi-fork sessions, consider splitting into separate conversation sessions at fork boundaries

## Action Items

### Stop Doing

- Using `Task` subagent to wrap simple `ace-assign fork-run` bash commands
- Writing PR descriptions manually with `gh pr edit --body` when `/ace-git-update-pr-desc` exists
- Proceeding to next fork subtree without committing previous fork's artifacts

### Continue Doing

- Two-phase proof-then-implement approach for new packages
- Three-tier review cycle (valid → fit → shine) with selective apply
- Commit reorganization via soft reset after review iterations
- Evidence-based reporting for each assignment phase

### Start Doing

- Adding skill references to phase instructions (e.g., "Update PR desc using `/ace-git-update-pr-desc`")
- Running `git status` checkpoint between fork subtree boundaries
- Documenting provider alias availability before proof runs
- Including `## Demo` section in PRs with user-facing CLI (now codified in workflows)

## Technical Details

- **Assignment**: `8pqm43` (work-on-tasks-296)
- **Branch**: `296-ace-sim-rebuild-from-task-285-postmortem-usage-first`
- **PR**: #222 (https://github.com/cs3b/ace-meta/pull/222)
- **Deliverables**: ace-sim v0.1.3, 48 files, 1592 insertions
- **Duration**: ~1.5 hours (14:44 → 16:05 UTC)
- **Phases completed**: 15+ (onboard, 2 fork subtrees x 5 phases, release, PR, 3 review cycles, reorg, push, update-desc)
- **Reviews**: 32 total findings, 9 applied, 23 skipped (design/v2/low-priority)

## Additional Context

- **Sources analyzed**: 25 assignment phase reports (`.cache/ace-assign/8pqm43/reports/`), compacted session transcript (939 events), 3 review sessions (`review-8pqn5u`, `review-8pqnby`, `review-8pqnif`), simulation demo run (`tb4k7zcm`), git history (3 final commits)
- **Related tasks**: Task 285 (original ace-sim, postmortem source), Task 296 (this rebuild)
- **Key commits**: `09addf59e` (ace-sim package), `47af0ddb9` (taskflow artifacts), `a1851f000` (PR workflow Demo section)
