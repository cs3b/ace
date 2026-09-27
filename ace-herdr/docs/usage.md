---
doc-type: user
title: ace-herdr Usage
purpose: Full CLI and configuration reference for ace-herdr push delivery and agent bootstrap.
ace-docs:
  last-updated: 2026-09-27
  last-checked: 2026-09-27
---

# Usage

`ace-herdr` is a zero-token wrapper over the `herdr` CLI. It implements the ace-hitl push-delivery contract — `deliver(ref, answer)` -> `herdr agent prompt <pane>` — and adds one-command agent dispatch, noiseless waiting, and pane closure. No LLM is consulted anywhere in the gem.

## Command Surface

- `ace-herdr deliver [OPTIONS]`
- `ace-herdr dispatch [OPTIONS]`
- `ace-herdr wait [OPTIONS]`
- `ace-herdr close [OPTIONS]`

## The delivery contract

`ace-hitl ask` captures the asker's reverse address fail-closed from the environment (`HERDR_SESSION` / `HERDR_PANE`, schema `ace.hitl.ref/v1`). `ace-herdr deliver` pushes an answer back to that address:

1. A write-ahead delivery record is persisted under `.ace-local/herdr/deliveries/<event-id>.json` before any herdr contact, so a crash can never lose the answer.
2. Delivery is idempotent per event id. Re-delivering identical content after a `:delivered` record short-circuits without contacting herdr; different content for the same event id fails closed.
3. If the target pane has no agent, one is bootstrapped (`herdr agent start`), the reverse address is exported into the pane shell (`export HERDR_SESSION=... HERDR_PANE=...`), and delivery waits for the agent to become idle before prompting.
4. Transient failures (`agent_prompt_stalled`, socket/binary unavailability) retry with a fixed deterministic backoff up to `delivery.max_attempts`; exhausted attempts report `retryable`.
5. Terminal failures (`agent_blocked` pre-send rejection, missing pane, agent start failure) report `failed` immediately with the error persisted in the record history.

Result states follow the ace-hitl contract (spec 8wm.t.vrz §1.2): `delivered`, `retryable` (safe to re-push identical content), `failed` (terminal).

## `ace-herdr deliver`

Push an answer to an agent pane.

```bash
# Answer from a file, explicit ref
ace-herdr deliver --session ws-1 --pane p5 --event-id evt-1 --answer-file answer.md

# Answer from stdin, ref from the environment (inside the asking pane)
echo 'the answer' | ace-herdr deliver

# Bootstrap a specific agent kind if the pane has none
ace-herdr deliver --session ws-1 --pane p5 --kind codex --label 8wm.t.vs0 --answer-file a.md
```

Options: `--session`, `--pane` (default: `HERDR_SESSION` / `HERDR_PANE`), `--event-id` (default: derived from the ref and content digest), `--kind`, `--label`, `--answer-file` (default: stdin).

Output: one JSON line `{"ref":{...},"state":"delivered|retryable|failed"}`. Exit code is non-zero unless the state is `delivered`.

## `ace-herdr dispatch`

Start an agent in one command: tab + `herdr agent start` + prompt, all with deterministic defaults.

```bash
ace-herdr dispatch --label 8wm.t.vs0 --kind pi --prompt-file prompt.md
ace-herdr dispatch --label review --pane p7 --cwd /path/to/project
ace-herdr dispatch --label 8wm.t.vs0 --no-prompt
```

Defaults: the caller's herdr workspace (flag `--workspace` > `HERDR_WORKSPACE_ID` > `herdr pane current`), the label as agent and pane name, the prompt from `--prompt-file` or stdin (`--no-prompt` skips submission). The new agent's environment receives `HERDR_SESSION` (workspace id) and `HERDR_PANE` (pane id) so its own `ace-hitl ask` calls carry a working reverse address.

Output: one JSON line `{"workspace":...,"pane":...,"agent":...,"kind":...,"tab_created":...,"prompted":...}`.

## `ace-herdr wait`

Wait for an agent to reach a state without scraping pane output.

```bash
ace-herdr wait --pane p5                      # idle, done, or blocked
ace-herdr wait --pane p5 --until done --timeout 120
```

## `ace-herdr close`

Close out a finished agent pane; optionally rename first.

```bash
ace-herdr close --pane p5 --rename done       # rename, then close
ace-herdr close --pane p5 --keep --rename wip # rename only
```

## Configuration

Defaults (`.ace-defaults/herdr/config.yml`), overridable in `~/.ace/herdr/config.yml` or `.ace/herdr/config.yml`:

```yaml
default_agent_kind: pi          # herdr agent kind used for bootstrap/dispatch
delivery:
  max_attempts: 3               # prompt attempts per delivery sequence
  backoff_seconds: [1, 2, 4]    # fixed deterministic backoff, no jitter
timeouts:
  agent_start: 60               # seconds to interactive readiness
  prompt: 30
  wait: 30                      # readiness gate / ace-herdr wait
deliveries_dir: .ace-local/herdr/deliveries
```

## Delivery records

Records are JSON, one file per event id under `deliveries_dir` (relative to the working directory): event id, reverse address, SHA-256 answer digest, state (`pending` / `delivered` / `retryable` / `failed`), attempt count, and an append-only history of bootstrap, readiness, and prompt events with errors. Records are written atomically. Re-running `deliver` with the same event id and content resumes or short-circuits; with different content it fails closed.

## Exit codes

Commands raise a CLI error (non-zero exit) for: invalid or missing reverse address, unreadable answer/prompt files, unresolvable workspace, herdr command failures, and delivery outcomes other than `delivered`. `0` means success (or a `ready` wait).

## Testing

```bash
ace-test ace-herdr
```

Fast tests only; the herdr binary is faked at the executor seam. An end-to-end scenario against a live herdr is tracked as a follow-up.
