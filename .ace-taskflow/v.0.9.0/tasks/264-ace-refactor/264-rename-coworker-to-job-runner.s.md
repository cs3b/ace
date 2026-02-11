---
id: v.0.9.0+task.264
status: in-progress
priority: medium
estimate: 6h
dependencies: []
worktree:
  branch: 264-rename-ace-coworker-to-ace-job-runner
  path: "../ace-task.264"
  created_at: '2026-02-11 22:48:18'
  updated_at: '2026-02-11 22:48:18'
  target_branch: main
---

# Rename ace-coworker to ace-job-runner

## 0. Directory Audit

_Command run:_

```bash
ace-nav guide://
```

_Relevant guides:_

```
guide://atom-pattern
guide://cli-dry-cli
guide://mono-repo-patterns
guide://coding-standards
```

## Objective

Align the package name with its actual function. "ace-coworker" describes a collaborator; "ace-job-runner" describes what the tool does — run jobs (sequences of steps) with durable state tracking. The internal concept "session" becomes "job" since that's what it represents. Additionally, simplify the skill surface by combining prepare + create into a single `/ace:job-start` entry point.

## Behavioral Specification

### User Experience

- **Input**: No user input required — internal rename with identical CLI interface
- **Process**: All CLI commands change from `ace-coworker <cmd>` to `ace-job <cmd>`. Ruby module `Ace::Coworker` → `Ace::JobRunner`. Internal "session" → "job". Skills `/ace:coworker-*` → `/ace:job-*`. New combined `/ace:job-start` skill.
- **Output**: Identical functionality under clearer naming

### Interface Contract

```bash
# CLI (renamed from ace-coworker)
ace-job create job.yaml        # Create job from YAML spec
ace-job status [--flat]        # Show current queue state
ace-job report <file>          # Complete current step with report
ace-job fail --message "msg"   # Mark current step as failed
ace-job add <name> [opts]      # Add step dynamically
ace-job retry <step-ref>       # Retry failed step
```

```bash
# Skills (renamed from /ace:coworker-*)
/ace:job-start [preset] [args]  # NEW: Combined prepare + create
/ace:job-prepare [preset]       # Prepare job.yaml from preset
/ace:job-create job.yaml        # Create job from YAML
/ace:job-drive                  # Drive execution through active job
```

### Terminology Mapping

| Current | New | Notes |
|---------|-----|-------|
| Package: `ace-coworker` | `ace-job-runner` | Gem name |
| Binary: `ace-coworker` | `ace-job` | CLI command |
| Module: `Ace::Coworker` | `Ace::JobRunner` | Ruby namespace |
| Session | Job | Execution instance |
| SessionManager | JobManager | Molecule |
| WorkflowExecutor | JobExecutor | Organism |
| session.yaml | job.yaml | State file in cache |
| `.cache/ace-coworker/` | `.cache/ace-job/` | Cache directory |
| `.ace-defaults/coworker/` | `.ace-defaults/job/` | Config defaults |
| Config namespace: `coworker` | `job` | Config cascade |
| Step | Step | **No change** |
| QueueState | QueueState | **No change** |

### Success Criteria

- [ ] `ace-job` CLI responds to all 6 commands with identical behavior to `ace-coworker`
- [ ] `ace-job --version` shows correct version
- [ ] All existing unit tests pass under new naming (~18 test files)
- [ ] Ruby module `Ace::JobRunner` fully replaces `Ace::Coworker`
- [ ] Config cascade resolves via `resolve_namespace("job")`
- [ ] WFI protocols resolve: `wfi://create-job`, `wfi://drive-job`, `wfi://prepare-job`
- [ ] New combined `/ace:job-start` skill works (prepare + create in one invocation)
- [ ] `ace-test-suite` passes (no broken cross-package references)
- [ ] No references to `ace-coworker` remain in active code (historical task files excluded)

## Scope of Work

