---
id: v.0.9.0+task.237
status: in-progress
priority: high
estimate: 6h
dependencies: []
parent: v.0.9.0+task.234
worktree:
  branch: 237-ace-coworker-mvp-with-work-queue-model
  path: "../ace-task.237"
  created_at: '2026-01-28 11:21:58'
  updated_at: '2026-01-28 11:21:58'
  target_branch: main
---

# ace-coworker MVP with Work Queue Model

## 0. Directory Audit ✅

_Command run:_

```bash
ace-nav --sources
```

_Result excerpt:_

```
@ace-handbook (gem): /Users/mc/Ps/ace-task.234/ace-handbook/handbook/guides
@ace-search (gem): Reference CLI gem for dry-cli patterns
@ace-support-config (gem): Configuration cascade implementation
```

**Relevant existing gems:**
- `ace-search`: Reference for CLI structure, dry-cli patterns, ATOM architecture
- `ace-support-config`: Configuration cascade per ADR-022
- `ace-support-core`: Base CLI helpers (`Ace::Core::CLI::DryCli::Base`)
- `ace-support-timestamp`: Session ID generation (8-char Base36)
- `ace-support-markdown`: Frontmatter parsing/editing

## Behavioral Specification

### User Experience

- **Input**: YAML configuration file (job.yaml) defining session name and steps with instructions
- **Process**:
  - User starts session with `ace-coworker start --config job.yaml`
  - System creates session, displays first step instructions
  - User (or agent) completes work, reports with `ace-coworker report <file>`
  - System advances queue, shows next step
  - User can add work dynamically with `ace-coworker add`
  - Failed steps preserved in queue as history; retry creates NEW queue item
- **Output**: Complete work queue showing all items (done, in_progress, in_queue, failed) with history preserved

### Expected Behavior

The ace-coworker gem manages workflow sessions using a **work queue model** where:

1. **Queue as History**: The queue represents both pending work AND execution history. Failed steps are NOT overwritten - they remain visible showing what happened.

2. **Dynamic Work**: Steps can be added to a running session at any time. This enables agents to insert fix steps, verification steps, or additional work as needed.

3. **Retry as New Item**: When retrying a failed step, a NEW queue item is created. The original failed item remains in the queue, showing:
   - Original step #4: failed (error message preserved)
   - Retry step #6: in_progress or done (linked to original)

4. **Status States**: Queue items have four states:
   - `done` - Completed successfully
   - `in_progress` - Currently being worked on (only one at a time)
   - `pending` - Waiting to be executed
   - `failed` - Failed and preserved as history

5. **File-Based Storage**: Each step is a separate markdown file with frontmatter. This provides:
   - Corruption isolation (one file fails, others survive)
   - Git-friendly diffs and merges
   - Natural subtask injection via hierarchical numbering
   - Human-readable history aligned with ACE patterns

### Interface Contract

```bash
# Start a new session from YAML config
ace-coworker start --config job.yaml
# Output:
# Session: foobar-gem-session (8or5kx)
# Created: .cache/ace-coworker/8or5kx/
# Step 010: init-project [in_progress]
#
# Instructions:
# Create a minimal Ruby project structure...

# Check current queue status
ace-coworker status
# Output:
# QUEUE - Session: foobar-gem-session (8or5kx)
# FILE                           STATUS       NAME
# 010-init-project.md            done         init-project
# 020-write-tests.md             done         write-tests
# 030-implement-foobar.md        in_progress  implement-foobar
# 040-run-tests.md               pending      run-tests
# 050-report-status.md           pending      report-status

# Complete current step with a report file
ace-coworker report impl-report.md
# Output:
# Step 030 (implement-foobar) completed
# Report appended to: jobs/030-implement-foobar.md
# Advancing to step 040: run-tests
# Instructions: ...

# Mark current step as failed
ace-coworker fail --message "2 tests failed: test_greet, test_shout"
# Output:
# Step 040 (run-tests) marked as failed
# Updated: jobs/040-run-tests.md
# Error: 2 tests failed: test_greet, test_shout

# Add new step dynamically
ace-coworker add "fix-implementation" --instructions "Fix the FooBar bug"
# Output:
# Created: jobs/041-fix-implementation.md
# Status: in_progress

# Retry a failed step (creates NEW queue item)
ace-coworker retry 040
# Output:
# Created: jobs/042-run-tests.md (retry of 040)
# Step 041 (fix-implementation) must complete first
```

**Error Handling:**
- No active session: "Error: No active session. Use 'ace-coworker start' to begin."
- Missing config file: "Error: Config file not found: job.yaml"
- Missing report file: "Error: Report file not found: report.md"
- Invalid step reference: "Error: Step 99 not found in queue"

