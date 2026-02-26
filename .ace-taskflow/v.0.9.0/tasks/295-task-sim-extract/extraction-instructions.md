# ace-sim Extraction Instructions

## Context

Task 285 built a next-phase simulation feature inside ace-taskflow (worktree at `/home/mc/ace-task.285`, branch `285-iterative-review-with-next-phase-dry-runs`). This feature must be extracted into a standalone `ace-sim` gem **before** merging the worktree to main, because ace-taskflow is being fully decomposed and deleted (tasks 290-294).

The simulation feature runs read-only, forward-looking dry-runs of downstream workflow phases (idea→draft→plan, task→plan) to surface missing context and decision gaps before committing to state transitions.

## What ace-sim Does

- **For ideas**: Simulates draft + plan phases, synthesizes findings, writes questions back to the idea
- **For tasks**: Simulates plan phase, synthesizes findings, writes questions back to the task
- **Completion gate**: Validates checklist completion in task specs before allowing "done" transition
- **Cache**: All simulation artifacts stored in `.cache/ace-sim/simulations/<b36ts-run-id>/`
- **Trigger policy**: Auto-trigger on reviews (configurable), manual trigger always available

## Files to Extract (from worktree)

All paths relative to `ace-taskflow/` in the worktree.

### New files (core simulation — move entirely to ace-sim)

**Model (1):**
- `lib/ace/taskflow/models/simulation_session.rb` → `ace-sim/lib/ace/sim/models/simulation_session.rb`

**Molecules (8):**
- `lib/ace/taskflow/molecules/idea_simulation_writeback.rb` → `ace-sim/lib/ace/sim/molecules/idea_simulation_writeback.rb`
- `lib/ace/taskflow/molecules/task_simulation_writeback.rb` → `ace-sim/lib/ace/sim/molecules/task_simulation_writeback.rb`
- `lib/ace/taskflow/molecules/simulation_writeback_mixin.rb` → `ace-sim/lib/ace/sim/molecules/simulation_writeback_mixin.rb`
- `lib/ace/taskflow/molecules/simulation_session_store.rb` → `ace-sim/lib/ace/sim/molecules/simulation_session_store.rb`
- `lib/ace/taskflow/molecules/simulation_synthesis_builder.rb` → `ace-sim/lib/ace/sim/molecules/simulation_synthesis_builder.rb`
- `lib/ace/taskflow/molecules/next_phase_stage_executor.rb` → `ace-sim/lib/ace/sim/molecules/next_phase_stage_executor.rb`
- `lib/ace/taskflow/molecules/next_phase_trigger_policy.rb` → `ace-sim/lib/ace/sim/molecules/next_phase_trigger_policy.rb`
- `lib/ace/taskflow/molecules/task_completion_gate.rb` → `ace-sim/lib/ace/sim/molecules/task_completion_gate.rb`

**Organism (1):**
- `lib/ace/taskflow/organisms/next_phase_simulation_runner.rb` → `ace-sim/lib/ace/sim/organisms/next_phase_simulation_runner.rb`

**CLI (1):**
- `lib/ace/taskflow/cli/commands/review_next_phase.rb` → `ace-sim/lib/ace/sim/cli/commands/review_next_phase.rb`

**Tests (10 — move to ace-sim):**
- `test/models/simulation_session_test.rb`
- `test/molecules/idea_simulation_writeback_test.rb`
- `test/molecules/task_simulation_writeback_test.rb`
- `test/molecules/simulation_session_store_test.rb`
- `test/molecules/simulation_synthesis_builder_test.rb`
- `test/molecules/next_phase_stage_executor_test.rb`
- `test/molecules/next_phase_trigger_policy_test.rb`
- `test/molecules/task_completion_gate_test.rb`
- `test/organisms/next_phase_simulation_runner_test.rb`
- `test/commands/review_next_phase_command_test.rb`

**Test that stays with ace-task (NOT moved):**
- `test/commands/task/done_test.rb` — completion gate integration test for the `done` command

**Workflows (2):**
- `handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md` → `ace-sim/handbook/workflow-instructions/sim/simulate-next-phase-draft.wf.md`
- `handbook/workflow-instructions/task/simulate-next-phase-plan.wf.md` → `ace-sim/handbook/workflow-instructions/sim/simulate-next-phase-plan.wf.md`

### Modified files (integration hooks — must be separated)

These existing ace-taskflow files were modified to integrate simulation. The simulation-specific changes need to be pulled out:

**1. `lib/ace/taskflow/organisms/task_manager.rb`**
- Added: `require_relative "../molecules/task_completion_gate"`
- Added: `complete_task` now accepts `allow_incomplete:` param
- Added: `evaluate_completion_gate`, `format_completion_gate_block_message`, `build_completion_gate_warning` private methods
- **Extraction**: The completion gate integration stays with the task manager (future ace-task). ace-sim provides `TaskCompletionGate` as a standalone molecule that ace-task calls.