- **Package Rename**: Directory, gemspec, executables, module namespace
- **Concept Rename**: Session → Job in models, molecules, organisms, CLI commands
- **Config Rename**: Defaults directory, config namespace, cache directory, WFI sources
- **Skill Simplification**: Combine prepare + create skills, rename all 3 existing skills
- **Documentation**: Update tools.md, README, usage docs, CHANGELOG
- **Test Updates**: All test files updated, E2E tests updated

### Deliverables

#### Rename (directory/file moves)

- `ace-coworker/` → `ace-job-runner/`
- `ace-coworker/lib/ace/coworker/` → `ace-job-runner/lib/ace/job_runner/`
- `ace-coworker/lib/ace/coworker.rb` → `ace-job-runner/lib/ace/job_runner.rb`
- `ace-coworker/exe/ace-coworker` → `ace-job-runner/exe/ace-job`
- `bin/ace-coworker` → `bin/ace-job`
- `ace-coworker/.ace-defaults/coworker/` → `ace-job-runner/.ace-defaults/job/`
- `ace-coworker/.ace-defaults/nav/protocols/wfi-sources/ace-coworker.yml` → `ace-job-runner/.ace-defaults/nav/protocols/wfi-sources/ace-job-runner.yml`
- `.ace/nav/protocols/wfi-sources/ace-coworker.yml` → `.ace/nav/protocols/wfi-sources/ace-job-runner.yml`
- `ace-coworker/ace-coworker.gemspec` → `ace-job-runner/ace-job-runner.gemspec`
- `.claude/skills/ace_coworker-prepare/` → `.claude/skills/ace_job-prepare/`
- `.claude/skills/ace_coworker-create-session/` → `.claude/skills/ace_job-create/`
- `.claude/skills/ace_coworker-drive-session/` → `.claude/skills/ace_job-drive/`
- `ace-coworker/handbook/workflow-instructions/create-coworker-session.wf.md` → `ace-job-runner/handbook/workflow-instructions/create-job.wf.md`
- `ace-coworker/handbook/workflow-instructions/drive-coworker-session.wf.md` → `ace-job-runner/handbook/workflow-instructions/drive-job.wf.md`
- `ace-coworker/handbook/workflow-instructions/prepare-coworker-job.wf.md` → `ace-job-runner/handbook/workflow-instructions/prepare-job.wf.md`
- `ace-coworker/models/session.rb` → `ace-job-runner/models/job.rb` (class rename)
- `ace-coworker/molecules/session_manager.rb` → `ace-job-runner/molecules/job_manager.rb` (class rename)
- `ace-coworker/organisms/workflow_executor.rb` → `ace-job-runner/organisms/job_executor.rb` (class rename)

#### Create

- `.claude/skills/ace_job-start/SKILL.md` — new combined skill (prepare + create)
- `ace-job-runner/handbook/workflow-instructions/start-job.wf.md` — new combined workflow

#### Modify (~60 files)

- `Gemfile` — gem reference
- `.ace/git/commit.yml` — scope definition
- `docs/tools.md` — CLI reference table
- `ace-review/.ace-defaults/review/presets/batch.yml` — coworker reference
- ~22 Ruby source files (module/class renames, require paths, string references)
- ~19 test files (require paths, class names, namespace references)
- 3 workflow instruction files (content updates)
- 3 skill SKILL.md files (name, description, tool refs, bundle refs)
- 2 WFI source configs
- `ace-job-runner/README.md`
- `ace-job-runner/CHANGELOG.md`
- `ace-job-runner/docs/usage.md`
- `ace-job-runner/docs/exit-codes.md`
- `ace-job-runner/handbook/guides/fork-context.g.md`

#### Delete (replaced by renames)

- `ace-coworker/` directory (entire tree)
- Old `.claude/skills/ace_coworker-*` directories
- Old `.ace/nav/protocols/wfi-sources/ace-coworker.yml`

## Phases

