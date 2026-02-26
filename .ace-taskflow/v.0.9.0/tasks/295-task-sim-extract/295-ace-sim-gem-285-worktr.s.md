---
id: v.0.9.0+task.295
status: draft
priority: high
estimate: TBD
dependencies: []
---

# Extract ace-sim Gem from Task 285 Worktree

## Objective

Extract the next-phase simulation feature (built in task 285) from ace-taskflow into a standalone `ace-sim` gem. This must happen **before** merging the 285 worktree to main, because ace-taskflow is being fully decomposed and deleted (tasks 290-294). ace-sim must be fully independent — no dependency on ace-task, ace-idea, or ace-taskflow.

## Behavioral Specification

### User Experience
- **Input**: Source reference (task or idea shortcut), simulation modes (draft, plan, work)
- **Process**: Reads source item file, runs LLM-driven simulations of downstream phases, caches artifacts, synthesizes findings, optionally writes back to source
- **Output**: Cache artifacts in `.cache/ace-sim/simulations/<run-id>/`, synthesis written back to source file

### Expected Behavior

1. **ace-sim review-next-phase**: Main CLI command. Runs read-only forward-looking simulations of downstream workflow phases.
2. **Idea simulation**: idea → simulated-draft → simulated-plan → synthesis → writeback to idea
3. **Task simulation**: task → simulated-plan → synthesis → writeback to task
4. **Completion gate**: `TaskCompletionGate` validates checklist completion. Provided as a standalone molecule that ace-task can optionally call.
5. **Cache**: All intermediate artifacts stored in `.cache/ace-sim/simulations/<b36ts-run-id>/`
6. **Trigger policy**: Auto-trigger on reviews (configurable), manual trigger always available

### Interface Contract

```bash
# Manual trigger
ace-sim review-next-phase --source <idea-ref|task-ref> --modes draft,plan

# Dry-run (no writeback)
ace-sim review-next-phase --source 285.01 --modes plan --dry-run

# Force enable/disable
ace-sim review-next-phase --source my-idea --next-phase-review
ace-sim review-next-phase --source my-idea --no-next-phase-review

# Auto-trigger mode
ace-sim review-next-phase --source my-task --auto-trigger
```

### Success Criteria

- [ ] `ace-sim` gem created with proper namespace `Ace::Sim`
- [ ] All 10 simulation source files extracted and namespace-transformed
- [ ] Source resolution decoupled from TaskManager/IdeaLoader — uses lightweight file scanner
- [ ] `ace-sim review-next-phase` works end-to-end from terminal
- [ ] Cache writes to `.cache/ace-sim/simulations/` (not ace-taskflow)
- [ ] Config loaded from `.ace-defaults/sim/config.yml` via ace-support-config
- [ ] TaskCompletionGate usable as standalone molecule
- [ ] No `require` of ace-task, ace-idea, or ace-taskflow in ace-sim source
- [ ] All simulation tests pass: `ace-test ace-sim`
- [ ] Remaining ace-taskflow tests still pass after simulation code removed
- [ ] ace-taskflow CLI no longer registers `review-next-phase`
- [ ] ace-taskflow configuration no longer has `next_phase_*` methods

## Scope of Work

### Files to extract from ace-taskflow (namespace Ace::Taskflow → Ace::Sim)

**Model (1):**
- `models/simulation_session.rb`

**Molecules (8):**
- `molecules/simulation_session_store.rb`
- `molecules/simulation_synthesis_builder.rb`
- `molecules/simulation_writeback_mixin.rb`
- `molecules/idea_simulation_writeback.rb`
- `molecules/task_simulation_writeback.rb`
- `molecules/next_phase_stage_executor.rb`
- `molecules/next_phase_trigger_policy.rb`
- `molecules/task_completion_gate.rb`

**Organism (1):**
- `organisms/next_phase_simulation_runner.rb`

**CLI (1):**
- `cli/commands/review_next_phase.rb`

**Tests (10):**
- `test/models/simulation_session_test.rb`
- `test/molecules/simulation_session_store_test.rb`
- `test/molecules/simulation_synthesis_builder_test.rb`
- `test/molecules/idea_simulation_writeback_test.rb`
- `test/molecules/task_simulation_writeback_test.rb`
- `test/molecules/next_phase_stage_executor_test.rb`
- `test/molecules/next_phase_trigger_policy_test.rb`
- `test/molecules/task_completion_gate_test.rb`
- `test/organisms/next_phase_simulation_runner_test.rb`
- `test/commands/review_next_phase_command_test.rb`

**Workflows (2):**
- `handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md`
- `handbook/workflow-instructions/task/simulate-next-phase-plan.wf.md`

### Integration hooks to remove from ace-taskflow

1. `cli.rb` — remove `review-next-phase` registration
2. `configuration.rb` — remove `next_phase_*` and `completion_gate_*` methods (~40 lines)
3. `.ace-defaults/taskflow/config.yml` — remove `review.next_phase` block and `task.completion_gate` block
4. `organisms/task_manager.rb` — keep completion gate call but make it optional (graceful if ace-sim not installed)
5. `cli/commands/task/done.rb` — keep `--allow-incomplete` flag (works with or without ace-sim)

### Key decoupling: Source Resolution

The runner currently depends on `TaskManager` and `IdeaLoader`. Replace with a lightweight `SourceResolver`:
- Scans `.ace-tasks/` for `*.s.md` (suffix match on shortcut)
- Scans `.ace-ideas/` for `*.idea.s.md` (suffix match on shortcut)
- Returns `{ type:, path:, content: }` — just file discovery + read
- No dependency on ace-task or ace-idea gems

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
  handbook/workflow-instructions/sim/
    simulate-next-phase-draft.wf.md
    simulate-next-phase-plan.wf.md
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
spec.add_dependency "ace-b36ts", "~> 0.7"
spec.add_dependency "ace-support-config", "~> 0.7"
spec.add_dependency "ace-support-core", "~> 0.25"
spec.add_dependency "ace-support-markdown", "~> 0.2"
spec.add_dependency "dry-cli", "~> 1.0"
# NO dependency on ace-task, ace-idea, or ace-taskflow
```

## References

- Extraction instructions: `295-task-sim-extract/extraction-instructions.md`
- Worktree: `/home/mc/ace-task.285` (branch `285-iterative-review-with-next-phase-dry-runs`)
- Task 285 orchestrator: `285-task-iterative-review/285-orchestrator.s.md`
- ace-taskflow decomposition: tasks 290-294