**2. `lib/ace/taskflow/cli/commands/task/done.rb`**
- Added: `--allow-incomplete` option
- Added: Gate warning output
- **Extraction**: This stays with ace-task CLI. It calls ace-sim's completion gate via the task manager.

**3. `lib/ace/taskflow/cli.rb`**
- Added: `register "review-next-phase"` command + require
- **Extraction**: Remove from ace-taskflow CLI. ace-sim gets its own `exe/ace-sim` with the `review-next-phase` command.

**4. `lib/ace/taskflow/configuration.rb`**
- Added: ~40 lines of `next_phase_*` config methods and `completion_gate_*` methods
- **Extraction**: Move to ace-sim's own configuration. ace-sim uses ace-support-config independently.

**5. `.ace-defaults/taskflow/config.yml`**
- Added: `review.next_phase` config block (22 lines) and `task.completion_gate` block (3 lines)
- **Extraction**: Move to `.ace-defaults/sim/config.yml` in ace-sim.

## Namespace Transformation

All classes change from `Ace::Taskflow::*` to `Ace::Sim::*`:

```
Ace::Taskflow::Models::SimulationSession          → Ace::Sim::Models::SimulationSession
Ace::Taskflow::Molecules::SimulationSessionStore  → Ace::Sim::Molecules::SimulationSessionStore
Ace::Taskflow::Molecules::SimulationSynthesisBuilder → Ace::Sim::Molecules::SimulationSynthesisBuilder
Ace::Taskflow::Molecules::SimulationWritebackMixin   → Ace::Sim::Molecules::SimulationWritebackMixin
Ace::Taskflow::Molecules::IdeaSimulationWriteback    → Ace::Sim::Molecules::IdeaSimulationWriteback
Ace::Taskflow::Molecules::TaskSimulationWriteback    → Ace::Sim::Molecules::TaskSimulationWriteback
Ace::Taskflow::Molecules::NextPhaseStageExecutor     → Ace::Sim::Molecules::NextPhaseStageExecutor
Ace::Taskflow::Molecules::NextPhaseTriggerPolicy     → Ace::Sim::Molecules::NextPhaseTriggerPolicy
Ace::Taskflow::Molecules::TaskCompletionGate         → Ace::Sim::Molecules::TaskCompletionGate
Ace::Taskflow::Organisms::NextPhaseSimulationRunner  → Ace::Sim::Organisms::NextPhaseSimulationRunner
Ace::Taskflow::CLI::Commands::ReviewNextPhase        → Ace::Sim::CLI::Commands::ReviewNextPhase
```

## Integration Points (how ace-sim connects to ace-task / ace-idea)

### 1. Source Resolution
`NextPhaseSimulationRunner#resolve_source!` currently calls `TaskManager` and `IdeaLoader` to find items. After extraction, ace-sim must NOT depend on ace-task or ace-idea directly. Instead:

- ace-sim reads `.ace-tasks/` and `.ace-ideas/` directories directly using its own lightweight resolver
- It only needs to find and read markdown files — no need for full TaskManager/IdeaManager
- Pattern: scan for `*.s.md` in `.ace-tasks/`, `*.idea.s.md` in `.ace-ideas/`, resolve shortcuts by suffix match
- Returns `{ type: "task"|"idea", path: "/path/to/file.md", content: "..." }`

### 2. Writeback
`IdeaSimulationWriteback` and `TaskSimulationWriteback` write sections into item files. After extraction:
- ace-sim writes directly to the file path (it already does `File.read`/`File.write`)
- No dependency needed — just file path as input

### 3. Completion Gate
`TaskCompletionGate` is called by `TaskManager#complete_task`. After extraction:
- ace-task optionally requires ace-sim and calls `Ace::Sim::Molecules::TaskCompletionGate.evaluate(content:)`
- If ace-sim is not installed, the gate is skipped (graceful degradation)
- This is a soft/optional dependency, not a hard one

```ruby
# In future ace-task's task_manager — optional integration pattern
begin
  require "ace/sim/molecules/task_completion_gate"
  gate = Ace::Sim::Molecules::TaskCompletionGate
rescue LoadError
  gate = nil  # ace-sim not installed, skip completion gate
end
```

### 4. CLI Command
Currently `review-next-phase` is registered in ace-taskflow's CLI. After extraction:
- ace-sim gets its own `exe/ace-sim` entry point
- Command becomes: `ace-sim review-next-phase --source <ref> --modes draft,plan`

### 5. Config
Currently reads from `Ace::Taskflow.configuration`. After extraction:
- ace-sim uses ace-support-config with its own `.ace-defaults/sim/config.yml`
- Config key changes from `taskflow.review.next_phase.*` to `sim.review.next_phase.*`

## ace-sim Gem Structure

