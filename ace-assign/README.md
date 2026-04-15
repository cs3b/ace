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
8qm5rt work-on-task-8qm.t.5nx-job.yml | running | 64/71 done | current: 100.01 review-pr | last: 070.03 release
hidden: 66 | done: 64 active: 1 pending: 5 failed: 1
100.01 active review-pr
100.02 next apply-feedback
100.03 next release
130 next reorganize-commits
140 next push-to-remote
```

Use `ace-assign status --mode full` when you need the whole tree, and `ace-assign step` when you need the raw instructions for the current or next step.


The easiest way to start is through [ace-overseer](../ace-overseer) -- define a task and run `ace-overseer work-on --task <ref> --preset work-on-task` , which creates the assignment, worktree, and tmux window in one shot.

## Testing Contract

- `ace-test ace-assign` runs the default deterministic package loop (`test/fast`).
- `ace-test ace-assign feat` runs deterministic feature/contract coverage (`test/feat`).
- `ace-test ace-assign all` runs full package deterministic coverage (`fast` + `feat`).
- `ace-test-e2e ace-assign` runs scenario workflows under `test/e2e`.

Assignment verification uses deterministic commands only:
- modified packages: `ace-test <package> all --profile 6`
- monorepo gate: `ace-test-suite --target all`

## How It Works

1. Define steps from a [preset](.ace-defaults/assign/presets/work-on-task.yml) or compose from the [step catalog](.ace-defaults/assign/catalog/steps/) -- steps can nest into substeps and reference workflow instructions for execution details.
2. Expand the definition into a session with explicit per-step instructions, state tracking (`pending` → `in_progress` → `done`/`failed`), and numbered hierarchy (e.g., `010`, `010.01`, `010.01.01`).
3. Drive execution with `/as-assign-drive` -- fork long-running steps to isolated agent subprocesses, use `ace-assign watch` to continue sequential fork work deterministically, and retry or inject fix steps on failure.

## Use Cases

**Define assignments from presets** - pick a [preset](.ace-defaults/assign/presets/) like [`work-on-task`](.ace-defaults/assign/presets/work-on-task.yml) or `release-only`, pass parameters (task refs, packages), and run `ace-assign create --task ...` or [`ace-assign create --yaml ...`](docs/usage.md) to expand them into a concrete step queue. Steps are defined in the [catalog](.ace-defaults/assign/catalog/steps/) (e.g., [`work-on-task.step.yml`](.ace-defaults/assign/catalog/steps/work-on-task.step.yml)) and ordered by [composition rules](.ace-defaults/assign/catalog/composition-rules.yml). Compose custom assignments with `/as-assign-compose`.

`work-on-task` release steps resolve `wfi://release/publish` from shipped workflow sources by default, and project-level `wfi://` source overrides registered under `.ace/nav/protocols/wfi-sources/` are honored by both `ace-bundle` and `ace-assign`.

**Run with orchestrator and fork agents** - use `/as-assign-drive` to walk through steps, forking long-running work (implementation, review, release) to isolated agent subprocesses with configurable [execution defaults](.ace-defaults/assign/config.yml) or per-step `fork.provider` overrides. Use `ace-assign watch --assignment <id>` when the driver needs deterministic fork wait/recovery behavior across sequential child subtrees. Forks can run sequentially or as parallel batches, each producing inspectable traces and session reports under `.ace-local/assign/`.

**Recover from failure without losing history** - keep failed-step lineage intact, inject targeted retries or fix steps, and continue execution with auditable failure evidence.

**Compose assignments from templates** - use `/as-assign-compose` and `/as-assign-prepare` to build assignment plans from reusable patterns, then pair with [ace-task](../ace-task) for task lifecycle, [ace-bundle](../ace-bundle) for context loading, and [ace-review](../ace-review) for quality checks.

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
