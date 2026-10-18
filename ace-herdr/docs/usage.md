---
doc-type: user
title: ace-herdr Usage
purpose: CLI and configuration reference for ace-herdr terminal transport, delivery, and agent bootstrap.
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# ace-herdr Usage

> **State owner:** none for task, assignment, or HITL state. `ace-herdr` owns
> terminal transport and its delivery retry records only. See
> [docs/lab-flow.md](../../docs/lab-flow.md).

`ace-herdr` is a zero-token wrapper over the `herdr` CLI. It is a transport:
it does not own task, assignment, queue, or HITL event state.

## Command surface

| Command | Purpose |
|---------|---------|
| `deliver` | Push an answer to an agent pane (HITL delivery transport) |
| `dispatch` | Start an agent in one command: tab + agent + prompt |
| `send` | Send a command, raw text, or named keys to a pane |
| `capture` | Print recent pane output as raw text |
| `wait` | Wait for an agent state or matching pane output |
| `close` | Rename and/or close a finished agent pane |
| `list` | List live panes, tabs, or workspaces as one JSON line |
| `tidy` | Report cleanable panes/delivery records; close/archive with `--apply` |
| `tab` / `workspace` | Create a tab/workspace from a preset |

## Delivery

`deliver` pushes an answer to the pane that asked, bootstrapping an agent when
the pane has none. Deliveries are idempotent per event id and never lose the
answer: a write-ahead record survives crashes, transient failures retry with
fixed backoff, and `--resume` re-delivers from the stored record.

```bash
ace-herdr deliver --session ws-1 --pane p5 --event-id evt-1 --answer-file answer.md
echo 'the answer' | ace-herdr deliver --pane p5
```

These are transport records, not a journal or a state owner.

## Dispatch, send, capture, wait, close

```bash
ace-herdr dispatch --label t.123 --kind pi --prompt-file prompt.md
ace-herdr dispatch --label review --pane p7 --cwd /Users/me/project

ace-herdr send --pane p5 --cmd 'bundle exec rake test'
ace-herdr send --pane p5 --msg 'continue with option 2' --key Enter
ace-herdr capture --pane p5 --lines 40
ace-herdr wait --pane p5 --until done --timeout 120
ace-herdr wait --pane p5 --for output --pattern 'build succeeded'
ace-herdr close --pane p5 --rename done
```

`send` delivers input in declaration order. Panes hosting a live agent get
prompt semantics: text becomes one self-submitting agent prompt, and a single
trailing Enter is dropped and reported. A command must be declared before any
key.

## Workspaces, tabs, and presets

Presets resolve through the ADR-022 cascade (`.ace/herdr/` > `~/.ace/herdr/` >
gem defaults) and may compose via `preset:` refs.

```bash
ace-herdr workspace development --cwd /path/to/project
ace-herdr tab agent --workspace w1
ace-herdr --list-presets
```

## List and tidy

```bash
ace-herdr list
ace-herdr list --tabs --workspace w1
ace-herdr list --workspaces
ace-herdr tidy          # dry run: report candidates only
ace-herdr tidy --apply  # close eligible panes, archive old delivered records
```

`tidy` closes panes only on positive completion evidence re-confirmed right
before closing; unknown, pending, retryable, and failed resources are never
touched.

## Status

```bash
ace-herdr status              # readable tree: workspaces > tabs > panes
ace-herdr status --format json
```

`status` composes the live workspaces, tabs, and panes into one read-only
snapshot. It starts nothing, writes nothing, and exits 0 whenever a report
renders; only usage errors exit non-zero.

Output states (never conflated):

- `Herdr runtime: available` -- the tree follows, with `*` marking focused
  entries, `agent:<status>` for agent panes and `plain` otherwise, cwd
  shortened with `~`. A valid empty layout renders zero counts and
  `No herdr workspaces, tabs, or panes.`
- `Herdr runtime: unavailable - <reason>` -- the herdr binary/runtime is
  missing; never rendered as an empty, ready layout.
- `Herdr runtime: error - <reason>` -- the runtime answered with an error.

JSON shape: `{"runtime": {"state", "binary", "error"}, "counts":
{"workspaces", "tabs", "panes"}, "workspaces": [{"workspace": {...},
"tabs": [{"tab": {...}, "panes": [...]}]}], "unattached": {"tabs": [...],
"panes": [...]}}`. Snapshot-race orphans (tab without workspace, pane without
tab) land in `unattached` and stay counted.

## Planned waves

> **Planned (L2):** the unified HITL report/question/reply interface and
> configurable adapter set are not available yet.
>
> The old durable agent inbox (`inbox`) and guarded native-source requirements
> belong to the replaced protected model and are not part of the file-based
> flow.

## Configuration

```yaml
# .ace/herdr/config.yml
default_agent_kind: pi
timeouts:
  wait: 300
tidy:
  delivered_retention_days: 7
```

## Testing

```bash
bin/ace-test ace-herdr
```
