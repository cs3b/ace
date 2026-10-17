<div align="center">
  <h1> ACE - Assign </h1>

  Multi-step assignment plans with nesting, fork delegation, and inspectable state.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-assign"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-assign.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

> **State owner:** `.ace-local/assign/` -- assignment plans and step state owned
> by `ace-assign`. There is no second queue: the plan is the only place steps
> live, and coworker configuration or the private overseer list never copy
> them. The canonical flow is [docs/lab-flow.md](../docs/lab-flow.md).

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

`ace-assign` turns work into a multi-step assignment with nested substeps and
fork delegation. Steps come from a [step catalog](.ace-defaults/assign/catalog/steps/)
and are assembled via [presets](.ace-defaults/assign/presets/work-on-task.yml) or
composed manually. Each step may reference a workflow instruction for execution
details. Assignments are restartable: failed steps keep their lineage so you can
retry or inject fixes without losing history.

```bash
ace-assign status
# abc123 work-on-task-abc456 | running | 4/7 done | current: 100 review-pr
```

Use `ace-assign status --mode full` for the whole tree and `ace-assign step` for
the current or next step instructions.

The local lifecycle is:

1. `ace-assign create` expands a preset or YAML definition into numbered steps
   (`010`, `010.01`, …) with `pending` → `in_progress` → `done`/`failed` state.
2. `ace-assign step` / `start` / `finish` / `fail` drive one step at a time;
   `/as-assign-drive` wraps this loop for agents.
3. `ace-assign add` / `retry` / `fork-run` adapt the plan while it runs.

The easiest way to start is through [ace-overseer](../ace-overseer):
`ace-overseer work-on --task <ref>` creates the worktree, assignment, and
terminal in one shot.

## Use Cases

**Define assignments from presets** - pick a preset such as `work-on-task` or
`release-only`, pass parameters (task refs, packages), and run
`ace-assign create --task ...` or `ace-assign create --yaml ...`. Steps are
ordered by [composition rules](.ace-defaults/assign/catalog/composition-rules.yml).

**Run with orchestrator and fork agents** - `/as-assign-drive` walks the steps
and can fork long-running work to isolated agent subprocesses with configurable
execution defaults or per-step `fork.provider` overrides. Fork traces and
session reports stay under `.ace-local/assign/`.

**Recover from failure without losing history** - keep failed-step lineage,
inject targeted retries or fix steps, and continue.

**Compose assignments from templates** - use `/as-assign-compose` to build plans
from reusable patterns, then pair with [ace-task](../ace-task) for task
lifecycle, [ace-bundle](../ace-bundle) for context loading, and
[ace-review](../ace-review) for quality checks.

## Planned waves

> **Planned (L3):** `ace-coworker` consumes an assignment from
> `.ace-local/coworker/`, records results, and reports through HITL -- not
> available yet.
>
> **Planned (L5.5):** role rules, review rounds, and forge delivery workflow --
> not available yet.

## Testing Contract

- `bin/ace-test ace-assign` runs the default deterministic package loop.
- `bin/ace-test ace-assign feat` runs deterministic feature/contract coverage.
- `bin/ace-test ace-assign all` runs full package deterministic coverage.
- `bin/ace-test-e2e ace-assign` runs scenario workflows.

Assignment verification uses deterministic commands only:

- modified packages: `bin/ace-test <package> all --profile 6`
- monorepo gate: `bin/ace-test-suite --target all`

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