1. Package structure rename (git mv for history preservation)
2. Ruby module + concept rename (find-and-replace across all source files)
3. Config, WFI, skill updates
4. New combined skill/workflow creation
5. Documentation updates
6. Test verification

## Implementation Plan

### Planning Steps

* [x] Research industry naming conventions for agent job queue tools
* [x] Inventory all files referencing ace-coworker (274 module refs, 29 gem name refs, 19 test files)
* [x] Confirm no external package dependencies on ace-coworker (isolated change)
* [x] Define terminology mapping (Session→Job, Coworker→JobRunner)
* [x] Identify 7 string replacement patterns needed across codebase

### Execution Steps

#### Phase 1: Git-Based Directory & File Renames

- [ ] Rename package directory: `git mv ace-coworker ace-job-runner`
- [ ] Rename lib path: `git mv ace-job-runner/lib/ace/coworker ace-job-runner/lib/ace/job_runner`
- [ ] Rename main module file: `git mv ace-job-runner/lib/ace/coworker.rb ace-job-runner/lib/ace/job_runner.rb`
- [ ] Rename executable: `git mv ace-job-runner/exe/ace-coworker ace-job-runner/exe/ace-job`
- [ ] Rename bin wrapper: `git mv bin/ace-coworker bin/ace-job`
- [ ] Rename gemspec: `git mv ace-job-runner/ace-coworker.gemspec ace-job-runner/ace-job-runner.gemspec`
- [ ] Rename defaults dir: `git mv ace-job-runner/.ace-defaults/coworker ace-job-runner/.ace-defaults/job`
- [ ] Rename WFI source (package): `git mv ace-job-runner/.ace-defaults/nav/protocols/wfi-sources/ace-coworker.yml ace-job-runner/.ace-defaults/nav/protocols/wfi-sources/ace-job-runner.yml`
- [ ] Rename WFI source (root): `git mv .ace/nav/protocols/wfi-sources/ace-coworker.yml .ace/nav/protocols/wfi-sources/ace-job-runner.yml`
- [ ] Rename model file: `git mv ace-job-runner/lib/ace/job_runner/models/session.rb ace-job-runner/lib/ace/job_runner/models/job.rb`
- [ ] Rename molecule file: `git mv ace-job-runner/lib/ace/job_runner/molecules/session_manager.rb ace-job-runner/lib/ace/job_runner/molecules/job_manager.rb`
- [ ] Rename organism file: `git mv ace-job-runner/lib/ace/job_runner/organisms/workflow_executor.rb ace-job-runner/lib/ace/job_runner/organisms/job_executor.rb`
- [ ] Rename workflow files:
  - `git mv ace-job-runner/handbook/workflow-instructions/create-coworker-session.wf.md ace-job-runner/handbook/workflow-instructions/create-job.wf.md`
  - `git mv ace-job-runner/handbook/workflow-instructions/drive-coworker-session.wf.md ace-job-runner/handbook/workflow-instructions/drive-job.wf.md`
  - `git mv ace-job-runner/handbook/workflow-instructions/prepare-coworker-job.wf.md ace-job-runner/handbook/workflow-instructions/prepare-job.wf.md`
- [ ] Rename skill directories:
  - `git mv .claude/skills/ace_coworker-prepare .claude/skills/ace_job-prepare`
  - `git mv .claude/skills/ace_coworker-create-session .claude/skills/ace_job-create`
  - `git mv .claude/skills/ace_coworker-drive-session .claude/skills/ace_job-drive`
  > TEST: All renames preserved in git
  > Type: Pre-condition Check
  > Assert: `git status` shows renames, not delete+add
  > Command: git status --short | head -40

#### Phase 2: Ruby Module & Concept Renames

String replacements across all source files (7 replacement patterns):

- [ ] **Pattern 1** — Module declarations (22 lib files): `module Coworker` → `module JobRunner`
- [ ] **Pattern 2** — Gem/package name refs (6 files): `"ace-coworker"` → `"ace-job-runner"`
  - gemspec, main module, cli.rb, bin wrapper, exe, test_helper
