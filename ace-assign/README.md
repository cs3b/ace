<div align="center">
  <h1> ACE - Assign </h1>

  Multi-step assignment execution with nesting, fork delegation, and inspectable traces.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-assign"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-assign.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

`ace-assign` turns work into a multi-step assignment with nested substeps, fork delegation to long-running agent subprocesses, and inspectable session traces. Steps are defined from a [step catalog](.ace-defaults/assign/catalog/steps/) and assembled via [presets](.ace-defaults/assign/presets/work-on-task.yml) or composed manually. Each step can reference a [workflow instruction](../ace-task/handbook/workflow-instructions/task/work.wf.md) for execution details. Assignments are restartable -- failed steps keep their lineage so you can retry or inject fixes without losing history.
```

❯ ace-assign status
QUEUE - Assignment: work-on-task-8qm.t.5nx-job.yml (8qm5rt)

NUMBER       STATUS       NAME                           FORK   CHILDREN
------------------------------------------------------------------------------
000          ✓ Done       onboard
010          ✓ Done       batch-tasks                           (28/28 done)
|-- 010.01   ✓ Done       work-on-8qm.t.5nx.0            yes    (8/8 done)
  |-- 010.01.01 ✓ Done       onboard-base
  |-- 010.01.02 ✓ Done       task-load
  |-- 010.01.03 ✓ Done       plan-task
  |-- 010.01.04 ✓ Done       work-on-task
  |-- 010.01.05 ✓ Done       pre-commit-review
  |-- 010.01.06 ✓ Done       verify-test
  |-- 010.01.07 ✓ Done       release-minor
  \-- 010.01.08 ✓ Done       create-retro
|-- 010.02   ✓ Done       work-on-8qm.t.5nx.1            yes    (8/8 done)
# ... multiple tasks hidden
012          ✓ Done       verify-test-suite
015          ✓ Done       verify-e2e                     yes
020          ✓ Done       release-minor
025          ✓ Done       update-docs
030          ✓ Done       create-pr
040          ✓ Done       review-valid-1                 yes    (3/3 done)
|-- 040.01   ✓ Done       review-pr
|-- 040.02   ✓ Done       apply-feedback
\-- 040.03   ✓ Done       release
070          ✓ Done       review-fit-1                   yes    (3/3 done)
|-- 070.01   ✓ Done       review-pr
|-- 070.02   ✓ Done       apply-feedback
\-- 070.03   ✓ Done       release
100          ○ Pending    review-shine-1                 yes    (2/3 done)
|-- 100.01   ✗ Failed     review-pr                              - Fork agent blocked by pre-existing unrelated changes (now stashed). Retrying.
|-- 100.02   ✓ Done       apply-feedback
\-- 100.03   ✓ Done       release
101          ✓ Done       review-pr
130          ✓ Done       reorganize-commits
140          ✓ Done       push-to-remote
150          ✓ Done       update-pr-desc                 yes
155          ✓ Done       mark-tasks-done
160          ✓ Done       create-retro
161          ✓ Done       review-pr                      yes
162          ✓ Done       apply-feedback                 yes
163          ✓ Done       release                        yes
```


The easiest way to start is through [ace-overseer](../ace-overseer) -- define a task and run `ace-overseer work-on --task <ref> --preset work-on-task` , which creates the assignment, worktree, and tmux window in one shot.

## How It Works

1. Define steps from a [preset](.ace-defaults/assign/presets/work-on-task.yml) or compose from the [step catalog](.ace-defaults/assign/catalog/steps/) -- steps can nest into substeps and reference workflow instructions for execution details.
2. Expand the definition into a session with explicit per-step instructions, state tracking (`pending` → `in_progress` → `done`/`failed`), and numbered hierarchy (e.g., `010`, `010.01`, `010.01.01`).
3. Drive execution with `/as-assign-drive` -- fork long-running steps to isolated agent subprocesses, advance the queue on completion, and retry or inject fix steps on failure.

## Use Cases

**Define assignments from presets** - pick a [preset](.ace-defaults/assign/presets/) like [`work-on-task`](.ace-defaults/assign/presets/work-on-task.yml) or `release-only`, pass parameters (task refs, packages), and [`ace-assign create`](docs/usage.md) expands it into a concrete step queue. Steps are defined in the [catalog](.ace-defaults/assign/catalog/steps/) (e.g., [`work-on-task.step.yml`](.ace-defaults/assign/catalog/steps/work-on-task.step.yml)) and ordered by [composition rules](.ace-defaults/assign/catalog/composition-rules.yml). Compose custom assignments with `/as-assign-compose`.

**Run with orchestrator and fork agents** - use `/as-assign-drive` to walk through steps, forking long-running work (implementation, review, release) to isolated agent subprocesses with configurable [execution defaults](.ace-defaults/assign/config.yml). Forks can run sequentially or as parallel batches, each producing inspectable traces and session reports under `.ace-local/assign/`.

**Recover from failure without losing history** - keep failed-step lineage intact, inject targeted retries or fix steps, and continue execution with auditable failure evidence.

**Compose assignments from templates** - use `/as-assign-compose` and `/as-assign-prepare` to build assignment plans from reusable patterns, then pair with [ace-task](../ace-task) for task lifecycle, [ace-bundle](../ace-bundle) for context loading, and [ace-review](../ace-review) for quality checks.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
