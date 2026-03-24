---
doc-type: user
title: ace-sim Getting Started
purpose: Tutorial for first-run ace-sim workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-sim

`ace-sim` gives you a controlled way to validate ideas and tasks with multiple LLMs before you make changes.

## 1. Prerequisites

- Ruby 3.2+
- `ace-sim` installed
- `vhs` installed when you want to run the demonstration recording
- Access to at least one LLM provider configured in your environment

## 2. Prepare your source

`ace-sim` reads one or more markdown sources. A source can be:

- A draft issue file
- A task specification
- A short prompt file for idea checks

## 3. First dry-run simulation

Use a dry run to inspect the plan without executing providers:

```bash
ace-sim run --preset validate-idea --source idea.md --dry-run
```

Expected behavior:

- A run is prepared with a generated run directory under `.ace-local/sim/simulations/<run-id>`
- No final artifacts are written by providers because dry-run disables mutations
- You can still inspect the run metadata output in the command result

## 4. Understand the output

Each run produces a directory under `.ace-local/sim/simulations/<run-id>/`:

- `input.md` and `input.bundle.md` — the bundled source used as initial input
- `chains/<provider>-<iteration>/` — step-by-step outputs where each step's result feeds into the next (draft -> plan -> work)
- `final/` — synthesis results that gather feedback from all stages, propose improvements, and produce a revised source artifact

The chain is sequential: each step builds on the previous step's output, so the final work step has the benefit of the draft and plan reasoning before it. The synthesis stage then reviews everything to surface questions and actionable suggestions.

## 5. Run for real

Remove `--dry-run` to execute real simulation providers:

```bash
ace-sim run --preset validate-idea --source idea.md
```

## 6. Validate a task

Use the task preset for task-oriented review:

```bash
ace-sim run --preset validate-task --source path/to/task.s.md
```

`validate-task` defaults to a shorter `plan -> work` flow with task-oriented synthesis.

## 7. Override providers

You can compare outputs by provider:

```bash
ace-sim run --preset validate-task --source task.md --provider codex:mini --provider google:gflash
```

## 8. Common commands

| Goal | Command |
|---|---|
| Run idea validation (dry) | `ace-sim run --preset validate-idea --source idea.md --dry-run` |
| Run task validation | `ace-sim run --preset validate-task --source task.md` |
| Use a different provider mix | `ace-sim run --preset validate-task --source task.md --provider codex:mini --provider google:gflash` |
| Repeat each provider chain | `ace-sim run --preset validate-task --source task.md --repeat 2` |
| See full command reference | [`docs/usage.md`](usage.md) |

## 9. What to try next

- Add a custom step override (`--steps`) to focus on only `plan` or only `work`
- Pair with `--repeat` for stress-testing convergence
- Use `--synthesis-workflow` for custom review logic
- Explore all switches in [`docs/usage.md`](usage.md)

