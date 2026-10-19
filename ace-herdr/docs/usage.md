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
| `status` | Show the live layout: workspaces, tabs, and panes in one view |
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

## Delivering reports to a pi overseer (L7.3)

An ace-hitl report reaches a pi overseer session through the transports Herdr
already owns — there is no second queue on the ACE side:

- **Pane push (`ace-herdr deliver`):** the report text is prompted into the
  overseer pane. Delivery is idempotent per event id: a repeated notification
  of the same event short-circuits against the delivery record instead of
  prompting again, and concurrent deliveries of one event prompt once. A pane
  without an agent is bootstrapped and gated on readiness first.
- **Provider-native queue (`ACE_HERDR_PI_QUEUE_CLIENT`):** the configured pi
  queue client receives the payload (`--delivery <event-id> --session-id ...`
  with a digest-bound receipt) and hands it to the session, which accepts it
  while waiting (immediate turn) and while working (queued follow-up for the
  active run).

Either way a delivery during an ACTIVE overseer turn never starts a second
overseer execution: the message joins the one session run, and the woken
session resumes the commissioned process with the `/continue-work` prompt
(see ace-handbook-integration-pi). Repetition of a delivery is transport
noise — work repetition is decided by event state on the receiving side, not
by the number of deliveries.

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

`status` composes the three live lists (`workspace_list`, `tab_list`,
`pane_list`) into one readable tree: workspaces with their tabs and each tab
with its panes, focused items marked with `*`, agent panes suffixed with
`agent: <state>`, and home directories shortened to `~`.

```bash
ace-herdr status                  # whole layout as a table
ace-herdr status --workspace w1   # one workspace
ace-herdr status --format json    # the composed tree as JSON
```

Semantics:

- A live but empty result prints `No live herdr workspaces.` and exits 0 —
  an empty valid set, not an error.
- An unreachable runtime (`ExecutorUnavailableError` and other executor
  failures) is reported as an actionable non-zero error, never as an empty
  layout.
- Counts are recomputed from the composed nesting, and panes whose tab or
  workspace vanished between the list calls are kept in a synthetic
  `(unlinked)` group instead of being dropped.
- JSON shape: `{"workspaces":[{"id","title","number","focused","tab_count",
  "pane_count","tabs":[{"id","title","number","focused","pane_count","panes":
  [{"id","tab","workspace","title","cwd","focused","agent_status"}]}]}]}`
  with synthetic groups carrying `synthetic: true`.

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