- [ ] **Pattern 3** — Full namespace refs (22+ files): `Ace::Coworker::` → `Ace::JobRunner::` and `Ace::Coworker.` → `Ace::JobRunner.`
- [ ] **Pattern 4** — Config directory refs (main module):
  - `".cache/ace-coworker"` → `".cache/ace-job"`
  - `".ace-defaults", "coworker"` → `".ace-defaults", "job"`
  - `resolve_namespace("coworker")` → `resolve_namespace("job")`
- [ ] **Pattern 5** — CLI command examples in error messages (organism + commands):
  - `'ace-coworker create'` → `'ace-job create'`
  - `'ace-coworker add'` → `'ace-job add'`
  - `'ace-coworker report'` → `'ace-job report'`
  - etc.
- [ ] **Pattern 6** — Warning/debug prefixes (2 files): `"[ace-coworker]"` → `"[ace-job]"`
- [ ] **Pattern 7** — Concept rename Session→Job in model class:
  - `Models::Session` → `Models::Job`
  - `session_file` → `job_file`
  - `SessionManager` → `JobManager`
  - `WorkflowExecutor` → `JobExecutor`
  - `session` parameter names → `job` where referring to the model
  - Update QueueState: `session:` parameter → `job:` parameter
  - Update `session.yaml` file references → `job.yaml`
- [ ] **Pattern 8** — Require path updates (all files):
  - `require_relative "coworker/"` → `require_relative "job_runner/"`
  - `require "ace/coworker"` → `require "ace/job_runner"`
  > TEST: All patterns applied
  > Type: Action Validation
  > Assert: No remaining `Ace::Coworker` references in lib/
  > Command: grep -r "Ace::Coworker" ace-job-runner/lib/ || echo "CLEAN"

#### Phase 3: Test File Updates

- [ ] Update `test/test_helper.rb`:
  - `require "ace/coworker"` → `require "ace/job_runner"`
  - `AceCoworkerTestCase` → `AceJobRunnerTestCase`
  - `"ace-coworker-test"` → `"ace-job-runner-test"`
- [ ] Update all 19 test files:
  - Class inheritance: `< AceCoworkerTestCase` → `< AceJobRunnerTestCase`
  - Namespace refs: `Ace::Coworker::` → `Ace::JobRunner::`
  - String refs: `"ace-coworker"` → `"ace-job-runner"` / `"ace-job"`
- [ ] Update E2E test files: command references `ace-coworker` → `ace-job`
  > TEST: Unit tests pass
  > Type: Action Validation
  > Assert: All tests pass
  > Command: ace-test ace-job-runner

#### Phase 4: Config, WFI & Skill Updates

- [ ] Update WFI source configs (both copies): `name: ace-coworker` → `name: ace-job-runner`, update description
- [ ] Update `.ace/git/commit.yml`: scope definition for ace-job-runner
- [ ] Update root `Gemfile`: `gem 'ace-coworker', path: 'ace-coworker'` → `gem 'ace-job-runner', path: 'ace-job-runner'`
- [ ] Update skill SKILL.md files (3 files):
  - `.claude/skills/ace_job-prepare/SKILL.md`: name → `ace:job-prepare`, source → `ace-job-runner`, tool refs → `Bash(ace-job:*)`, bundle → `wfi://prepare-job`
  - `.claude/skills/ace_job-create/SKILL.md`: name → `ace:job-create`, source → `ace-job-runner`, bundle → `wfi://create-job`
  - `.claude/skills/ace_job-drive/SKILL.md`: name → `ace:job-drive`, source → `ace-job-runner`, bundle → `wfi://drive-job`
- [ ] Update workflow instruction content (3 files): replace all `ace-coworker` → `ace-job` in instructions, examples, commands
- [ ] Update `ace-review/.ace-defaults/review/presets/batch.yml`: coworker → job-runner reference

#### Phase 5: New Combined Skill & Workflow