**Edge Cases:**
- Starting session when one exists: Warn and offer to resume or create new
- Adding step: If `in_progress` exists → insert after it; else → insert after last `done` step
- Retry of already-completed step: Create new step anyway (re-verification)

### Success Criteria

- [x] `ace-coworker start --config job.yaml` creates session folder with `session.yaml` and `jobs/` subfolder
- [x] `ace-coworker status` displays full queue from `jobs/*.md` files (done/in_progress/pending/failed)
- [x] `ace-coworker report <file>` appends report to current step's `.md` file and advances queue
- [x] `ace-coworker fail --message "..."` updates frontmatter status=failed, preserves file
- [x] `ace-coworker add "step-name"` creates new `.md` file with next available number
- [x] `ace-coworker retry <step-id>` creates new `.md` file with `added_by: retry_of:NNN`
- [x] Queue history shows complete execution path (all files remain, including failed)
- [x] Session state persists as files (can resume after interruption)

### Validation Questions

- [x] **Queue Position**: Where should dynamically added steps be inserted? → After current `in_progress` step (or after last `done` if none in progress)
- [x] **Retry Semantics**: Should retry overwrite or preserve? → PRESERVE (create new item)
- [x] **Status Display**: Show all items or filter by state? → Show ALL (queue is history)
- [x] **Concurrent Sessions**: Allow multiple sessions per directory? → Deferred to later task (out of scope for MVP)
- [x] **Storage Model**: Single JSON or file-based? → FILE-BASED (hierarchical markdown files)

### File-Based Storage Model

```
.cache/ace-coworker/<session-id>/
├── session.yaml                   # Session metadata
└── jobs/                          # Work queue files (lexicographic order)
    ├── 010-init-project.md        # Main task
    ├── 010.01-setup-dirs.md       # Subtask of 010 (optional)
    ├── 010.01.01-create-lib.md    # Sub-subtask (3 levels max)
    ├── 020-write-tests.md
    ├── 030-implement-foobar.md
    ├── 040-run-tests.md           # [failed]
    ├── 041-fix-implementation.md  # Injected after failure
    ├── 042-run-tests.md           # Retry of 040
    └── 050-report-status.md
```

**Numbering Rules:**
- Main tasks: `010`, `020`, `030` (10-step gaps for injection room)
- Subtasks: `.01`, `.02` (2-digit padding)
- Sub-subtasks: `.01.01`, `.01.02` (3 levels max)
- Dynamic injection: next available number (`041` after `040`)

**Queue Reconstruction:** Scan `jobs/*.md`, sort lexicographically, parse frontmatter for status.

## Objective

Create a simplified ace-coworker gem that manages workflow sessions using a work queue model. This replaces the complex 234.01-234.08 subtask breakdown with a focused MVP that:
- Tracks work as a queue (history + pending)
- Preserves failed steps (no overwriting)
- Allows dynamic work addition
- Shows complete execution history

## Scope of Work