```
ace-sim/
  ace-sim.gemspec
  exe/ace-sim
  lib/ace/sim.rb
  lib/ace/sim/version.rb
  lib/ace/sim/configuration.rb
  lib/ace/sim/
    models/simulation_session.rb
    molecules/simulation_session_store.rb
    molecules/simulation_synthesis_builder.rb
    molecules/simulation_writeback_mixin.rb
    molecules/idea_simulation_writeback.rb
    molecules/task_simulation_writeback.rb
    molecules/next_phase_stage_executor.rb
    molecules/next_phase_trigger_policy.rb
    molecules/task_completion_gate.rb
    organisms/next_phase_simulation_runner.rb
    cli.rb
    cli/commands/review_next_phase.rb
  .ace-defaults/sim/config.yml
  handbook/
    workflow-instructions/sim/simulate-next-phase-draft.wf.md
    workflow-instructions/sim/simulate-next-phase-plan.wf.md
  test/
    test_helper.rb
    models/simulation_session_test.rb
    molecules/  (7 test files)
    organisms/next_phase_simulation_runner_test.rb
    commands/review_next_phase_command_test.rb
  CHANGELOG.md
  README.md
```

## Dependencies

```ruby
# ace-sim.gemspec
spec.add_dependency "ace-b36ts", "~> 0.7"          # Run ID generation
spec.add_dependency "ace-support-config", "~> 0.7"  # Config cascade
spec.add_dependency "ace-support-core", "~> 0.25"   # CLI base (DryCli::Base)
spec.add_dependency "ace-support-markdown", "~> 0.2" # Frontmatter reading
spec.add_dependency "dry-cli", "~> 1.0"             # CLI framework
# NO dependency on ace-task, ace-idea, or ace-taskflow
```

## Extraction Steps

### Step 1: Create ace-sim gem scaffold
- Copy gem structure from another ace-* gem (e.g., ace-b36ts) as template
- Set up namespace `Ace::Sim`, version `0.1.0`
- Add gemspec with dependencies listed above
- Add to monorepo Gemfile

### Step 2: Move simulation files
- Copy all 11 new Ruby source files from ace-taskflow in the worktree
- Rename namespace from `Ace::Taskflow` → `Ace::Sim` in every file
- Update all `require_relative` paths
- Remove `require_relative "task_manager"` and `require_relative "../molecules/idea_loader"` from the runner — replace with lightweight source resolution

### Step 3: Decouple source resolution
The runner currently does:
```ruby
@task_manager = task_manager || Organisms::TaskManager.new
@idea_loader = idea_loader || Molecules::IdeaLoader.new
```
Replace with a lightweight `SourceResolver` that:
- Scans `.ace-tasks/` for `*.s.md` files (suffix match on shortcut)
- Scans `.ace-ideas/` for `*.idea.s.md` files (suffix match on shortcut)
- Returns `{ type: "task"|"idea", path: "/path/to/file.md", content: "..." }`
- No need for full TaskManager/IdeaManager — just file discovery + read

### Step 4: Extract config
- Create `.ace-defaults/sim/config.yml` with the `review.next_phase` block
- Create `Ace::Sim::Configuration` that reads from ace-support-config
- Remove `next_phase_*` and `completion_gate_*` methods from ace-taskflow's configuration.rb
- Remove `review.next_phase` and `task.completion_gate` blocks from ace-taskflow's config.yml

### Step 5: Move tests
- Copy all 10 test files
- Update namespaces and requires
- Create ace-sim test_helper.rb
- Verify: `ace-test ace-sim`

### Step 6: Move workflows
- Move the 2 `.wf.md` files to `ace-sim/handbook/workflow-instructions/sim/`

### Step 7: Create CLI
- Create `exe/ace-sim` with SIGINT handling (copy pattern from other ace-* gems)
- Create `lib/ace/sim/cli.rb` with dry-cli registry
- Register `review-next-phase` command

### Step 8: Clean ace-taskflow integration hooks
Back in ace-taskflow within the worktree, remove simulation-specific additions:
- `cli.rb` — remove `register "review-next-phase"` and its require
- `configuration.rb` — remove all `next_phase_*` and `completion_gate_*` methods
- `.ace-defaults/taskflow/config.yml` — remove `review.next_phase` and `task.completion_gate` blocks
- `organisms/task_manager.rb` — keep completion gate call but make it optional (graceful if ace-sim not installed):
  ```ruby
  begin
    require "ace/sim/molecules/task_completion_gate"
  rescue LoadError
    # ace-sim not installed, skip completion gate
  end
  ```
- `cli/commands/task/done.rb` — keep `--allow-incomplete` flag, works with or without ace-sim

### Step 9: Verify
1. `ace-test ace-sim` — all simulation tests pass
2. `ace-sim review-next-phase --source <ref> --modes plan --dry-run` — works end-to-end
3. `ace-test ace-taskflow` — all remaining ace-taskflow tests still pass
4. No `Ace::Taskflow` references remain in ace-sim source
5. No `require` of ace-task, ace-idea, or ace-taskflow in ace-sim source

## Cache Directory Change

- Old: `.cache/ace-taskflow/simulations/<run-id>/`
- New: `.cache/ace-sim/simulations/<run-id>/`