- [ ] Create `.claude/skills/ace_job-start/SKILL.md`:
  ```yaml
  name: ace:job-start
  description: Create and start a job from preset or instructions (prepare + create)
  user-invocable: true
  allowed-tools: [Bash(ace-job:*), Bash(ace-bundle:*), Read, Write, AskUserQuestion]
  argument-hint: "[preset-name] [--taskref value]"
  source: ace-job-runner
  ```
  Instructions: run prepare-job workflow, then create-job workflow sequentially
- [ ] Create `ace-job-runner/handbook/workflow-instructions/start-job.wf.md`:
  - Combines prepare + create steps
  - References: `wfi://prepare-job` → `wfi://create-job` → output session info

#### Phase 6: Documentation Updates

- [ ] Update `docs/tools.md`: Workforce Management table → `ace-job status`, `ace-job create CONFIG`
- [ ] Update `ace-job-runner/README.md`: title, all examples, installation instructions
- [ ] Update `ace-job-runner/CHANGELOG.md`: Add `## [Unreleased]` entry documenting the rename
- [ ] Update `ace-job-runner/docs/usage.md`: all CLI examples
- [ ] Update `ace-job-runner/docs/exit-codes.md`: command references
- [ ] Update `ace-job-runner/handbook/guides/fork-context.g.md`: all `ace-coworker` refs

#### Phase 7: Verification

- [ ] Run `bundle install` to regenerate Gemfile.lock
  > TEST: Bundle resolves
  > Type: Action Validation
  > Assert: No errors
  > Command: bundle install
- [ ] Run unit tests: `ace-test ace-job-runner`
  > TEST: All tests pass
  > Type: Action Validation
  > Assert: 0 failures, 0 errors
  > Command: ace-test ace-job-runner
- [ ] Verify CLI: `ace-job status` (expect "no active job" error = correct)
- [ ] Verify CLI: `ace-job --version` (shows correct version)
- [ ] Verify WFI resolution: `ace-bundle wfi://create-job`, `ace-bundle wfi://drive-job`, `ace-bundle wfi://prepare-job`
- [ ] Verify no stale references: `grep -r "ace-coworker" ace-job-runner/lib/ ace-job-runner/test/` → should return nothing
- [ ] Run full suite: `ace-test-suite`
  > TEST: Full monorepo passes
  > Type: Action Validation
  > Assert: No broken cross-package references
  > Command: ace-test-suite

## Acceptance Criteria

- [ ] AC 1: Package fully renamed — directory, gemspec, executables, module namespace all use `ace-job-runner`/`Ace::JobRunner`
- [ ] AC 2: Internal "session" concept renamed to "job" — models, molecules, organisms, CLI messages
- [ ] AC 3: All 3 existing skills renamed and working under `/ace:job-*` names
- [ ] AC 4: New `/ace:job-start` combined skill created and functional
- [ ] AC 5: WFI protocol resolution works for all renamed workflows
- [ ] AC 6: All unit tests pass (`ace-test ace-job-runner`)
- [ ] AC 7: Full monorepo test suite passes (`ace-test-suite`)
- [ ] AC 8: No remaining references to `ace-coworker` in active code (taskflow history excluded)

## Out of Scope

- ❌ Historical `.ace-taskflow/` task files (records of past work)
- ❌ ADR documents (historical decisions)
- ❌ Migrating existing `.cache/ace-coworker/` session data
- ❌ Functional changes to the queue/step execution logic
- ❌ Task 238 (ace-queue extraction) — independent effort
- ❌ Task 240 advanced features — coordinate naming but don't implement

## References

- Plan file: `.claude/plans/squishy-plotting-rain.md`
- Current package: `ace-coworker/` (v0.5.3)
- Related tasks: 238 (ace-queue), 240 (advanced features), 236 (workflow templates), 242 (review verification)
- Industry research: Sidekiq, Bull, Temporal, GitHub Actions, OpenAI Agents SDK, Claude Agent SDK