- **User Experience Scope**: CLI commands for session lifecycle (start, status, report, fail, add, retry)
- **System Behavior Scope**: Work queue management with history preservation
- **Interface Scope**: YAML input (job.yaml), file-based state (session.yaml + jobs/*.md), CLI commands

### Deliverables

#### Behavioral Specifications
- Complete CLI command interface with expected inputs/outputs
- Work queue state model with status transitions
- Session persistence format (session.yaml + jobs/*.md schemas)
- E2E test scenario validating queue behavior

#### Validation Artifacts
- E2E test case: MT-COWORKER-001 (Work Queue Session Lifecycle)
- Real-world example: FooBar gem creation workflow
- Success criteria checklist

## Out of Scope

- ❌ **Subagent Spawning**: Task tool delegation (234.03)
- ❌ **Human Gates**: Pause for approval (234.06)
- ❌ **Multi-Session**: Concurrent sessions in same directory (234.07)
- ❌ **Verifications**: Automatic verification command execution (234.04)
- ❌ **ace-queue Extraction**: Reusable queue gem (238) - depends on this task

## Technical Approach

### Architecture Pattern

The ace-coworker gem follows the ATOM architecture pattern (ADR-011) with dry-cli (ADR-023):

```
ace-coworker/
├── lib/ace/coworker/
│   ├── atoms/                    # Pure functions, no side effects
│   │   ├── number_generator.rb   # Queue number calculations (010, 041, 030.01)
│   │   ├── step_file_parser.rb   # Frontmatter + content parsing
│   │   └── step_sorter.rb        # Lexicographic ordering logic
│   ├── molecules/                # Composed operations with controlled I/O
│   │   ├── session_manager.rb    # Session YAML CRUD
│   │   ├── queue_scanner.rb      # Scan jobs/*.md, sort, parse
│   │   └── step_writer.rb        # Create/update step markdown files
│   ├── organisms/                # Business logic orchestration
│   │   └── workflow_executor.rb  # Queue state machine (start→advance→complete)
│   ├── models/                   # Pure data structures
│   │   ├── session.rb            # Session metadata
│   │   ├── step.rb               # Step with status, instructions, report
│   │   └── queue_state.rb        # Current queue snapshot
│   └── cli/
│       └── commands/
│           ├── start.rb          # ace-coworker start --config
│           ├── status.rb         # ace-coworker status
│           ├── report.rb         # ace-coworker report <file>
│           ├── fail.rb           # ace-coworker fail --message
│           ├── add.rb            # ace-coworker add "name"
│           └── retry_cmd.rb      # ace-coworker retry <step>
├── exe/ace-coworker
├── .ace-defaults/coworker/config.yml
├── test/
│   ├── atoms/
│   ├── molecules/
│   ├── organisms/
│   └── commands/
├── handbook/
│   └── workflow-instructions/
│       └── coworker-session.wf.md
└── ace-coworker.gemspec
```

### Technology Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| CLI Framework | dry-cli | ADR-023 standard, consistent with ace-search |
| Configuration | ace-support-config | ADR-022 cascade pattern |
| Session IDs | ace-support-timestamp | 8-char Base36 IDs (8or5kx format) |
| Frontmatter | ace-support-markdown | Safe YAML parsing in markdown |
| File I/O | Ruby stdlib (FileUtils) | No external dependencies |

### Key Design Decisions

1. **File-Based Queue**: Each step is a markdown file in `jobs/`. No database, no JSON index. State is derived from file names and frontmatter. Benefits:
   - Corruption isolation
   - Git-friendly
   - Human-readable
   - Resumable after crash

2. **Lexicographic Ordering**: Queue order = `Dir.glob("jobs/*.md").sort`. Numbering scheme:
   - Main: `010`, `020`, `030` (10-step gaps)
   - Subtask: `030.01`, `030.02`
   - Dynamic: `041` after `040`

3. **History Preservation**: Failed steps are NEVER deleted. Retry creates a new file linked to original via `added_by: retry_of:040`.

4. **Single In-Progress**: Only one step can have `status: in_progress` at a time. Enforced by workflow_executor.

## File Modifications

### Create

- `ace-coworker/lib/ace/coworker.rb`
  - Purpose: Module root, configuration loading (ADR-022 pattern)
  - Key components: `Ace::Coworker.config`, `Ace::Coworker.reset_config!`

- `ace-coworker/lib/ace/coworker/cli.rb`
  - Purpose: dry-cli registry with KNOWN_COMMANDS
  - Key components: DEFAULT_COMMAND="status", register all 6 commands

- `ace-coworker/lib/ace/coworker/atoms/number_generator.rb`
  - Purpose: Calculate next step number
  - Key methods: `next_main(last)` → 020, `next_after(base)` → 041, `subtask(parent, seq)` → 030.01

- `ace-coworker/lib/ace/coworker/atoms/step_file_parser.rb`
  - Purpose: Parse step markdown (frontmatter + body)
  - Key methods: `parse(content)` → {status:, name:, instructions:, report:}

- `ace-coworker/lib/ace/coworker/atoms/step_sorter.rb`
  - Purpose: Sort step files lexicographically
  - Key methods: `sort(filenames)` → ordered array

- `ace-coworker/lib/ace/coworker/molecules/session_manager.rb`
  - Purpose: Create/load/update session.yaml
  - Key methods: `create(name:, config_path:)`, `load(session_id)`, `update(attrs)`

- `ace-coworker/lib/ace/coworker/molecules/queue_scanner.rb`
  - Purpose: Build queue state from jobs/*.md
  - Key methods: `scan(jobs_dir)` → Array<Step>, `current` → Step|nil

- `ace-coworker/lib/ace/coworker/molecules/step_writer.rb`
  - Purpose: Create/update step markdown files
  - Key methods: `create(number, name, instructions)`, `update(path, attrs)`, `append_report(path, content)`

- `ace-coworker/lib/ace/coworker/organisms/workflow_executor.rb`
  - Purpose: State machine for queue operations
  - Key methods: `start(config)`, `advance(report)`, `fail(message)`, `add(name, instructions)`, `retry(step_ref)`

- `ace-coworker/lib/ace/coworker/models/session.rb`
  - Purpose: Session data model
  - Fields: `id`, `name`, `created_at`, `config_path`, `cache_dir`

- `ace-coworker/lib/ace/coworker/models/step.rb`
  - Purpose: Step data model
  - Fields: `number`, `name`, `status`, `instructions`, `report`, `error`, `added_by`

- `ace-coworker/lib/ace/coworker/cli/commands/start.rb`
  - Purpose: `ace-coworker start --config job.yaml`
  - Key behavior: Create session, initialize queue from config, display first step

- `ace-coworker/lib/ace/coworker/cli/commands/status.rb`
  - Purpose: `ace-coworker status`
  - Key behavior: Display queue table, current step instructions

- `ace-coworker/lib/ace/coworker/cli/commands/report.rb`
  - Purpose: `ace-coworker report <file>`
  - Key behavior: Append report to current step, advance queue

- `ace-coworker/lib/ace/coworker/cli/commands/fail.rb`
  - Purpose: `ace-coworker fail --message "..."`
  - Key behavior: Mark current step as failed, preserve error

- `ace-coworker/lib/ace/coworker/cli/commands/add.rb`
  - Purpose: `ace-coworker add "name" --instructions "..."`
  - Key behavior: Create new step after current in_progress

- `ace-coworker/lib/ace/coworker/cli/commands/retry_cmd.rb`
  - Purpose: `ace-coworker retry <step-ref>`
  - Key behavior: Create new step linked to failed original

- `ace-coworker/exe/ace-coworker`
  - Purpose: CLI entrypoint
  - Key behavior: `Ace::Coworker::CLI.start(ARGV)`

- `ace-coworker/.ace-defaults/coworker/config.yml`
  - Purpose: Default configuration
  - Key settings: `cache_dir: .cache/ace-coworker`

- `ace-coworker/ace-coworker.gemspec`
  - Purpose: Gem specification
  - Dependencies: ace-support-core, ace-support-config, dry-cli

- `ace-coworker/Rakefile`, `ace-coworker/CHANGELOG.md`, `ace-coworker/README.md`
  - Purpose: Standard gem files per ADR-020, ADR-021

- `ace-coworker/test/test_helper.rb`
  - Purpose: Test setup with AceTestCase

- `ace-coworker/test/atoms/*_test.rb`
  - Purpose: Unit tests for atoms

- `ace-coworker/test/molecules/*_test.rb`
  - Purpose: Unit tests for molecules

- `ace-coworker/test/commands/*_test.rb`
  - Purpose: CLI command integration tests

### Modify

None - this is a new gem.

### Delete

None - this is a new gem.

## Implementation Plan

### Planning Steps

* [x] Review behavioral specification for completeness
* [x] Analyze existing gem patterns (ace-search) for CLI structure
* [x] Identify dependencies (ace-support-config, ace-support-timestamp)
* [x] Design ATOM layer responsibilities

### Execution Steps

- [x] **Phase 1: Gem Scaffold**
  - [x] Create `ace-coworker/` directory structure
  - [x] Create gemspec with dependencies
  - [x] Create `lib/ace/coworker.rb` with config loading
  - [x] Create `lib/ace/coworker/version.rb`
  - [x] Create `exe/ace-coworker` entrypoint
  - [x] Create `.ace-defaults/coworker/config.yml`
  - [x] Create Rakefile, CHANGELOG.md, README.md
  > TEST: Gem Scaffold
  > Type: Action Validation
  > Assert: `bundle exec ruby -e "require 'ace/coworker'; puts Ace::Coworker::VERSION"` succeeds
  > Command: ace-test ace-coworker

- [x] **Phase 2: Models (Pure Data)**
  - [x] Create `models/session.rb` with immutable attributes
  - [x] Create `models/step.rb` with status enum
  - [x] Create `models/queue_state.rb` for queue snapshot
  > TEST: Models
  > Type: Unit Tests
  > Assert: Models are pure data carriers with no behavior
  > Command: ace-test ace-coworker test/models/

- [x] **Phase 3: Atoms (Pure Functions)**
  - [x] Create `atoms/number_generator.rb`
    - `next_main(nil)` → "010"
    - `next_main("040")` → "050"
    - `next_after("040")` → "041"
    - `subtask("030", 1)` → "030.01"
  - [x] Create `atoms/step_file_parser.rb`
    - Parse frontmatter + body
    - Extract status, name, instructions, report sections
  - [x] Create `atoms/step_sorter.rb`
    - Lexicographic sort with hierarchical awareness
  > TEST: Atoms
  > Type: Unit Tests
  > Assert: All atom functions are pure (same input → same output)
  > Command: ace-test ace-coworker test/atoms/

- [x] **Phase 4: Molecules (I/O Operations)**
  - [x] Create `molecules/session_manager.rb`
    - Create/load/update session.yaml
    - Generate session ID using ace-support-timestamp
  - [x] Create `molecules/queue_scanner.rb`
    - Glob jobs/*.md, sort, parse each
    - Build QueueState from files
  - [x] Create `molecules/step_writer.rb`
    - Create new step files with frontmatter
    - Update existing step frontmatter
    - Append report content to step file
  > TEST: Molecules
  > Type: Integration Tests
  > Assert: File operations work correctly with temp directories
  > Command: ace-test ace-coworker test/molecules/

- [x] **Phase 5: Organisms (Business Logic)**
  - [x] Create `organisms/workflow_executor.rb`
    - `start(config_path)`: Create session, populate initial queue, set first step in_progress
    - `advance(report_path)`: Complete current step, advance to next
    - `fail(message)`: Mark current step as failed
    - `add(name, instructions)`: Insert new step after current
    - `retry(step_ref)`: Create new step linked to failed original
  > TEST: Workflow Executor
  > Type: Integration Tests
  > Assert: State machine transitions work correctly
  > Command: ace-test ace-coworker test/organisms/

- [x] **Phase 6: CLI Commands**
  - [x] Create `cli.rb` with dry-cli registry
  - [x] Create `commands/start.rb`
  - [x] Create `commands/status.rb`
  - [x] Create `commands/report.rb`
  - [x] Create `commands/fail.rb`
  - [x] Create `commands/add.rb`
  - [x] Create `commands/retry_cmd.rb` (avoid Ruby keyword)
  > TEST: CLI Commands
  > Type: Command Tests
  > Assert: All commands return correct exit codes
  > Command: ace-test ace-coworker test/commands/

- [x] **Phase 7: E2E Test Scenario**
  - [x] Create E2E test: MT-COWORKER-001 (Work Queue Session Lifecycle)
    - Start session from job.yaml
    - Check status shows queue
    - Report completion, verify advancement
    - Fail a step, verify preservation
    - Add dynamic step
    - Retry failed step
    - Complete workflow
  > TEST: E2E Session Lifecycle
  > Type: End-to-End Test
  > Assert: Full workflow executes correctly
  > Command: ace-test ace-coworker test/e2e/

- [x] **Phase 8: Documentation**
  - [x] Update README.md with installation and usage
  - [x] Create handbook/workflow-instructions/coworker-session.wf.md
  - [x] Update CHANGELOG.md

## Test Case Summary

| Test Type | Coverage | Priority |
|-----------|----------|----------|
| Unit (atoms) | NumberGenerator, StepFileParser, StepSorter | High |
| Unit (molecules) | SessionManager, QueueScanner, StepWriter | High |
| Unit (organisms) | WorkflowExecutor state transitions | High |
| Command | All 6 CLI commands | High |
| E2E | MT-COWORKER-001 full lifecycle | High |
| Edge Cases | Empty queue, all done, concurrent add | Medium |

## Risk Assessment

### Technical Risks

- **Risk:** File corruption during write
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Atomic writes (write to temp, rename)
  - **Rollback:** Files are immutable history; no rollback needed

- **Risk:** Numbering collision on concurrent add
  - **Probability:** Low (single session per directory in MVP)
  - **Impact:** Low
  - **Mitigation:** Check existence before write, increment if collision
  - **Rollback:** Manual file rename

### Integration Risks

- **Risk:** ace-support-timestamp API changes
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Pin dependency version, use simple timestamp.generate call

## Acceptance Criteria

- [x] AC 1: All 6 CLI commands implemented and tested
- [x] AC 2: Queue state persists across process restarts
- [x] AC 3: Failed steps are preserved in queue history
- [x] AC 4: Dynamic step addition works correctly
- [x] AC 5: Retry creates new linked step
- [x] AC 6: E2E test MT-COWORKER-001 passes
- [x] AC 7: All tests pass via `ace-test ace-coworker`

## References

- Related task: v.0.9.0+task.234 (parent orchestrator)
- Dependent task: v.0.9.0+task.238 (ace-queue extraction)
- Reference gem: ace-search (CLI patterns)
- Existing specs (reference only): 234.01-234.08 subtasks
- Existing UX docs: `.ace-taskflow/v.0.9.0/tasks/234-gem-add/ux/usage.md`