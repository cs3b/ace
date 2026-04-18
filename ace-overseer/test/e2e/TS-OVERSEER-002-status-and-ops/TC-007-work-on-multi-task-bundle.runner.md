# Goal 7 -- Work-On Multi-Task Bundle

## Goal

Run a multi-task work-on flow using the public CLI surface (repeat `--task` and/or comma-separated task refs). Verify that the command accepts multiple task refs, creates the primary task orchestration resources, and avoids duplicate/ambiguous public state.

## Workspace

Save all output to `results/tc/07/`. Capture:

- Scenario-local task creation evidence and resolved refs
  - save the first created task ref to `results/tc/07/task-a.ref.txt`
  - save the second created task ref to `results/tc/07/task-b.ref.txt`
- Multi-task `ace-overseer work-on` command stdout/stderr/exit
- `ace-git-worktree list` output after invocation
- `ace-overseer status --format json` output after invocation
- assignment job YAML path or contents reported by the command, when present, as supporting evidence
- Optional tmux window listing (`tmux list-windows -t "$ACE_TMUX_SESSION"`) as supporting evidence

## Constraints

- Provide the same minimal project config used by the happy-path overseer scenario: task root config, overseer default preset config, tmux default window config, and a scenario-local multi-task assignment preset.
- Create two scenario-local pending tasks first with `ace-task create`, persist their refs to the files above, and use those created refs for the multi-task invocation.
- Run the multi-task command with `ACE_TMUX_SESSION` exported explicitly in the command environment so `ace-overseer` can target the scenario tmux session deterministically.
- Use the explicit public preset `--preset work-on-task` for the multi-task invocation.
- Use public CLI flags only; no hidden helper scripts.
- Verify outcomes via worktree and status outputs as primary oracle.
- All artifacts must come from real tool execution, not fabricated.
